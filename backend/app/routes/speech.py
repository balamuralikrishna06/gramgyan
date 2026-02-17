from fastapi import APIRouter, UploadFile, File, HTTPException, BackgroundTasks
from fastapi.responses import JSONResponse, StreamingResponse
from app.services.sarvam import speech_to_text, text_to_speech, translate_text
import shutil
import os
import uuid
from pydantic import BaseModel

router = APIRouter()

class SpeakRequest(BaseModel):
    text: str
    language_code: str = "ta-IN" # Default to Tamil
    target_speaker_gender: str = "female" # optional

class TranslateRequest(BaseModel):
    text: str
    source_language: str = "ta-IN"
    target_language: str = "en-IN"

class ProcessResponse(BaseModel):
    transcript: str
    translation: str
    source_language: str
    target_language: str

@router.post("/transcribe")
async def transcribe_audio(file: UploadFile = File(...), language_code: str = "ta-IN"):
    """
    Accepts an audio file upload and returns the transcription from Sarvam AI.
    """
    # Create a temporary file to save the upload
    temp_filename = f"temp_{uuid.uuid4()}_{file.filename}"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        transcript = await speech_to_text(temp_filename, language_code)
        
        return JSONResponse(content={"transcript": transcript, "language_code": language_code})
    
    except Exception as e:
        error_msg = str(e)
        if "duration greater than 30 seconds" in error_msg:
             raise HTTPException(status_code=400, detail="Audio too long. Sarvam API only supports <30s for real-time. Use shorter audio.")
        if "Sarvam API Error" in error_msg:
             raise HTTPException(status_code=400, detail=error_msg)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        # Clean up the temp file
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

@router.post("/translate")
async def translate(request: TranslateRequest):
    """
    Translates text from source language to target language.
    """
    try:
        translation = await translate_text(request.text, request.source_language, request.target_language)
        return {"translated_text": translation}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/process")
@router.post("/process-audio")
async def process_audio(file: UploadFile = File(...), source_language: str = "ta-IN", target_language: str = "en-IN"):
    """
    Full workflow: Upload Audio -> STT -> Translate -> Return JSON.
    """
    temp_filename = f"temp_{uuid.uuid4()}_{file.filename}"
    try:
        with open(temp_filename, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # 1. STT
        transcript = await speech_to_text(temp_filename, source_language)
        
        # 2. Translation
        translation = await translate_text(transcript, source_language, target_language)
        
        return ProcessResponse(
            transcript=transcript,
            translation=translation,
            source_language=source_language,
            target_language=target_language
        )
    
    except Exception as e:
        error_msg = str(e)
        if "duration greater than 30 seconds" in error_msg:
             raise HTTPException(status_code=400, detail="Audio too long. Sarvam API only supports <30s for real-time. Use shorter audio.")
        if "Sarvam API Error" in error_msg:
             raise HTTPException(status_code=400, detail=error_msg)
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        if os.path.exists(temp_filename):
            os.remove(temp_filename)

@router.post("/speak")
async def speak_text(request: SpeakRequest):
    """
    Converts text to speech and returns an audio file.
    """
    try:
        audio_content = await text_to_speech(request.text, request.language_code)
        
        def iterfile():
            yield audio_content
            
        return StreamingResponse(iterfile(), media_type="audio/wav")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
