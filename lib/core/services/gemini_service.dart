import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class GeminiService {
  // Using the verified working API Key
  static const String apiKey = 'AIzaSyDE4R7kKKi7R0vSvVPtltNJBMLTcqGEiGI'; 
  
  late final GenerativeModel _model;

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
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

  Future<List<double>?> generateEmbedding(String text) async {
    if (text.isEmpty) {
      print('Gemini Embedding: Text is empty');
      return null;
    }
    
    try {
      print('Gemini Embedding: Generating for text length ${text.length}...');
      // Use the embedding model with the valid API key
      final embeddingModel = GenerativeModel(
        model: 'gemini-embedding-001',
        apiKey: apiKey, 
      );
      final content = Content.text(text);
      final result = await embeddingModel.embedContent(content, taskType: TaskType.retrievalDocument);
      print('Gemini Embedding: Success. Vector length: ${result.embedding.values.length}');
      return result.embedding.values;
    } catch (e) {
      print('Gemini Embedding Error: $e');
      return null;
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
}
