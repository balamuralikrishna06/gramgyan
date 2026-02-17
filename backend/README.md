# GramGyan Backend (Sarvam AI Integration)

This directory contains the FastAPI backend for GramGyan, integrating Sarvam AI for Speech-to-Text (STT) and Text-to-Speech (TTS).

## Prerequisites

- Python 3.9+
- A valid Sarvam AI API Key.

## Setup

1.  **Navigate to the backend directory:**
    ```bash
    cd backend
    ```

2.  **Create a virtual environment (optional but recommended):**
    ```bash
    python -m venv venv
    .\venv\Scripts\activate  # Windows
    # source venv/bin/activate # Linux/Mac
    ```

3.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Configure Environment Variables:**
    Copy `.env.example` to `.env` and add your Sarvam AI API Key.
    ```bash
    copy .env.example .env
    ```
    Edit `.env` and set `SARVAM_API_KEY`.

## Running the Server

Start the development server:

```bash
uvicorn app.main:app --reload
```

The API will be available at `http://localhost:8000`.

## API Documentation

Interactive API docs are available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

### Endpoints

- **POST /api/v1/speech/transcribe**
    - Input: Multipart form data with `file` (audio result).
    - Output: JSON `{"transcript": "...", "language_code": "..."}`.

- **POST /api/v1/speech/speak**
    - Input: JSON body `{"text": "...", "language_code": "ta-IN"}`.
    - Output: Audio file (WAV).

- **GET /health**
    - Health check.

## Mobile Integration

To call these endpoints from Flutter:

1.  **Transcribe:** Use `http.MultipartRequest` to POST audio to `/api/v1/speech/transcribe`.
2.  **Speak:** Use `http.post` with JSON body to `/api/v1/speech/speak`, then play the response bytes.
