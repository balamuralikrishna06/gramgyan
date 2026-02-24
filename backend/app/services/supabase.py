from supabase import create_client, Client
from app.core.config import get_settings
import logging

logger = logging.getLogger(__name__)
settings = get_settings()

_supabase_client: Client = None

def get_supabase_client() -> Client:
    """Get or initialize Supabase Client (Singleton)"""
    global _supabase_client
    if _supabase_client is None:
        try:
            url = settings.SUPABASE_URL
            key = settings.SUPABASE_SERVICE_ROLE_KEY
            _supabase_client = create_client(url, key)
            logger.info("Supabase Client initialized successfully")
        except Exception as e:
            logger.error(f"Failed to initialize Supabase Client: {e}")
            raise
    return _supabase_client
