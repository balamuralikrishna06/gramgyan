from fastapi import APIRouter, BackgroundTasks, HTTPException, Request
import logging
from app.services.supabase import get_supabase_client

router = APIRouter()
logger = logging.getLogger(__name__)

async def process_community_alert(question_id: str, embedding: list, lat: float, lng: float, category: str):
    """
    Background task to process threshold-based community alerts.
    """
    try:
        supabase = get_supabase_client()
        
        # 1. Call the match_recent_questions RPC
        rpc_response = supabase.rpc(
            "match_recent_questions",
            {
                "query_embedding": embedding,
                "query_lat": lat,
                "query_lng": lng,
                "match_threshold": 0.85,
                "max_distance_km": 5.0,
                "days_ago": 30
            }
        ).execute()
        
        data = rpc_response.data
        if not data or len(data) == 0:
            logger.info(f"No match count returned for question {question_id}")
            return
            
        result = data[0]
        match_count = result.get('match_count', 0)
        nearby_user_ids = result.get('nearby_user_ids', [])
        
        logger.info(f"Question {question_id} has {match_count} similar nearby reports.")
        
        # 2. Threshold Check
        if match_count < 4 or not nearby_user_ids:
            # Below threshold, do nothing
            return
            
        # Determine Notification Content
        title = ""
        message = ""
        
        if match_count == 4:
            title = "⚠️ Community Alert"
            message = f"4+ farmers have reported {category} issues nearby. This may be a localized outbreak. Check the Map for details."
        else: # Count > 4
            title = "⚠️ Issue Escalation"
            message = f"The local outbreak is growing. More farmers have reported {category} issues nearby. Check the Map for details."
            
        # 3. Create notifications for all nearby users
        notifications = []
        for user_id in nearby_user_ids:
            notifications.append({
                "user_id": user_id,
                "title": title,
                "message": message,
                "question_id": question_id,
                "is_read": False
            })
            
        if notifications:
            # Insert into Supabase
            supabase.table("notifications").insert(notifications).execute()
            logger.info(f"Inserted {len(notifications)} community alerts.")
            
    except Exception as e:
        logger.error(f"Failed to process community alert: {str(e)}")


@router.post("/question-alerts")
async def handle_question_alert(request: Request, background_tasks: BackgroundTasks):
    """
    Webhook triggered when a new question is added with an embedding and location.
    """
    try:
        payload = await request.json()
        
        question_id = payload.get("question_id")
        embedding = payload.get("embedding")
        lat = payload.get("latitude")
        lng = payload.get("longitude")
        category = payload.get("category", "General")
        
        if not question_id or not embedding or lat is None or lng is None:
            raise HTTPException(status_code=400, detail="Missing required payload fields")
            
        # Add to background tasks so respond immediately
        background_tasks.add_task(
            process_community_alert,
            question_id,
            embedding,
            lat,
            lng,
            category
        )
        
        return {"status": "success", "message": "Alert processing started"}
        
    except Exception as e:
        logger.error(f"Error in handle_question_alert: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))
