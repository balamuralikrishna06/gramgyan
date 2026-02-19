import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "GramGyan Backend"
    API_V1_STR: str = "/api/v1"
    SARVAM_API_KEY: str
    DEBUG: bool = False
    
    # Msg91
    MSG91_AUTH_KEY: str | None = None
    MSG91_TEMPLATE_ID: str | None = None
    
    # Supabase
    SUPABASE_URL: str | None = None
    SUPABASE_SERVICE_ROLE_KEY: str | None = None
    SUPABASE_JWT_SECRET: str | None = None

    model_config = SettingsConfigDict(env_file=".env", env_ignore_empty=True, extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
