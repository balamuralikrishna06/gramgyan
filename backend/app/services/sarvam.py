import httpx
import base64
from app.core.config import get_settings

config = get_settings()

SARVAM_STT_URL = "https://api.sarvam.ai/speech-to-text"
SARVAM_TTS_URL = "https://api.sarvam.ai/text-to-speech"
SARVAM_TRANSLATE_URL = "https://api.sarvam.ai/translate"

async def speech_to_text(audio_file_path: str, language_code: str = "ta-IN") -> str:
    """
    Converts speech to text using Sarvam AI.
    """
    async with httpx.AsyncClient() as client:
        with open(audio_file_path, "rb") as f:
            files = {"file": (audio_file_path, f, "audio/wav")}
            headers = {"api-subscription-key": config.SARVAM_API_KEY}
            
            # Note: Sarvam API parameters might vary. Adjust as per actual API docs.
            # Assuming standard multipart upload for STT.
            data = {"model": "saarika:v2.5", "language_code": language_code}
            
            try:
                response = await client.post(SARVAM_STT_URL, headers=headers, files=files, data=data)
                response.raise_for_status()
                result = response.json()
                return result.get("transcript", "")
            except httpx.HTTPStatusError as e:
                print(f"Error calling Sarvam STT: {e.response.status_code} - {e.response.text}")
                # Re-raise with the detail message if possible, or just log
                raise Exception(f"Sarvam API Error: {e.response.text}") from e
            except Exception as e:
                print(f"An error occurred in STT: {e}")
                raise e

async def translate_text(text: str, source_language: str = "ta-IN", target_language: str = "en-IN") -> str:
    """
    Translates text using Sarvam AI.
    """
    async with httpx.AsyncClient() as client:
        headers = {
            "api-subscription-key": config.SARVAM_API_KEY,
            "Content-Type": "application/json"
        }
        
        payload = {
            "input": text,
            "source_language_code": source_language,
            "target_language_code": target_language,
            "speaker_gender": "Female", # Optional, but sometimes required by certain models
            "mode": "formal", # Optional
            "model": "mayura:v1" # Assuming 'mayura:v1' is the translation model; validating later.
        }
        
        try:
            response = await client.post(SARVAM_TRANSLATE_URL, headers=headers, json=payload)
            response.raise_for_status()
            result = response.json()
            return result.get("translated_text", "")
        except httpx.HTTPStatusError as e:
            print(f"Error calling Sarvam Translation: {e.response.status_code} - {e.response.text}")
            raise Exception(f"Sarvam API Error: {e.response.text}") from e
        except Exception as e:
            print(f"An error occurred in Translation: {e}")
            raise e

async def text_to_speech(text: str, language_code: str = "ta-IN") -> bytes:
    """
    Converts text to speech using Sarvam AI.
    """
    async with httpx.AsyncClient() as client:
        headers = {
            "api-subscription-key": config.SARVAM_API_KEY,
            "Content-Type": "application/json"
        }
        payload = {
            "inputs": [text],
            "target_language_code": language_code,
            "speaker": "kavitha", # Updated to valid speaker
            "model": "bulbul:v3"

        }
        
        try:
            response = await client.post(SARVAM_TTS_URL, headers=headers, json=payload)
            response.raise_for_status()
            
            # Assuming Sarvam returns base64 encoded audio or binary.
            # If JSON with base64:
            result = response.json()
            audio_base64 = result.get("audios", [])[0]
            return base64.b64decode(audio_base64)
            
            # If direct binary:
            # return response.content
        except httpx.HTTPStatusError as e:
            print(f"Error calling Sarvam TTS: {e.response.text}")
            raise e
        except Exception as e:
            print(f"An error occurred: {e}")
            raise e
