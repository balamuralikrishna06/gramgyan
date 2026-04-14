import httpx
from fastapi import APIRouter, HTTPException, Request
from app.core.config import get_settings
import logging

router = APIRouter()
config = get_settings()
logger = logging.getLogger(__name__)

async def _proxy_to_n8n(url: str, payload: dict):
    if not url:
        raise HTTPException(status_code=500, detail="n8n webhook URL not configured on backend.")
        
    try:
        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(url, json=payload)
            response.raise_for_status()
            
            # n8n can sometimes return empty responses or JSON arrays
            try:
                return response.json()
            except ValueError:
                return response.text
                
    except httpx.HTTPStatusError as e:
        logger.error(f"n8n API Error ({e.response.status_code}): {e.response.text}")
        raise HTTPException(status_code=e.response.status_code, detail="Webhook failed.")
    except Exception as e:
        logger.error(f"n8n Network Error: {e}")
        raise HTTPException(status_code=500, detail="Internal Service Error.")

@router.post("/news")
async def get_agri_news(request: Request):
    payload = await request.json()
    return await _proxy_to_n8n(config.N8N_NEWS_WEBHOOK_URL, payload)

@router.post("/report")
async def generate_report(request: Request):
    payload = await request.json()
    return await _proxy_to_n8n(config.N8N_REPORT_WEBHOOK_URL, payload)
