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

def is_tamil(text: str) -> bool:
    """Checks if the text contains Tamil characters."""
    for char in text:
        if '\u0B80' <= char <= '\u0BFF':
            return True
    return False

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
        # We perform STT (defaulting to ta-IN as it often handles mixed speech well)
        transcript = await speech_to_text(temp_filename, source_language)
        
        # 2. Language Detection & Translation
        detected_source_lang = source_language
        detected_target_lang = target_language

        if not transcript or not transcript.strip():
             translation = ""
        else:
             if is_tamil(transcript):
                 # It's Tamil, proceed with translation to English
                 detected_source_lang = "ta-IN"
                 detected_target_lang = "en-IN"
                 translation = await translate_text(transcript, detected_source_lang, detected_target_lang)
             else:
                 # It's likely English (or at least not Tamil), so we treat it as English
                 # User Requirement: "if it is english no need for translation"
                 detected_source_lang = "en-IN"
                 # We set translation same as transcript so the UI shows it clearly in the "Translation" box too,
                 # or we could leave it empty. Setting it to transcript makes the "English Translation" field useful.
                 translation = transcript 
                 detected_target_lang = "en-IN"

        return ProcessResponse(
            transcript=transcript,
            translation=translation,
            source_language=detected_source_lang,
            target_language=detected_target_lang
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

@router.get("/stream")
async def stream_text(text: str, language_code: str = "ta-IN"):
    """
    GET endpoint for instant streaming via audio players.
    """
    if not text:
        raise HTTPException(status_code=400, detail="Text is required")
    try:
        audio_content = await text_to_speech(text, language_code)
        
        def iterfile():
            yield audio_content
            
        return StreamingResponse(iterfile(), media_type="audio/wav")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
