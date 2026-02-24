import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/knowledge_post.dart';

/// Real Supabase-backed knowledge repository.
/// Replaces MockKnowledgeRepository for production use.
class SupabaseKnowledgeRepository {
  final SupabaseClient _client;

  SupabaseKnowledgeRepository(this._client);

  /// Fetch all verified posts.
  Future<List<KnowledgePost>> fetchPosts() async {
    try {
      final response = await _client
          .from('knowledge_posts')
          .select()
          .eq('is_verified', true)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => KnowledgePost.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching knowledge posts: $e');
      return [];
    }
  }

  /// Fetch posts filtered by category.
  Future<List<KnowledgePost>> fetchPostsByCategory(String category) async {
    if (category == 'All') {
      return fetchPosts();
    }

    try {
      final response = await _client
          .from('knowledge_posts')
          .select()
          .eq('is_verified', true)
          .eq('category', category)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => KnowledgePost.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching knowledge posts by category: $e');
      return [];
    }
  }

  /// Fetch a single post by ID
  Future<KnowledgePost?> fetchPostById(String id) async {
    try {
      final response = await _client
          .from('knowledge_posts')
          .select()
          .eq('id', id)
          .single();

      return KnowledgePost.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching knowledge post by ID: $e');
      return null;
    }
  }

  /// Upvote a post (increments karma)
  Future<void> upvotePost(String postId) async {
    try {
      // First try to use RPC if it exists
      await _client.rpc('increment_knowledge_karma', params: {
        'post_id': postId,
        'points': 1,
      });
    } catch (e) {
      // Fallback to direct update if RPC doesn't exist
      debugPrint('RPC upvote failed, trying direct update: $e');
      try {
        final current = await _client
            .from('knowledge_posts')
            .select('karma')
            .eq('id', postId)
            .single();
            
        final currentKarma = current['karma'] as int? ?? 0;
        await _client
            .from('knowledge_posts')
            .update({'karma': currentKarma + 1})
            .eq('id', postId);
      } catch (e2) {
        debugPrint('Direct upvote also failed: $e2');
      }
    }
  }
}
