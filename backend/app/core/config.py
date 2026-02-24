import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "GramGyan Backend"
    API_V1_STR: str = "/api/v1"
    SARVAM_API_KEY: str
    SARVAM_API_KEY_2: str | None = None  # Fallback key if primary hits quota
    GEMINI_API_KEY: str | None = None # Add this in Render Env
    GEMINI_API_KEYS: str | None = None # Comma separated for rotation
    DEBUG: bool = False
    
    # Auth & Database
    FIREBASE_CREDENTIALS_PATH: str
    SUPABASE_URL: str
    SUPABASE_SERVICE_ROLE_KEY: str

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
