import httpx
import logging
from app.core.config import get_settings

settings = get_settings()
logger = logging.getLogger(__name__)

class Msg91Service:
    BASE_URL = "https://control.msg91.com/api/v5"

    @staticmethod
    async def send_otp(phone_number: str) -> bool:
        """
        Sends OTP via MSG91 to the given phone number.
        Phone number should include country code (e.g., 919876543210).
        """
        url = f"{Msg91Service.BASE_URL}/otp"
        headers = {
            "authkey": settings.MSG91_AUTH_KEY,
            "Content-Type": "application/json"
        }
        # Assuming template_id is used. If not, params might differ.
        # Required params usually: template_id, mobile, authkey, etc.
        # Checking Msg91 docs, usually query params or body.
        # V5 API uses query params for GET or body for POST with template.
        
        # Using POST with template_id
        payload = {
            "template_id": settings.MSG91_TEMPLATE_ID,
            "mobile": phone_number,
            "authkey": settings.MSG91_AUTH_KEY
        }
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(url, params=payload)
                response.raise_for_status()
                data = response.json()
                if data.get("type") == "success":
                    return True
                logger.error(f"Msg91 Error: {data}")
                return False
        except Exception as e:
            logger.error(f"Failed to send OTP: {str(e)}")
            return False

    @staticmethod
    async def verify_otp(phone_number: str, otp: str) -> bool:
        """
        Verifies the OTP for the given phone number.
        """
        url = f"{Msg91Service.BASE_URL}/otp/verify"
        headers = {
            "authkey": settings.MSG91_AUTH_KEY
        }
        params = {
            "mobile": phone_number,
            "otp": otp,
            "authkey": settings.MSG91_AUTH_KEY
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(url, params=params, headers=headers)
                response.raise_for_status()
                data = response.json()
                if data.get("type") == "success":
                    return True
                logger.error(f"Msg91 Verify Error: {data}")
                return False
        except Exception as e:
            logger.error(f"Failed to verify OTP: {str(e)}")
            return False
