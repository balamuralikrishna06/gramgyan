from fastapi import APIRouter, HTTPException, Body
from pydantic import BaseModel
import logging
from app.services.groq import analyze_crops

router = APIRouter()
logger = logging.getLogger(__name__)

class CropAnalysisRequest(BaseModel):
    predicted_top_crop: str
    nitrogen: float
    phosphorus: float
    potassium: float
    ph: float
    rainfall: float
    temperature: float
    humidity: float
    language_code: str = "en"

@router.post("/analyze")
async def analyze_crop_suitability(request: CropAnalysisRequest = Body(...)):
    """
    Analyzes soil/weather data using Groq AI and returns top 5 crop recommendations.
    """
    try:
        results = await analyze_crops(
            predicted_top_crop=request.predicted_top_crop,
            nitrogen=request.nitrogen,
            phosphorus=request.phosphorus,
            potassium=request.potassium,
            ph=request.ph,
            rainfall=request.rainfall,
            temperature=request.temperature,
            humidity=request.humidity,
            language_code=request.language_code
        )
        return {"data": results}
    except Exception as e:
        logger.error(f"Error analyzing crops: {e}")
        raise HTTPException(status_code=500, detail=str(e))
