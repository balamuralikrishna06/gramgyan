import httpx
import base64
import logging
from app.core.config import get_settings

config = get_settings()
logger = logging.getLogger(__name__)

SARVAM_STT_URL = "https://api.sarvam.ai/speech-to-text"
SARVAM_TTS_URL = "https://api.sarvam.ai/text-to-speech"
SARVAM_TRANSLATE_URL = "https://api.sarvam.ai/translate"
SARVAM_TRANSLITERATE_URL = "https://api.sarvam.ai/transliterate"

# ── Key Rotation ──────────────────────────────────────────────────────────────

def _get_api_keys() -> list[str]:
    """Returns a list of available Sarvam API keys (primary first, backup second)."""
    keys = [config.SARVAM_API_KEY]
    if config.SARVAM_API_KEY_2:
        keys.append(config.SARVAM_API_KEY_2)
    return keys

def _should_fallback(status_code: int) -> bool:
    """Determines if the error warrants trying the next key."""
    # 401 = invalid key, 403 = forbidden, 429 = quota exceeded
    return status_code in (401, 403, 429)


import os
import re

# ── Tanglish Detection ────────────────────────────────────────────────────────

def _is_tanglish(text: str, language_code: str) -> bool:
    """Returns True if the text is in Latin script but the expected language is non-English."""
    if language_code == "en-IN":
        return False  # English is expected to be Latin
    if not text or not text.strip():
        return False
    # If >80% of non-space characters are ASCII/Latin, it's likely Tanglish
    stripped = text.replace(" ", "")
    latin_chars = sum(1 for c in stripped if ord(c) < 128)
    return (latin_chars / len(stripped)) > 0.80 if stripped else False

async def transliterate_to_native_script(text: str, language_code: str) -> str:
    """
    Converts a Tanglish/romanized string to native Indic script using Sarvam /transliterate.
    e.g. 'Vanakkam' -> 'வணக்கம்' for ta-IN
    """
    keys = _get_api_keys()
    for key in keys:
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                payload = {
                    "input": text,
                    "source_language_code": "en-IN",   # Tanglish is treated as English input
                    "target_language_code": language_code,
                    "speaker_gender": "Male",
                    "mode": "classic-colloquial",
                    "numerals_format": "international",
                    "output_script": "fully-native",
                }
                headers = {
                    "api-subscription-key": key,
                    "Content-Type": "application/json",
                }
                response = await client.post(SARVAM_TRANSLITERATE_URL, json=payload, headers=headers)
                if response.status_code == 200:
                    result = response.json()
                    native = result.get("transliterated_text", text)
                    logger.info(f"Transliterated '{text[:50]}' -> '{native[:50]}' [{language_code}]")
                    return native
                else:
                    logger.warning(f"Transliterate failed ({response.status_code}): {response.text[:200]}")
        except Exception as e:
            logger.warning(f"Transliterate exception: {e}")
    return text  # fallback: return original if transliteration fails


# ── Speech-to-Text ────────────────────────────────────────────────────────────

def _get_audio_mime_type(file_path: str) -> str:
    """Return correct MIME type based on file extension."""
    ext = os.path.splitext(file_path)[1].lower()
    mime_map = {
        ".wav": "audio/wav",
        ".wave": "audio/wav",
        ".mp3": "audio/mpeg",
        ".m4a": "audio/mp4",
        ".mp4": "audio/mp4",
        ".ogg": "audio/ogg",
        ".webm": "audio/webm",
        ".flac": "audio/flac",
    }
    return mime_map.get(ext, "audio/wav")

