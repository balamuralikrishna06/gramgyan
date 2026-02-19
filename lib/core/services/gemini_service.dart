import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class GeminiService {
  // Using the verified working API Key
  // Using the verified working API Key
  // Using the verified working API Key
  
  List<String> _apiKeys = [];
  int _currentKeyIndex = 0;
  late GenerativeModel _model;

  GeminiService() {
    _apiKeys = AppConstants.geminiApiKeys;
    if (_apiKeys.isEmpty) {
      debugPrint('Warning: No Gemini API keys found in .env');
    }
    _initializeModel();
  }

  void _initializeModel() {
    if (_apiKeys.isNotEmpty) {
      final key = _apiKeys[_currentKeyIndex];
      _model = GenerativeModel(
        model: 'gemini-2.5-flash', 
        apiKey: key,
      );
      debugPrint('GeminiService initialized with key index: $_currentKeyIndex');
    }
  }

  void _rotateKey() {
    if (_apiKeys.length <= 1) return; // No other keys to rotate to
    
    _currentKeyIndex = (_currentKeyIndex + 1) % _apiKeys.length;
    debugPrint('🔄 Rotating Gemini API Key to index: $_currentKeyIndex');
    _initializeModel();
  }

  /// Helper to execute Gemini requests with retry logic and Key Rotation
  Future<GenerateContentResponse> _generateWithRetry(List<Content> prompt, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await _model.generateContent(prompt);
      } catch (e) {
        attempt++;
        final errorStr = e.toString().toLowerCase();
        
        // Check for Quota/Rate Limit errors
        if (errorStr.contains('429') || 
            errorStr.contains('resource has been exhausted') ||
            errorStr.contains('quota') ||
            errorStr.contains('limit')) {
          
          debugPrint('⚠️ Gemini Rate Limit hit (Attempt $attempt). Rotating key...');
          _rotateKey();
          
          // Add a small delay even after rotation to be safe
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          // Re-throw if it's likely not a transient rate limit
          rethrow;
        }
      }
    }
    throw Exception('Gemini Rate Limit Exceeded after $maxRetries retries (Keys rotated).');
  }

  /// Transcribes audio file to text using the 'transcribe-audio' Edge Function (Whisper)
  Future<String> transcribeAudio(File audioFile) async {
    try {
      final supabase = Supabase.instance.client;
      final fileName = 'temp_${DateTime.now().millisecondsSinceEpoch}.m4a';

      // 1. Upload to 'audio' bucket (temp file for transcription)
      await supabase.storage.from('audio').upload(
        fileName,
        audioFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      // 2. Get Public URL
      final audioUrl = supabase.storage.from('audio').getPublicUrl(fileName);

      // 3. Call Edge Function
      final response = await supabase.functions.invoke(
        'transcribe-audio',
        body: {'audioUrl': audioUrl} 
      );

      if (response.data != null && response.data['transcript'] != null) {
        return response.data['transcript'];
      } else {
         return 'Error: No transcript returned from AI';
      }

    } catch (e) {
      throw Exception('Failed to transcribe audio: $e');
    }
  }

  /// internal helper for embeddings with rotation
  Future<List<double>?> _generateEmbeddingWithRotation(String text, TaskType taskType) async {
    int maxRetries = 3; 
    int attempt = 0;
    
    while (attempt < maxRetries) {
      try {
        final currentKey = _apiKeys.isNotEmpty ? _apiKeys[_currentKeyIndex] : '';
        if (currentKey.isEmpty) return null;

        // Try Primary Model
        try {
          final embeddingModel = GenerativeModel(
            model: 'models/gemini-embedding-001',
            apiKey: currentKey, 
          );
          final content = Content.text(text);
          final result = await embeddingModel.embedContent(content, taskType: taskType);
          return result.embedding.values;
        } catch (e) {
             final errorStr = e.toString().toLowerCase();
             if (errorStr.contains('429') || errorStr.contains('quota') || errorStr.contains('limit')) {
               throw e; // Rethrow to outer loop for rotation
             }
             // Otherwise try fallback model
             debugPrint('Primary embedding failed ($e). Trying fallback...');
             final fallbackModel = GenerativeModel(
                model: 'models/embedding-001',
                apiKey: currentKey,
             );
             final content = Content.text(text);
             final result = await fallbackModel.embedContent(content, taskType: taskType);
             return result.embedding.values;
        }
      } catch (e) {
        attempt++;
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('429') || 
            errorStr.contains('resource has been exhausted') ||
            errorStr.contains('quota') ||
            errorStr.contains('limit')) {
          
          debugPrint('⚠️ Gemini Embedding Rate Limit hit. Rotating key...');
          _rotateKey();
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          debugPrint('Embedding Error: $e');
          return null; // Non-retriable error
        }
      }
    }
    return null;
  }

  /// Generates a document embedding from English text.
  /// Used for storing knowledge posts and questions.
  Future<List<double>?> generateEmbedding(String text) async {
    if (text.isEmpty) return null;
    return _generateEmbeddingWithRotation(text, TaskType.retrievalDocument);
  }

  /// Generates a query embedding optimized for searching.
  /// Uses TaskType.retrievalQuery for accurate similarity matching.
  Future<List<double>?> generateQueryEmbedding(String text) async {
    if (text.isEmpty) return null;
    return _generateEmbeddingWithRotation(text, TaskType.retrievalQuery);
  }

  /// Translates text to the target language
  Future<String> translateText(String text, String targetLang) async {
    try {
      final prompt = 'Translate the following text to $targetLang:\n\n$text';
      final response = await _generateWithRetry([Content.text(prompt)]);
      return response.text?.trim() ?? text;
    } catch (e) {
      // Return original text on failure to avoid blocking
      return text;
    }
  }

  /// Generates a clear agricultural solution for a farmer question.
  Future<String> generateAnswer(String query) async {
    try {
      final prompt = 'Provide a clear, simple agricultural solution for this farmer question: "$query". Keep the answer concise and easy to understand for a farmer. The answer MUST be in Tamil language.';
      final response = await _generateWithRetry([Content.text(prompt)]);
      return response.text?.trim() ?? 'தற்போது என்னால் பதில் அளிக்க முடியவில்லை.';
    } catch (e) {
      debugPrint('Gemini Multi-turn Answer Error: $e');
      return 'தற்போது என்னால் பதில் அளிக்க முடியவில்லை. தயவுசெய்து சிறிது நேரம் கழித்து முயற்சிக்கவும்.';
    }
  }
  /// Checks if the content is safe and scientifically valid agricultural advice.
  /// Returns a record with (isSafe, reason).
  Future<({bool isSafe, String? reason})> checkSafety(String text) async {
    try {
      final prompt = '''
You are a STRICT Agricultural Knowledge Verifier.
Your job is to filter out ANY content that is not a valid, helpful, and accurate agricultural tip.

Text to Verify: "$text"

Reply with ONLY a JSON object:
{
  "safe": true/false,
  "reason": "EXACT reason why it failed (e.g., 'Not related to farming', 'Scientifically incorrect', 'Vague/Spam')"
}

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
''';

      final response = await _generateWithRetry([Content.text(prompt)]);
      final responseText = response.text?.trim() ?? '';
      debugPrint('Gemini Safety Check Raw Response: $responseText');
      
      // Basic cleaning to handle potential markdown code blocks
      final jsonString = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      if (jsonString.toLowerCase().contains('"safe": true')) {
        debugPrint('Gemini: Content marked as SAFE');
        return (isSafe: true, reason: 'Verified Safe by AI');
      } else if (jsonString.toLowerCase().contains('"safe": false')) {
        // Extract reason roughly
        final reasonMatch = RegExp(r'"reason":\s*"(.*?)"').firstMatch(jsonString);
        final reason = reasonMatch?.group(1) ?? 'Flagged as unsafe/irrelevant by AI';
        debugPrint('Gemini: Content marked as UNSAFE. Reason: $reason');
        return (isSafe: false, reason: reason);
      }
      
      // Fallback: If AI fails to parse, FLAG IT as unsafe just to be sure.
      debugPrint('Gemini: Parsing failed, defaulting to UNSAFE for manual review.');
      return (isSafe: false, reason: 'AI parsing failed, requires human review');
      
    } catch (e) {
      debugPrint('Safety Check Failed: $e');
      return (isSafe: true, reason: 'AI Check Error'); // Allow but maybe flag in UI later
    }
  }
  /// Analyzes a crop image and query to diagnose diseases using Multimodal input.
  Future<String> analyzeCropDisease(File imageFile, String query) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      
      // Construct the Master Prompt
      final promptText = '''
Role: You are the "Gram Gyan" Senior Multimodal Agronomist. Your mission is to support rural farmers in India by identifying crop diseases and providing actionable, safe, and culturally relevant farming advice.

Step-by-Step Logic:
1. Visual Diagnosis: Carefully inspect the image. Identify the crop and detect symptoms like necrosis, chlorosis, fungal growth, or pest infestation.
2. Contextual Analysis: Cross-reference the visual symptoms with the user's description: "$query"
3. Validation: If the image is not related to agriculture, or is too blurry to identify, politely ask for a clearer photo.
4. Treatment Plan: Provide a dual solution (Organic and Chemical).
5. Radar Impact: Determine if this issue is contagious.

Response Constraints (Strict JSON):
Return ONLY a JSON object with this structure:
{
"crop": "string",
"diagnosis": "string",
"confidence_score": 0.0 to 1.0,
"solutions": {
"organic": "string",
"chemical": "string"
},
"prevention_tips": ["tip 1", "tip 2"],
"radar_severity": "LOW" | "MEDIUM" | "HIGH",
"summary_for_farmer": "A friendly, empathetic summary STRICTLY IN TAMIL language."
}
''';

      final content = [
        Content.multi([
          TextPart(promptText),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await _generateWithRetry(content);
      return response.text?.trim() ?? 'பிழை: பகுப்பாய்வு உருவாக்கப்படவில்லை.';
    } catch (e) {
      debugPrint('Gemini Crop Analysis Error: $e');
      return 'பிழை: பயிரை பகுப்பாய்வு செய்ய முடியவில்லை. ${e.toString()}';
    }
  }
}
