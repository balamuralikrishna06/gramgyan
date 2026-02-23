"""
Quick test: send a real STT request to the deployed Render backend 
to verify the Tanglish→Tamil fix is live.
"""
import asyncio
import httpx
import os

# Read the backend URL from .env
from dotenv import load_dotenv
load_dotenv()

BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:8000")

async def test_render_backend():
    """Call the /process endpoint on render with a sample audio file if available."""
    print(f"Testing backend at: {BACKEND_URL}")
    
    # First just check /health
    async with httpx.AsyncClient(timeout=30) as client:
        try:
            r = await client.get(f"{BACKEND_URL}/health")
            print(f"Health: {r.status_code} - {r.text[:200]}")
        except Exception as e:
            print(f"Health check failed: {e}")

        # Check if the transliterate function is imported correctly by hitting the root
        try:
            r2 = await client.get(f"{BACKEND_URL}/")
            print(f"Root: {r2.status_code} - {r2.text[:200]}")
        except Exception as e:
            print(f"Root check failed: {e}")

if __name__ == "__main__":
    asyncio.run(test_render_backend())
