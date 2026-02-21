import google.generativeai as genai
from app.core.config import get_settings
import logging

logger = logging.getLogger(__name__)
settings = get_settings()

class GeminiService:
    def __init__(self):
        self.api_keys = []
        self.current_key_index = 0
        self._initialize_keys()

    def _initialize_keys(self):
        # Support comma-separated keys for rotation
        if settings.GEMINI_API_KEYS:
            self.api_keys = [k.strip() for k in settings.GEMINI_API_KEYS.split(",") if k.strip()]
        
        if not self.api_keys and settings.GEMINI_API_KEY:
            self.api_keys = [settings.GEMINI_API_KEY]
            
        if not self.api_keys:
            logger.warning("No Gemini API keys found in config.")
            return

        self._configure_model()

    def _configure_model(self):
        if not self.api_keys:
            return
            
        key = self.api_keys[self.current_key_index]
        genai.configure(api_key=key)
        self.model = genai.GenerativeModel('gemini-2.5-flash')
        logger.info(f"GeminiService configured with key index: {self.current_key_index}")

    def _rotate_key(self):
        if len(self.api_keys) <= 1:
            return
        self.current_key_index = (self.current_key_index + 1) % len(self.api_keys)
        logger.info(f"Rotating Gemini API Key to index: {self.current_key_index}")
        self._configure_model()

    async def _generate_with_retry(self, prompt, max_retries=3):
        attempt = 0
        while attempt < max_retries:
            try:
                response = await self.model.generate_content_async(prompt)
                return response.text
            except Exception as e:
                attempt += 1
                error_str = str(e).lower()
                
                # Check for rate limit or quota exhausted
                if "429" in error_str or "quota" in error_str or "limit" in error_str or "resource has been exhausted" in error_str:
                    logger.warning(f"Gemini Rate Limit hit (Attempt {attempt}). Rotating key...")
                    self._rotate_key()
                else:
                    raise e
        
        raise Exception(f"Gemini Rate Limit Exceeded after {max_retries} retries (Keys rotated).")

    async def generate_answer(self, query: str) -> str:
        prompt = f'Provide a clear, simple agricultural solution for this farmer question: "{query}". Keep the answer concise and easy to understand for a farmer. The answer MUST be in Tamil language.'
        try:
            return await self._generate_with_retry(prompt)
        except Exception as e:
            logger.error(f"Gemini Multi-turn Answer Error: {e}")
            return f"DEBUG ERROR: {type(e).__name__} - {str(e)}"

    async def check_safety(self, text: str) -> dict:
        prompt = f'''
You are a STRICT Agricultural Knowledge Verifier.
Your job is to filter out ANY content that is not a valid, helpful, and accurate agricultural tip.

Text to Verify: "{text}"

Reply with ONLY a JSON object:
{{
  "safe": true/false,
  "reason": "EXACT reason why it failed (e.g., 'Not related to farming', 'Scientifically incorrect', 'Vague/Spam')"
}}

STRICT CRITERIA for "safe": true:
1. MUST be about Agriculture, Farming, Livestock, or Crops.
2. MUST be scientifically ACCURATE and helpful.
3. MUST be a clear tip or knowledge (not just "Hello" or a question).

FLAG AS UNSAFE ("safe": false) IF:
- Irrelevant to farming (e.g., Politics, Sports, General Greeting, Human Health).
- Scientifically incorrect (e.g., "Pour battery acid on crops").
- Vague or Spam (e.g., "Good morning", "Test", "Call me").
- Harmful / Dangerous.

If in doubt, FLAG AS UNSAFE.
'''
        try:
            response_text = await self._generate_with_retry(prompt)
            json_string = response_text.replace('```json', '').replace('```', '').strip().lower()
            
            if '"safe": true' in json_string:
                return {"is_safe": True, "reason": "Verified Safe by AI"}
            elif '"safe": false' in json_string:
                import re
                match = re.search(r'"reason":\s*"(.*?)"', json_string)
                reason = match.group(1) if match else "Flagged as unsafe/irrelevant by AI"
                return {"is_safe": False, "reason": reason}
            
            return {"is_safe": False, "reason": "AI parsing failed, requires human review"}
            
        except Exception as e:
            logger.error(f"Safety Check Failed: {e}")
            return {"is_safe": True, "reason": "AI Check Error"} # Allow but might flag in UI later

    async def _generate_embedding_with_rotation(self, text: str, task_type: str = "RETRIEVAL_DOCUMENT"):
        max_retries = 3
        attempt = 0
        
        while attempt < max_retries:
            try:
                if not self.api_keys:
                    return None
                current_key = self.api_keys[self.current_key_index]
                
                try:
                    # Configure specifically for embedding
                    genai.configure(api_key=current_key)
                    result = genai.embed_content(
                        model="models/gemini-embedding-001",
                        content=text,
                        task_type=task_type
                    )
                    return result['embedding']
                except Exception as e:
                    error_str = str(e).lower()
                    if "429" in error_str or "quota" in error_str or "limit" in error_str:
                         raise e
                    
                    logger.warning(f"Primary embedding failed ({e}). Trying fallback...")
                    # Fallback
                    result = genai.embed_content(
                        model="models/embedding-001",
                        content=text,
                        task_type=task_type
                    )
                    return result['embedding']
                    
            except Exception as e:
                attempt += 1
                error_str = str(e).lower()
                
                if "429" in error_str or "quota" in error_str or "limit" in error_str or "resource has been exhausted" in error_str:
                    logger.warning("Gemini Embedding Rate Limit hit. Rotating key...")
                    self._rotate_key()
                else:
                    logger.error(f"Embedding Error: {e}")
                    return None
        return None

    async def generate_document_embedding(self, text: str):
        if not text: return None
        return await self._generate_embedding_with_rotation(text, "RETRIEVAL_DOCUMENT")

    async def generate_query_embedding(self, text: str):
        if not text: return None
        return await self._generate_embedding_with_rotation(text, "RETRIEVAL_QUERY")

    async def analyze_crop_disease(self, image_bytes: bytes, query: str) -> str:
        prompt_text = f'''
Role: You are the "Gram Gyan" Senior Multimodal Agronomist. Your mission is to support rural farmers in India by identifying crop diseases and providing actionable, safe, and culturally relevant farming advice.

Step-by-Step Logic:
1. Visual Diagnosis: Carefully inspect the image. Identify the crop and detect symptoms like necrosis, chlorosis, fungal growth, or pest infestation.
2. Contextual Analysis: Cross-reference the visual symptoms with the user's description: "{query}"
3. Validation: If the image is not related to agriculture, or is too blurry to identify, politely ask for a clearer photo.
4. Treatment Plan: Provide a dual solution (Organic and Chemical).
5. Radar Impact: Determine if this issue is contagious.

Response Constraints (Strict JSON):
Return ONLY a JSON object with this structure:
{{
"crop": "string",
"diagnosis": "string",
"confidence_score": 0.0 to 1.0,
"solutions": {{
"organic": "string",
"chemical": "string"
}},
"prevention_tips": ["tip 1", "tip 2"],
"radar_severity": "LOW" | "MEDIUM" | "HIGH",
"summary_for_farmer": "A friendly, empathetic summary STRICTLY IN TAMIL language."
}}
'''
        try:
            # We must use proper multi-part message structure for Gemini vision
            content = [
                prompt_text,
                {"mime_type": "image/jpeg", "data": image_bytes}
            ]
            response_text = await self._generate_with_retry(content)
            return response_text.strip()
        except Exception as e:
            logger.error(f"Gemini Crop Analysis Error: {e}")
            return 'பிழை: பயிரை பகுப்பாய்வு செய்ய முடியவில்லை.'

gemini_service = GeminiService()
