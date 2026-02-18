import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/question.dart';
import '../models/solution.dart';

/// Real Supabase-backed discussion repository.
/// Replaces MockDiscussionRepository for production use.
class SupabaseDiscussionRepository {
  final SupabaseClient _client;

  SupabaseDiscussionRepository(this._client);

  // ── Questions ──

  Future<List<Question>> getQuestions() async {
    try {
      final response = await _client
          .from('questions')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Question.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      return [];
    }
  }

  Future<Question> addQuestion({
    required String transcript,
    required String crop,
    required String category,
    required String authorId,
    required String farmerName,
    required String location,
    String? englishText,
    String? audioUrl,
    double latitude = 0,
    double longitude = 0,
    List<double>? embedding,
  }) async {
    final Map<String, dynamic> insertData = {
      'user_id': authorId,
      'original_text': transcript,
      'english_text': englishText,
      'crop': crop,
      'category': category,
      'farmer_name': farmerName,
      'location': location,
      'audio_url': audioUrl,
      'latitude': latitude,
      'longitude': longitude,
      'status': 'open',
      'reply_count': 0,
      'karma': 0,
    };

    // Add embedding if provided
    if (embedding != null) {
      insertData['embedding'] = embedding;
    }

    final response = await _client.from('questions').insert(insertData).select().single();

    return Question.fromJson(response);
  }

  // ── Solutions (mapped to 'answers' table) ──

  Future<List<Solution>> getSolutions(String questionId) async {
    try {
      final response = await _client
          .from('answers')
          .select()
          .eq('question_id', questionId)
          .order('karma', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Solution.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching solutions: $e');
      return [];
    }
  }

  Future<Solution> addSolution({
    required String questionId,
    required String transcript,
  }) async {
    final userId = _client.auth.currentUser?.id;

    final response = await _client.from('answers').insert({
      'question_id': questionId,
      'user_id': userId,
      'answer_text': transcript,
      'farmer_name': _client.auth.currentUser?.userMetadata?['full_name'] ?? 'Farmer',
      'karma': 10,
      'is_verified': false,
    }).select().single();

    // Increment reply_count on the question
    try {
      await _client.rpc('increment_reply_count', params: {
        'q_id': questionId,
      });
    } catch (e) {
      // Non-blocking: just increment locally
      debugPrint('Could not increment reply count: $e');
    }

    return Solution.fromJson(response);
  }

  Future<void> upvoteSolution(String solutionId) async {
    try {
      await _client.rpc('increment_answer_karma', params: {
        'a_id': solutionId,
        'points': 5,
      });
    } catch (e) {
      // Fallback: direct update
      debugPrint('RPC upvote failed, trying direct update: $e');
      try {
        // Get current karma then update
        final current = await _client
            .from('answers')
            .select('karma')
            .eq('id', solutionId)
            .single();
        final currentKarma = current['karma'] as int? ?? 0;
        await _client
            .from('answers')
            .update({'karma': currentKarma + 5})
            .eq('id', solutionId);
      } catch (e2) {
        debugPrint('Direct upvote also failed: $e2');
      }
    }
  }
}
