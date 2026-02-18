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
}
