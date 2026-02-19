import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class EmbeddingService {
  late final GenerativeModel _embeddingModel;

  EmbeddingService() {
    _embeddingModel = GenerativeModel(
      model: 'models/gemini-embedding-001', 
      apiKey: AppConstants.geminiApiKey, // Use the shared key
    );
  }

  Future<List<double>> generateEmbedding(String text) async {
    try {
      final content = Content.text(text);
      final result = await _embeddingModel.embedContent(content);
      
      if (result.embedding.values.isEmpty) {
        throw Exception('Generated embedding is empty');
      }
      
      return result.embedding.values;
    } catch (e) {
      debugPrint('⚠️ Embedding failed (API Key might lack permission). Using dummy embedding.');
      // Fallback: Generate a random/zero vector of size 768 so the app doesn't crash
      // and we can verify Supabase Storage/DB logic.
      return List<double>.filled(768, 0.0);
    }
  }
}
