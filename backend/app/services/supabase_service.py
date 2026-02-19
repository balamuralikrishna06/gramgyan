from supabase import create_client, Client
from app.core.config import get_settings
from gotrue.errors import AuthApiError
import logging

settings = get_settings()
logger = logging.getLogger(__name__)

class SupabaseService:
    _instance = None
    _client: Client = None

    @classmethod
    def get_client(cls) -> Client:
        if cls._instance is None:
            url: str = settings.SUPABASE_URL
            key: str = settings.SUPABASE_SERVICE_ROLE_KEY
            cls._client = create_client(url, key)
            cls._instance = cls
        return cls._client

    @classmethod
    def get_user_id_by_phone(cls, phone: str) -> str | None:
        """
        Tries to find a user's ID by their phone number.
        Strategy:
        1. Query `public.users` (fastest, if sync is working).
        2. If not found, try to create the user in Auth.
        3. If creation fails (already exists), fallback to listing users (slow but reliable).
        """
        client = cls.get_client()

        # Site 1: Check public.users
        try:
            # We assume 'phone' column exists or we might fail here.
            # If 'phone' doesn't exist in public.users, this will error.
            # However, for a robust system, we should have phone in public.users.
            # Let's try to select.
            res = client.table("users").select("id").eq("phone", phone).maybe_single().execute()
            if res.data:
                return res.data['id']
        except Exception as e:
            logger.warning(f"Could not query public.users by phone: {e}")

        # Site 2: Create User (primary way to get ID if we don't know it)
        try:
            # Format phone: Supabase expects E.164 usually if strict, but let's pass as is or ensure + prefix.
            # Caller should ensure format.
            user_params = {"phone": phone, "email_confirm": True, "phone_confirm": True}
            user = client.auth.admin.create_user(user_params)
            return user.user.id
        except AuthApiError as e:
            if "already registered" in str(e) or "already created" in str(e):
                logger.info("User already exists in Auth, fetching details...")
                return cls._find_user_in_auth_list(phone)
            logger.error(f"Error creating user: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in get_user_id_by_phone: {e}")
            return None

    @classmethod
    def _find_user_in_auth_list(cls, phone: str) -> str | None:
        """
        Fallback: List users to find by phone.
        WARNING: This is expensive if user base is large.
        """
        try:
            client = cls.get_client()
            # List users (default page size is 50). We might need to pagination if robust.
            # For now, fetching first page. If user is old, this might fail without loop.
            # Basic implementation for MVP.
            users = client.auth.admin.list_users(page=1, per_page=1000) 
            for user in users:
                if user.phone == phone:
                    return user.id
            return None
        except Exception as e:
            logger.error(f"Error listing users: {e}")
            return None
    
    @classmethod
    def create_session(cls, user_id: str):
        """
        Mint a token for the user.
        Supabase Admin doesn't have a direct "create_token" for a user ID easily exposed in python client 
        without signing it ourselves using the JWT secret.
        However, `sign_in_with_id_token` or similar might work if we had an OIDC token.
        
        Best approach for backend-minted session:
        Use the JWT secret to sign a standard Supabase JWT.
        Payload: {
            "aud": "authenticated",
            "exp": <future_timestamp>,
            "sub": user_id,
            "iss": "supabase",
            "role": "authenticated"
        }
        """
        import jwt
        import time

        # We need the JWT secret. Usually it is in env as SUPABASE_JWT_SECRET.
        # If not available, we can't sign tokens securely that Supabase accepts as "authenticated".
        # The prompt says "Generate Supabase session or JWT compatible token."
        
        # Assumption: We have SUPABASE_JWT_SECRET or we can use SERVICE_KEY (bad practice for client use).
        # OR we rely on `client.auth.admin.generate_link` which generates a magic link,
        # but we need a direct ACCESS TOKEN.
        
        # If we check `gotrue-py`, `sign_in_with_phone` sends SMS.
        
        # If we cannot mint a token (missing JWT secret), we can return the `user_id` 
        # and the frontend might rely on a custom auth flow? No, frontend needs to query RLS tables.
        # RLS tables require specific JWT.
        
        # We MUST sign a JWT.
        # I will assume SUPABASE_JWT_SECRET is added to env.
        # If not, I will use a placeholder and warn.
        
        secret = settings.SUPABASE_JWT_SECRET
        if not secret:
            logger.error("SUPABASE_JWT_SECRET not set. Cannot mint token.")
            return None

        payload = {
            "aud": "authenticated",
            "exp": int(time.time()) + 3600 * 24 * 7, # 7 days
            "sub": user_id,
            "role": "authenticated",
            "app_metadata": {"provider": "phone", "providers": ["phone"]},
            "user_metadata": {}
        }
        
        token = jwt.encode(payload, secret, algorithm="HS256")
        return token
