import httpx
from fastapi import APIRouter, HTTPException, Body
from app.core.config import get_settings
import logging
from pydantic import BaseModel

router = APIRouter()
config = get_settings()
logger = logging.getLogger(__name__)

class GyanCallRequest(BaseModel):
    phone: str
    line: int

LINES = {
    1: {
        "endpoint": "https://madhan1806.app.n8n.cloud/webhook/missed-call",
        "to": "+18392616941",
        "env_sid_key": "GYANCALL_LINE1_SID"
    },
    2: {
        "endpoint": "https://bala006.app.n8n.cloud/webhook/missed-call",
        "to": "+15822820653",
        "env_sid_key": "GYANCALL_LINE2_SID"
    }
}

@router.post("/trigger")
async def trigger_gyan_call(request: GyanCallRequest = Body(...)):
    """
    Triggers an n8n workflow for offline farmer assistance.
    """
    if request.line not in LINES:
        raise HTTPException(status_code=400, detail="Invalid line selection.")
        
    line_config = LINES[request.line]
    account_sid = getattr(config, line_config["env_sid_key"], None)
    
    if not account_sid:
        raise HTTPException(status_code=500, detail="Call Service not configured on backend.")
    
    payload = {
        "From": request.phone,
        "To": line_config["to"],
        "CallSid": "CA123456789example",
        "Direction": "inbound",
        "AccountSid": account_sid,
    }
    
    try:
        async with httpx.AsyncClient(timeout=15.0) as client:
            response = await client.post(line_config["endpoint"], json=payload)
            response.raise_for_status()
            return {"status": "success"}
    except Exception as e:
        logger.error(f"Failed to trigger Gyan Call on line {request.line}: {e}")
        raise HTTPException(status_code=500, detail="Service busy. Please try again later.")