async def speech_to_text(audio_file_path: str, language_code: str = "ta-IN") -> str:
    """
    Converts speech to text using Sarvam AI.
    Automatically falls back to the secondary API key if the primary hits quota/auth errors.
    """
    keys = _get_api_keys()
    last_error = None

    for i, key in enumerate(keys):
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                with open(audio_file_path, "rb") as f:
                    files = {"file": (os.path.basename(audio_file_path), f, _get_audio_mime_type(audio_file_path))}
                    headers = {"api-subscription-key": key}
                    data = {"model": "saarika:v2.5", "language_code": language_code}

                    response = await client.post(
                        SARVAM_STT_URL, headers=headers, files=files, data=data
                    )

                    if _should_fallback(response.status_code) and i < len(keys) - 1:
                        logger.warning(
                            f"Sarvam STT key {i+1} failed ({response.status_code}). "
                            f"Trying key {i+2}..."
                        )
                        last_error = response.text
                        continue

                    response.raise_for_status()
                    result = response.json()
                    transcript = result.get("transcript", "")
                    logger.info(f"STT [{language_code}] → '{transcript[:80]}...' (file: {os.path.basename(audio_file_path)})")
                    return transcript

        except httpx.HTTPStatusError as e:
            if _should_fallback(e.response.status_code) and i < len(keys) - 1:
                logger.warning(
                    f"Sarvam STT key {i+1} failed ({e.response.status_code}). "
                    f"Trying key {i+2}..."
                )
                last_error = e.response.text
                continue
            raise Exception(f"Sarvam API Error: {e.response.text}") from e
        except Exception as e:
            raise e

    raise Exception(f"All Sarvam API keys exhausted. Last error: {last_error}")


# ── Translation ───────────────────────────────────────────────────────────────

async def translate_text(
    text: str,
    source_language: str = "ta-IN",
    target_language: str = "en-IN",
) -> str:
    """
    Translates text using Sarvam AI with automatic key fallback.
    """
    keys = _get_api_keys()
    last_error = None

    for i, key in enumerate(keys):
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                headers = {
                    "api-subscription-key": key,
                    "Content-Type": "application/json",
                }
                payload = {
                    "input": text,
                    "source_language_code": source_language,
                    "target_language_code": target_language,
                    "speaker_gender": "Female",
                    "mode": "formal",
                    "model": "mayura:v1",
                }

                response = await client.post(
                    SARVAM_TRANSLATE_URL, headers=headers, json=payload
                )

                if _should_fallback(response.status_code) and i < len(keys) - 1:
                    logger.warning(
                        f"Sarvam Translate key {i+1} failed ({response.status_code}). "
                        f"Trying key {i+2}..."
                    )
                    last_error = response.text
                    continue

                response.raise_for_status()
                result = response.json()
                return result.get("translated_text", "")

        except httpx.HTTPStatusError as e:
            if _should_fallback(e.response.status_code) and i < len(keys) - 1:
                logger.warning(
                    f"Sarvam Translate key {i+1} failed ({e.response.status_code}). "
                    f"Trying key {i+2}..."
                )
                last_error = e.response.text
                continue
            raise Exception(f"Sarvam API Error: {e.response.text}") from e
        except Exception as e:
            raise e

    raise Exception(f"All Sarvam API keys exhausted. Last error: {last_error}")


# ── Text-to-Speech ────────────────────────────────────────────────────────────

async def text_to_speech(text: str, language_code: str = "ta-IN") -> bytes:
    """
    Converts text to speech using Sarvam AI with automatic key fallback.
    """
    keys = _get_api_keys()
    last_error = None

    for i, key in enumerate(keys):
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                headers = {
                    "api-subscription-key": key,
                    "Content-Type": "application/json",
                }
                payload = {
                    "inputs": [text],
                    "target_language_code": language_code,
                    "speaker": "shubh",
                    "model": "bulbul:v3",
                }

                response = await client.post(
                    SARVAM_TTS_URL, headers=headers, json=payload
                )

                if _should_fallback(response.status_code) and i < len(keys) - 1:
                    logger.warning(
                        f"Sarvam TTS key {i+1} failed ({response.status_code}). "
                        f"Trying key {i+2}..."
                    )
                    last_error = response.text
                    continue

                response.raise_for_status()
                result = response.json()
                audio_base64 = result.get("audios", [])[0]
                return base64.b64decode(audio_base64)

        except httpx.HTTPStatusError as e:
            if _should_fallback(e.response.status_code) and i < len(keys) - 1:
                logger.warning(
                    f"Sarvam TTS key {i+1} failed ({e.response.status_code}). "
                    f"Trying key {i+2}..."
                )
                last_error = e.response.text
                continue
            raise e
        except Exception as e:
            raise e

    raise Exception(f"All Sarvam API keys exhausted. Last error: {last_error}")
