from fastapi import APIRouter, HTTPException, Depends, status
from pydantic import BaseModel
from typing import Optional
from app.services.firebase import verify_token
from app.services.supabase import get_supabase_client
import logging
from datetime import datetime

import uuid

router = APIRouter()
logger = logging.getLogger(__name__)

class LoginRequest(BaseModel):
    token: str

class ProfileUpdateRequest(BaseModel):
    firebase_uid: str
    name: str
    state: str
    city: str
    language: str
    role: str = "farmer"

@router.post("/firebase-login")
async def firebase_login(request: LoginRequest):
    """
    Verifies Firebase Token, syncs user to Supabase, and checks profile status.
    """
    # 1. Verify Firebase Token
    decoded_token = verify_token(request.token)
    if not decoded_token:
        raise HTTPException(status_code=401, detail="Invalid authentication token")

    firebase_uid = decoded_token.get("uid")
    email = decoded_token.get("email")
    phone = decoded_token.get("phone_number")
    
    if not firebase_uid:
        raise HTTPException(status_code=400, detail="Token missing UID")

    supabase = get_supabase_client()

    try:
        # 2. Check if user exists in Supabase
        response = supabase.table("users").select("*").eq("firebase_uid", firebase_uid).execute()
        user_data = response.data

        user_id = None
        is_new_user = False

        if not user_data:
            # 2.1. Fallback: Check if user exists by PHONE (to link old accounts)
            if phone:
                phone_response = supabase.table("users").select("*").eq("phone", phone).execute()
                if phone_response.data:
                    # Link existing user
                    existing_user = phone_response.data[0]
                    user_id = existing_user["id"]
                    # Update firebase_uid
                    supabase.table("users").update({"firebase_uid": firebase_uid}).eq("id", user_id).execute()
                    
                    # Refresh user_data
                    user_data = [existing_user]
                    user_data[0]["firebase_uid"] = firebase_uid
                else:
                    is_new_user = True
            else:
                is_new_user = True

            if is_new_user:
                # 3. Create new user matches nothing
                new_user_id = str(uuid.uuid4())
                new_user = {
                    "id": new_user_id,
                    "firebase_uid": firebase_uid,
                    "email": email,
                    "phone": phone,
                    "created_at": datetime.utcnow().isoformat()
                }
                # Insert and return inserted data to get the UUID
                insert_response = supabase.table("users").insert(new_user).execute()
                if insert_response.data:
                    user_data = insert_response.data
                    user_id = user_data[0]["id"]
                else:
                    user_id = new_user_id
        else:
            user_id = user_data[0]["id"]

        # 4. Check Profile Completeness
        # Profile is complete if name, role, state, city are present
        current_user = user_data[0]
        profile_complete = all([
            current_user.get("name"),
            current_user.get("role"),
            current_user.get("state"),
            current_user.get("city")
        ])

        return {
            "user_exists": not is_new_user,
            "profile_complete": profile_complete,
            "user_id": user_id,
            "firebase_uid": firebase_uid,
            "user_data": current_user
        }

    except Exception as e:
        logger.error(f"Database error during login: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/profile/update")
async def update_profile(request: ProfileUpdateRequest):
    """
    Updates user profile in Supabase.
    """
    supabase = get_supabase_client()
    
    try:
        update_data = {
            "name": request.name,
            "state": request.state,
            "city": request.city,
            "language": request.language,
            "role": request.role
        }
        
        response = supabase.table("users").update(update_data).eq("firebase_uid", request.firebase_uid).execute()
        
        if not response.data:
             raise HTTPException(status_code=404, detail="User not found")
             
        return {"status": "success", "data": response.data[0]}

    except Exception as e:
        logger.error(f"Database error during profile update: {e}")
        raise HTTPException(status_code=500, detail=str(e))
