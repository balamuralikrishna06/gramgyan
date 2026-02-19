import 'package:supabase_flutter/supabase_flutter.dart';

class KnowledgeService {
  final SupabaseClient _client;

  KnowledgeService(this._client);

  Future<void> createPost({
    required String originalText,
    required String englishText,
    required String language,
    required String? audioUrl,
    required double? latitude,
    required double? longitude,
    required List<double> embedding,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _client.from('knowledge_posts').insert({
        'user_id': user.id,
        'original_text': originalText,
        'english_text': englishText,
        'language': language,
        'audio_url': audioUrl,
        'latitude': latitude,
        'longitude': longitude,
        'embedding': embedding,
      });
    } catch (e) {
       throw Exception('Failed to insert knowledge post: $e');
    }
  }

  /// Searches for similar knowledge posts using vector similarity.
  Future<List<Map<String, dynamic>>> matchKnowledge({
    required List<double> queryEmbedding,
    double matchThreshold = 0.75,
    int matchCount = 3,
  }) async {
    try {
      final List<dynamic> response = await _client.rpc(
        'match_knowledge',
        params: {
          'query_embedding': queryEmbedding,
          'match_threshold': matchThreshold,
          'match_count': matchCount,
        },
      );
      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to match knowledge: $e');
    }
  }

  /// Inserts a new question into the community discussion table.
  Future<Map<String, dynamic>> addQuestion({
    required String? authorId,
    required String originalText,
    String? englishText,
    List<double>? embedding,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _client.from('questions').insert({
        'user_id': authorId,
        'original_text': originalText,
        'english_text': englishText,
        'embedding': embedding,
        'latitude': latitude,
        'longitude': longitude,
        'status': 'open',
      }).select().single();
      
      return response;
    } catch (e) {
      throw Exception('Failed to add question: $e');
    }
  }
}
