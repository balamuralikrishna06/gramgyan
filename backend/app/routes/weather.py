import httpx
from fastapi import APIRouter, HTTPException, Query
from app.core.config import get_settings
import logging

router = APIRouter()
config = get_settings()
logger = logging.getLogger(__name__)

@router.get("/")
async def get_current_weather(
    lat: float = Query(..., description="Latitude"),
    lon: float = Query(..., description="Longitude")
):
    """
    Proxies requests securely to OpenWeather using backend credentials.
    Returns stripped-down JSON with just temp and humidity.
    """
    if not config.OPENWEATHER_API_KEY:
        raise HTTPException(status_code=500, detail="Weather API key not configured on backend.")
        
    url = f"https://api.openweathermap.org/data/2.5/weather?lat={lat}&lon={lon}&appid={config.OPENWEATHER_API_KEY}&units=metric"
    
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url)
            response.raise_for_status()
            data = response.json()
            return {
                "temperature": float(data.get("main", {}).get("temp", 0.0)),
                "humidity": float(data.get("main", {}).get("humidity", 0.0)),
                "latitude": lat,
                "longitude": lon
            }
    except httpx.HTTPStatusError as e:
        logger.error(f"OpenWeather API Error: {e.response.text}")
        raise HTTPException(status_code=e.response.status_code, detail="Error fetching weather data from OpenWeather.")
    except Exception as e:
        logger.error(f"Weather Network Error: {e}")
        raise HTTPException(status_code=500, detail=str(e))
