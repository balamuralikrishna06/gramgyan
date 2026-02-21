import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class GeminiService {
  static const String _baseUrl = '${AppConstants.backendUrl}api/v1/gemini';

  GeminiService() {
    debugPrint('GeminiService initialized to hit remote backend $_baseUrl');
  }

  /// Generates a clear agricultural solution for a farmer question.
  Future<String> generateAnswer(String query) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/answer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': query}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['answer'] ?? 'தற்போது என்னால் பதில் அளிக்க முடியவில்லை.';
      } else {
        debugPrint('Gemini Answer Error: ${response.statusCode} - ${response.body}');
        return 'தற்போது என்னால் பதில் அளிக்க முடியவில்லை. தயவுசெய்து சிறிது நேரம் கழித்து முயற்சிக்கவும்.';
      }
    } catch (e) {
      debugPrint('Gemini Network Error: $e');
      return 'தற்போது என்னால் பதில் அளிக்க முடியவில்லை. பிணையப் பிழை.';
    }
  }

  /// Checks if the content is safe and scientifically valid agricultural advice.
  /// Returns a record with (isSafe, reason).
  Future<({bool isSafe, String? reason})> checkSafety(String text) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/safety-check'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final bool isSafe = data['is_safe'] ?? false;
        final String reason = data['reason'] ?? 'Unknown Reason';
        
        if (isSafe) {
          debugPrint('Backend Gemini: Content marked as SAFE');
        } else {
          debugPrint('Backend Gemini: Content marked as UNSAFE. Reason: $reason');
        }
        return (isSafe: isSafe, reason: reason);
      } else {
        debugPrint('Gemini Safety Check HTTP Error: ${response.statusCode}');
        return (isSafe: false, reason: 'Backend Server Error');
      }
    } catch (e) {
      debugPrint('Safety Check Failed: $e');
      return (isSafe: true, reason: 'Network/Plugin Error'); 
    }
  }

  /// Generates a document embedding from English text.
  Future<List<double>?> generateEmbedding(String text) async {
    if (text.isEmpty) return null;
    return _fetchEmbedding(text, 'document');
  }

  /// Generates a query embedding optimized for searching.
  Future<List<double>?> generateQueryEmbedding(String text) async {
    if (text.isEmpty) return null;
    return _fetchEmbedding(text, 'query');
  }

  Future<List<double>?> _fetchEmbedding(String text, String type) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/embed/$type'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> embeddingDynamic = data['embedding'];
        return embeddingDynamic.map((e) => (e as num).toDouble()).toList();
      } else {
        debugPrint('Gemini Embedding HTTP Error ($type): ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Gemini Embedding Network Error: $e');
      return null;
    }
  }

  /// Translates text to the target language via backend
  Future<String> translateText(String text, String targetLang) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': text, 'target_language': targetLang}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['translated_text'] ?? text;
      }
      return text;
    } catch (e) {
      debugPrint('Gemini Translate Network Error: $e');
      return text;
    }
  }

  /// Transcribes audio file to text using the 'transcribe-audio' Edge Function (Whisper).
  /// (Kept this pointing to Supabase Edge function as in the original code,
  ///  but Sarvam STT in backend/speech.py is the alternative)
  Future<String> transcribeAudio(File audioFile) async {
    try {
      // NOTE: This uses supabase_flutter which was removed from imports in your rewrite, 
      // but if the app relies on it here, we will re-add the import.
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

  /// Analyzes a crop image and query to diagnose diseases using backend Multimodal input.
  Future<String> analyzeCropDisease(File imageFile, String query) async {
    try {
      final uri = Uri.parse('$_baseUrl/analyze-crop');
      var request = http.MultipartRequest('POST', uri);
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        imageFile.path,
      ));
      request.fields['query'] = query;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['analysis'] ?? 'பிழை: பகுப்பாய்வு உருவாக்கப்படவில்லை.';
      } else {
        debugPrint('Gemini Crop Analysis HTTP Error: ${response.statusCode} - ${response.body}');
        return 'பிழை: பயிரை பகுப்பாய்வு செய்ய முடியவில்லை.';
      }

    } catch (e) {
      debugPrint('Gemini Crop Analysis Error: $e');
      return 'பிழை: பயிரை பகுப்பாய்வு செய்ய முடியவில்லை. \${e.toString()}';
    }
  }
}
