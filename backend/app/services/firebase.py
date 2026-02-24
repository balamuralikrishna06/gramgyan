import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import get_settings
import logging

logger = logging.getLogger(__name__)
settings = get_settings()

def initialize_firebase():
    """Initialize Firebase Admin SDK"""
    try:
        if not firebase_admin._apps:
            cred = credentials.Certificate(settings.FIREBASE_CREDENTIALS_PATH)
            firebase_admin.initialize_app(cred)
            logger.info("Firebase Admin SDK initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize Firebase Admin SDK: {e}")
        raise

def verify_token(id_token: str):
    """Verify Firebase ID Token"""
    try:
        decoded_token = auth.verify_id_token(id_token)
        return decoded_token
    except Exception as e:
        logger.error(f"Token verification failed: {e}")
        return None
