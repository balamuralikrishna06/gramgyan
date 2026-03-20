import httpx
import json
import logging
from app.core.config import get_settings

config = get_settings()
logger = logging.getLogger(__name__)

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.3-70b-versatile"

def _get_api_keys() -> list[str]:
    keys = []
    if config.GROQ_API_KEY:
        keys.append(config.GROQ_API_KEY)
    if config.GROQ_API_KEY_2:
        keys.append(config.GROQ_API_KEY_2)
    return keys

def _should_fallback(status_code: int) -> bool:
    return status_code in (401, 403, 429)

def _language_name(code: str) -> str:
    lang_map = {
        'ta': 'Tamil', 'hi': 'Hindi', 'te': 'Telugu', 'kn': 'Kannada',
        'ml': 'Malayalam', 'bn': 'Bengali', 'mr': 'Marathi', 'gu': 'Gujarati',
        'pa': 'Punjabi', 'or': 'Odia'
    }
    return lang_map.get(code[:2], 'English')

async def analyze_crops(
    predicted_top_crop: str,
    nitrogen: float, phosphorus: float, potassium: float, ph: float,
    rainfall: float, temperature: float, humidity: float,
    language_code: str = "en"
) -> list[dict]:
    keys = _get_api_keys()
    if not keys:
        raise Exception("Groq API key is not configured in backend.")

    ml_hint = f"An ML model predicted: {predicted_top_crop} for these values." if predicted_top_crop and predicted_top_crop != "Unknown" else ""

    prompt = (
        "You are an expert agricultural AI for Indian farmers. "
        "You have deep knowledge of the Kaggle Crop Recommendation dataset "
        "which contains these key crop profiles (N/P/K in kg/ha, temp in C, humidity %, rainfall in mm):\n"
        "- Rice:       N=60-100, P=35-60, K=35-45, temp=20-27, humidity=80-85, rainfall=183-298\n"
        "- Maize:      N=60-100, P=35-60, K=15-25, temp=18-27, humidity=55-74, rainfall=60-110\n"
        "- Chickpea:   N=20-60,  P=55-80, K=75-85, temp=17-21, humidity=14-20, rainfall=65-95\n"
        "- KidneyBeans:N=0-40,   P=55-80, K=15-25, temp=15-24, humidity=18-25, rainfall=60-150\n"
        "- PigeonPeas: N=0-40,   P=55-80, K=15-25, temp=18-37, humidity=30-68, rainfall=90-199\n"
        "- MothBeans:  N=0-40,   P=35-60, K=15-25, temp=24-32, humidity=40-65, rainfall=30-75\n"
        "- MungBean:   N=0-40,   P=35-60, K=15-25, temp=27-30, humidity=80-90, rainfall=36-60\n"
        "- BlackGram:  N=20-60,  P=55-80, K=15-25, temp=25-35, humidity=60-70, rainfall=60-75\n"
        "- Lentil:     N=18-28,  P=55-80, K=15-25, temp=18-24, humidity=60-70, rainfall=36-60\n"
        "- Pomegranate:N=0-20,   P=55-80, K=35-45, temp=18-24, humidity=85-95, rainfall=100-130\n"
        "- Banana:     N=80-120, P=55-80, K=45-55, temp=25-30, humidity=78-92, rainfall=100-160\n"
        "- Mango:      N=0-20,   P=15-25, K=25-35, temp=27-37, humidity=45-55, rainfall=90-130\n"
        "- Grapes:     N=0-20,   P=55-80, K=35-45, temp=8-42,  humidity=80-90, rainfall=65-80\n"
        "- Watermelon: N=80-120, P=55-80, K=45-55, temp=24-27, humidity=83-97, rainfall=50-60\n"
        "- Muskmelon:  N=80-100, P=55-80, K=45-55, temp=28-32, humidity=90-95, rainfall=20-35\n"
        "- Apple:      N=0-20,   P=55-80, K=35-45, temp=0-22,  humidity=90-95, rainfall=100-125\n"
        "- Orange:     N=0-20,   P=15-25, K=5-15,  temp=10-35, humidity=90-95, rainfall=100-120\n"
        "- Papaya:     N=40-60,  P=55-80, K=35-45, temp=33-38, humidity=92-97, rainfall=145-175\n"
        "- Coconut:    N=0-20,   P=15-25, K=25-35, temp=25-30, humidity=90-95, rainfall=100-150\n"
        "- Cotton:     N=100-140,P=35-60, K=15-25, temp=23-37, humidity=79-92, rainfall=60-100\n"
        "- Jute:       N=60-80,  P=35-60, K=35-45, temp=23-27, humidity=78-92, rainfall=150-200\n"
        "- Coffee:     N=100-140,P=15-25, K=25-35, temp=22-30, humidity=55-65, rainfall=158-200\n\n"
        f"A farmer entered these values:\n"
        f"- N: {nitrogen}  P: {phosphorus}  K: {potassium}  pH: {ph}\n"
        f"- Temperature: {temperature:.1f} C  Humidity: {humidity:.1f}%  Rainfall: {rainfall:.0f} mm\n"
        f"{ml_hint}\n\n"
        "Recommend TOP 5 crops that best match ALL parameters simultaneously. "
        "Give priority to crops with the closest N/P/K/temp/humidity/rainfall match. "
        "Indian context: prefer crops actually grown in India.\n\n"
        "Return ONLY a valid JSON array of exactly 5 objects with these fields:\n"
        '- "crop": string (ALWAYS in English)\n'
        '- "confidence_score": 0.0-1.0 (descending order)\n'
        '- "risk_level": "Low"/"Medium"/"High"\n'
        '- "risk_cause": string (one sentence)\n'
        '- "why_suitable": string (two sentences)\n'
        '- "improvement_steps": array of 3 strings\n'
        '- "planting_advice": array of 4 strings\n\n'
        f"IMPORTANT: Write ALL text fields in {_language_name(language_code)}. "
        'Keep the "crop" field in English.\nNo markdown, no extra text. Only the JSON array.'
    )

    request_body = {
        "model": GROQ_MODEL,
        "messages": [{"role": "user", "content": prompt}],
        "temperature": 0.5,
        "frequency_penalty": 0.3,
        "presence_penalty": 0.3,
        "max_tokens": 4096,
    }

    last_error = None

    for i, key in enumerate(keys):
        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    GROQ_URL,
                    headers={"Content-Type": "application/json", "Authorization": f"Bearer {key}"},
                    json=request_body
                )

                if _should_fallback(response.status_code) and i < len(keys) - 1:
                    logger.warning(f"Groq key {i+1} failed ({response.status_code}). Trying key {i+2}...")
                    last_error = response.text
                    continue

                response.raise_for_status()
                content = response.json()['choices'][0]['message']['content']
                cleaned = content.replace('```json', '').replace('```', '').strip()

                try:
                    return json.loads(cleaned)
                except json.JSONDecodeError:
                    start, end = content.find('['), content.rfind(']')
                    if start != -1 and end > start:
                        return json.loads(content[start:end+1])
                    raise Exception(f"Could not parse Groq response as JSON: {content}")

        except httpx.HTTPStatusError as e:
            if _should_fallback(e.response.status_code) and i < len(keys) - 1:
                logger.warning(f"Groq key {i+1} HTTP error ({e.response.status_code}). Trying key {i+2}...")
                last_error = e.response.text
                continue
            raise Exception(f"Groq AI error ({e.response.status_code}): {e.response.text}") from e

    raise Exception(f"All Groq API keys exhausted. Last error: {last_error}")
