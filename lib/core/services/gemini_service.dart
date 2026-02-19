import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class GeminiService {
  // Using the verified working API Key
  // Using the verified working API Key
  // static const String apiKey = 'AIzaSyDE4R7kKKi7R0vSvVPtltNJBMLTcqGEiGI'; 
  
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-2.5-flash', 
      apiKey: AppConstants.geminiApiKey,
    );
  }

  /// Helper to execute Gemini requests with retry logic for Rate Limits (429)
  Future<GenerateContentResponse> _generateWithRetry(List<Content> prompt, {int maxRetries = 5}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await _model.generateContent(prompt);
      } catch (e) {
        attempt++;
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('429') || 
            errorStr.contains('resource has been exhausted') ||
            errorStr.contains('quota') ||
            errorStr.contains('limit')) {
          debugPrint('Gemini Rate Limit/Quota hit. Retrying in ${2 * attempt} seconds...');
          await Future.delayed(Duration(seconds: 2 * attempt));
        } else {
          // Re-throw if it's likely not a transient rate limit
          rethrow;
        }
      }
    }
    throw Exception('Gemini Rate Limit Exceeded after $maxRetries retries.');
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

  /// Generates a document embedding from English text.
  /// Used for storing knowledge posts and questions.
  Future<List<double>?> generateEmbedding(String text) async {
    if (text.isEmpty) return null;
    
    try {
      debugPrint('Gemini: Generating embedding for: "${text.substring(0, text.length > 20 ? 20 : text.length)}..."');
      final embeddingModel = GenerativeModel(
        model: 'models/gemini-embedding-001',
        apiKey: AppConstants.geminiApiKey, 
      );
      final content = Content.text(text);
      final result = await embeddingModel.embedContent(content, taskType: TaskType.retrievalDocument);
      debugPrint('Gemini: Embedding generated successfully. Length: ${result.embedding.values.length}');
      return result.embedding.values;
    } catch (e) {
      debugPrint('Gemini Embedding Error (gemini-embedding-001): $e');
      // Fallback to older model
      try {
        debugPrint('Gemini: Retrying with models/embedding-001...');
        final fallbackModel = GenerativeModel(
          model: 'models/embedding-001',
          apiKey: AppConstants.geminiApiKey,
        );
        final content = Content.text(text);
        final result = await fallbackModel.embedContent(content, taskType: TaskType.retrievalDocument);
        return result.embedding.values;
      } catch (e2) {
        debugPrint('Gemini Fallback Embedding Error: $e2');
        return null;
      }
    }
  }

  /// Generates a query embedding optimized for searching.
  /// Uses TaskType.retrievalQuery for accurate similarity matching.
  Future<List<double>?> generateQueryEmbedding(String text) async {
    if (text.isEmpty) return null;
    
    try {
      final embeddingModel = GenerativeModel(
        model: 'models/gemini-embedding-001',
        apiKey: AppConstants.geminiApiKey, 
      );
      final content = Content.text(text);
      final result = await embeddingModel.embedContent(content, taskType: TaskType.retrievalQuery);
      return result.embedding.values;
    } catch (e) {
      debugPrint('Gemini Query Embedding Error: $e');
       // Fallback to older model
      try {
        final fallbackModel = GenerativeModel(
          model: 'models/embedding-001',
          apiKey: AppConstants.geminiApiKey,
        );
        final content = Content.text(text);
        final result = await fallbackModel.embedContent(content, taskType: TaskType.retrievalQuery);
        return result.embedding.values;
      } catch (e2) {
        return null;
      }
    }
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
      final prompt = 'Provide a clear, simple agricultural solution for this farmer question: "$query". Keep the answer concise and easy to understand for a farmer.';
      final response = await _generateWithRetry([Content.text(prompt)]);
      return response.text?.trim() ?? 'I could not generate an answer at this time.';
    } catch (e) {
      debugPrint('Gemini Multi-turn Answer Error: $e');
      return 'I could not generate an answer at this time. Please try again later.';
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
}
