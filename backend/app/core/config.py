import os
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache

class Settings(BaseSettings):
    APP_NAME: str = "GramGyan Backend"
    API_V1_STR: str = "/api/v1"
    SARVAM_API_KEY: str

    model_config = SettingsConfigDict(env_file=".env", env_ignore_empty=True, extra="ignore")

@lru_cache()
def get_settings():
    return Settings()
