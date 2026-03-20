import 'package:flutter/foundation.dart';
import 'gemini_service.dart';

class EmbeddingService {
  final GeminiService _geminiService;

  EmbeddingService() : _geminiService = GeminiService();

  Future<List<double>> generateEmbedding(String text) async {
    try {
      final result = await _geminiService.generateEmbedding(text);
      if (result == null || result.isEmpty) {
        throw Exception('Generated embedding is empty');
      }
      return result;
    } catch (e) {
      debugPrint('⚠️ Embedding failed via backend. Using dummy embedding.');
      // Fallback: Generate a zero vector of size 768 so the app doesn't crash
      return List<double>.filled(768, 0.0);
    }
  }
}
