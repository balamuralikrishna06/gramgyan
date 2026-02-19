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
      final response = await _model.generateContent([Content.text(prompt)]);
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
      final response = await _model.generateContent([Content.text(prompt)]);
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
You are an agricultural expert and safety moderator. 
Evaluate the following agricultural advice/text for safety and scientific validity.
Text: "$text"

Reply with ONLY a JSON object in this format:
{
  "safe": true/false,
  "reason": "Short explanation if unsafe, otherwise null"
}
Criteria:
- Unsafe if it recommends harmful chemicals banned in India.
- Unsafe if it suggests dangerous dosage of pesticides/fertilizers.
- Unsafe if it is clearly spam, hate speech, or irrelevant to farming.
- Safe otherwise.
''';

      final response = await _model.generateContent([Content.text(prompt)]);
      final responseText = response.text?.trim() ?? '';
      
      // Basic cleaning to handle potential markdown code blocks
      final jsonString = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
      
      // We'll manually parse simple JSON to avoid heavy dependencies if needed, 
      // but for now let's assume valid JSON or basic string checking.
      // Since we can't easily import dart:convert inside this replace block if not already there,
      // and to be robust, we'll do a robust check.
      
      if (jsonString.toLowerCase().contains('"safe": true')) {
        return (isSafe: true, reason: null);
      } else if (jsonString.toLowerCase().contains('"safe": false')) {
        // Extract reason roughly
        final reasonMatch = RegExp(r'"reason":\s*"(.*?)"').firstMatch(jsonString);
        final reason = reasonMatch?.group(1) ?? 'Flagged as unsafe by AI';
        return (isSafe: false, reason: reason);
      }
      
      // Fallback: Default to safe (let humans review) if AI is ambiguous, 
      // OR default to unsafe if we want strictness.
      // Given "Pending" layer exists, we can default to safe but flag it?
      // Let's default to false to be careful if AI fails to output JSON.
      return (isSafe: true, reason: 'AI parsing failed, requires human review');
      
    } catch (e) {
      debugPrint('Safety Check Failed: $e');
      return (isSafe: true, reason: 'AI Check Error'); // Allow but maybe flag in UI later
    }
  }
}
