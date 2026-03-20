import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';

class EmbeddingService {
  /// Generates an embedding vector for the given [text] via the backend.
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.backendPrimaryUrl}/api/v1/gemini/embed/document'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('Embedding API error (${response.statusCode})');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final values = data['embedding'] as List<dynamic>;
      return values.map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      debugPrint('⚠️ Embedding failed: $e. Using zero vector fallback.');
      return List<double>.filled(768, 0.0);
    }
  }
}
