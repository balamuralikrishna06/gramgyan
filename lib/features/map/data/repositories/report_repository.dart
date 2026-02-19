import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../domain/models/report.dart';
import '../../../../core/services/gemini_service.dart';

class ReportRepository {
  final SupabaseClient _client;
  final GeminiService _geminiService;

  ReportRepository(this._client, this._geminiService);

  /// Creates a new report in the Supabase 'knowledge_posts' table (for Questions/Issues).
  Future<Report> createReport({
    required String userId,
    required double latitude,
    required double longitude,
    required String crop,
    required String category,
    File? audioFile,
    String? manualTranscript, 
    String? translatedText, 
    String type = 'question', 
  }) async {
    try {
      String transcript = manualTranscript ?? '';
      String? audioUrl;
      
      // 1. Upload Audio if present
      if (audioFile != null) {
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _client.storage.from('knowledge-audio').upload(
          fileName,
          audioFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        audioUrl = _client.storage.from('knowledge-audio').getPublicUrl(fileName);
      }

      // 2. Insert into 'knowledge_posts' table
      final response = await _client.from('knowledge_posts').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'original_text': transcript,
        'english_text': translatedText,
        'language': 'Unknown',
        'audio_url': audioUrl,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      final reportId = response['id'];

      // 3. Trigger Process Report (Async)
      _client.functions.invoke(
        'process-report',
        body: {
          'report_id': reportId,
          'original_text': transcript,
          'translated_text': translatedText,
          'type': type
        }
      ).ignore();

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  /// Creates a new post in 'knowledge_posts' table (for Sharing Knowledge).
  /// Generates embeddings using Gemini.
  Future<void> createKnowledgePost({
    required String userId,
    required double latitude,
    required double longitude,
    File? audioFile,
    required String manualTranscript,
    String? translatedText,
  }) async {
    try {
      String? audioUrl;
      
      // 1. Upload Audio if present
      if (audioFile != null) {
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _client.storage.from('knowledge-audio').upload(
          fileName,
          audioFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        audioUrl = _client.storage.from('knowledge-audio').getPublicUrl(fileName);
      }

      // 2. Generate Embedding (Gemini)
      List<double>? embedding;
      try {
        final String effectiveTranslatedText = translatedText ?? '';
        final textToEmbed = effectiveTranslatedText.isNotEmpty ? effectiveTranslatedText : manualTranscript;
        if (textToEmbed.isNotEmpty) {
           embedding = await _geminiService.generateEmbedding(textToEmbed);
        }
      } catch (e) {
        debugPrint('Embedding generation failed: $e');
      }

      // 3. Insert into 'knowledge_posts'
      await _client.from('knowledge_posts').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'original_text': manualTranscript,
        'english_text': translatedText,
        'language': 'Unknown', // Could be detected language
        'audio_url': audioUrl,
        'created_at': DateTime.now().toIso8601String(),
        'embedding': embedding,
      });

    } catch (e) {
      throw Exception('Failed to create knowledge post: $e');
    }
  }

  /// Searches for similar knowledge posts using embeddings.
  Future<List<Map<String, dynamic>>> searchSimilarKnowledge(String queryText) async {
    try {
      final embedding = await _geminiService.generateQueryEmbedding(queryText);
      if (embedding == null) return [];

      final List<dynamic> response = await _client.rpc(
        'match_knowledge',
        params: {
          'query_embedding': embedding,
          'match_threshold': 0.78, // Higher threshold for more accurate matching
          'match_count': 3,
        },
      );

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('Error searching knowledge: $e');
      return [];
    }
  }

  /// Creates a question record when no matching knowledge is found.
  Future<void> createQuestion({
    required String userId,
    required String originalText,
    String? englishText,
    required double latitude,
    required double longitude,
    File? audioFile,
  }) async {
    try {
      String? audioUrl;
      
      // 1. Upload Audio if present
      if (audioFile != null) {
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _client.storage.from('knowledge-audio').upload(
          fileName,
          audioFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        audioUrl = _client.storage.from('knowledge-audio').getPublicUrl(fileName);
      }
      
      // 2. Generate Embedding
      List<double>? embedding;
      if (englishText != null && englishText.isNotEmpty) {
        try {
          embedding = await _geminiService.generateEmbedding(englishText);
        } catch (e) {
          debugPrint('Question Embedding Failed: $e');
        }
      }

      await _client.from('questions').insert({
        'user_id': userId,
        'original_text': originalText,
        'english_text': englishText,
        'embedding': embedding,
        'latitude': latitude,
        'longitude': longitude,
        'audio_url': audioUrl,
        'location': await _getLocationName(latitude, longitude), 
        'status': 'open',
      });
    } catch (e) {
      debugPrint('Error creating question: $e');
      // Non-blocking error, but good to log
    }
  }

  /// Helper to get a readable location name
  Future<String> _getLocationName(double lat, double lng) async {
    try {
      if (lat == 0 && lng == 0) return 'Unknown Location';
      
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        // Construct a simple location string: "Village, District"
        final parts = [
          place.subLocality, 
          place.locality, 
          place.administrativeArea
        ].where((e) => e != null && e.isNotEmpty).toSet().toList(); // Remove duplicates
        
        return parts.isNotEmpty ? parts.join(', ') : 'Unknown Location';
      }
    } catch (e) {
      debugPrint('Geocoding error: $e');
    }
    return 'Unknown Location';
  }
}
