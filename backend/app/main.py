from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import get_settings
from app.routes import speech
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger(__name__)

from app.services.firebase import initialize_firebase

# ... 

settings = get_settings()

# Initialize Firebase
initialize_firebase()

app = FastAPI(
    title=settings.APP_NAME,
    openapi_url=f"{settings.API_V1_STR}/openapi.json"
)

# Set all CORS enabled origins
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

from app.routes import speech, auth, gemini
import logging

# ... imports ...

app.include_router(speech.router, prefix="/api/v1/speech", tags=["speech"])
app.include_router(auth.router, prefix="/auth", tags=["auth"])
app.include_router(gemini.router, prefix="/api/v1/gemini", tags=["gemini"])

@app.get("/")
async def root():
    return {"message": "Welcome to GramGyan Backend", "status": "running"}

@app.get("/health")
def health_check():
    return {
        "status": "ok", 
        "app_name": settings.APP_NAME,
        "debug_mode": settings.DEBUG
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("app.main:app", host="0.0.0.0", port=8000, reload=True)
