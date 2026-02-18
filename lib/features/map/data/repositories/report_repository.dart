import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/report.dart';
import '../../../../core/services/gemini_service.dart';

class ReportRepository {
  final SupabaseClient _client;
  final GeminiService _geminiService;

  ReportRepository(this._client, this._geminiService);

  /// Creates a new report in the Supabase 'reports' table (for Questions/Issues).
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

      // 2. Insert into 'reports' table
      final response = await _client.from('reports').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'crop': crop,
        'category': category,
        'transcript': transcript,
        'translated_transcript': translatedText, // Can be passed or null
        'audio_url': audioUrl,
        'ai_generated': false,
        'created_at': DateTime.now().toIso8601String(),
        'type': type, 
        'status': 'open',
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
}
