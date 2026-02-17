import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:mime/mime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GeminiService {
  // TODO: Replace with your actual API Key
  static const String _apiKey = 'AIzaSyAUwlFsvW0HY3AbH0yPl_SLpMY0ez595To'; 
  
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
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

  /// Translates text to the target language
  Future<String> translateText(String text, String targetLang) async {
    // Removed mock check

    try {
      final prompt = 'Translate the following text to $targetLang:\n\n$text';
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text?.trim() ?? text;
    } catch (e) {
      throw Exception('Failed to translate text with Gemini: $e');
    }
  }
}
