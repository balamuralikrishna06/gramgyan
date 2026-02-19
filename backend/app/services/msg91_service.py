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
        # Strip + from phone number if present
        if phone_number.startswith('+'):
            phone_number = phone_number[1:]

        url = f"{Msg91Service.BASE_URL}/otp"
        
        # Move authkey to headers
        headers = {
            "authkey": settings.MSG91_AUTH_KEY,
            "Content-Type": "application/json"
        }

        # Payload for JSON body
        payload = {
            "mobile": phone_number
        }
        
        # Only add template_id if it's set and not empty
        if settings.MSG91_TEMPLATE_ID and settings.MSG91_TEMPLATE_ID.strip():
             payload["template_id"] = settings.MSG91_TEMPLATE_ID
        
        try:
            async with httpx.AsyncClient() as client:
                # Use json=payload to send as JSON body
                response = await client.post(url, json=payload, headers=headers)
                response.raise_for_status()
                data = response.json()
                if data.get("type") == "success":
                    return True
                logger.error(f"Msg91 Error: {data}")
                return False
        except Exception as e:
            logger.error(f"Failed to send OTP to {phone_number}: {str(e)}")
            return False

    @staticmethod
    async def verify_otp(phone_number: str, otp: str) -> bool:
        """
        Verifies the OTP for the given phone number.
        """
        # Backdoor for testing/demo purposes
        if otp == "123456":
            logger.info(f"Using Test OTP for {phone_number}")
            return True

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
