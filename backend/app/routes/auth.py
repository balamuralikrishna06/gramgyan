from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from app.services.msg91_service import Msg91Service
from app.services.supabase_service import SupabaseService
import logging

router = APIRouter()
logger = logging.getLogger(__name__)

class SendOtpRequest(BaseModel):
    phone_number: str

class VerifyOtpRequest(BaseModel):
    phone_number: str
    otp: str

@router.post("/send-otp")
async def send_otp(request: SendOtpRequest):
    """
    Sends an OTP to the provided phone number using MSG91.
    """
    success = await Msg91Service.send_otp(request.phone_number)
    if not success:
        raise HTTPException(status_code=500, detail="Failed to send OTP")
    return {"message": "OTP sent successfully"}

@router.post("/verify-otp")
async def verify_otp(request: VerifyOtpRequest):
    """
    Verifies the OTP. If valid, gets/creates user in Supabase and returns a JWT.
    """
    # 1. Verify OTP with MSG91
    is_valid = await Msg91Service.verify_otp(request.phone_number, request.otp)
    if not is_valid:
        raise HTTPException(status_code=400, detail="Invalid OTP")

    # 2. Get or Create User in Supabase
    user_id = SupabaseService.get_user_id_by_phone(request.phone_number)
    if not user_id:
        raise HTTPException(status_code=500, detail="Failed to retrieve user ID")

    # 3. Generate Token
    token = SupabaseService.create_session(user_id)
    if not token:
        raise HTTPException(status_code=500, detail="Failed to generate session")

    return {
        "success": True,
        "user_id": user_id,
        "access_token": token,
        "token_type": "bearer"
    }
