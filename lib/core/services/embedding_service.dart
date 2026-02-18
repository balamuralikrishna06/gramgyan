import 'package:google_generative_ai/google_generative_ai.dart';
import '../../core/services/gemini_service.dart'; // Reuse key if possible, or duplicate

class EmbeddingService {
  // Reuse API Key from GeminiService if accessible, or hardcode for now as per instructions implies standalone
  // Ideally this should be in Env
  static const String _apiKey = 'AIzaSyAUwlFsvW0HY3AbH0yPl_SLpMY0ez595To'; 
  late final GenerativeModel _embeddingModel;

  EmbeddingService() {
    _embeddingModel = GenerativeModel(
      model: 'text-embedding-004', // Or 'embedding-001'
      apiKey: _apiKey,
    );
  }

  Future<List<double>> generateEmbedding(String text) async {
    try {
      final content = Content.text(text);
      final result = await _embeddingModel.embedContent(content);
      
      if (result.embedding.values.isEmpty) {
        throw Exception('Generated embedding is empty');
      }
      
      // text-embedding-004 returns 768 dimensions usually
      return result.embedding.values;
    } catch (e) {
      throw Exception('Failed to generate embedding: $e');
    }
  }
}
