import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/report.dart';
import '../../../../core/services/gemini_service.dart';

class ReportRepository {
  final SupabaseClient _client;
  final GeminiService _geminiService;

  ReportRepository(this._client, this._geminiService);

  /// Creates a new report in the Supabase 'reports' table.
  /// 
  /// If [audioFile] is provided:
  /// 1. Uploads audio to Supabase Storage.
  /// 2. Transcribes audio to text (original language).
  /// 3. Translates text to English.
  Future<Report> createReport({
    required String userId,
    required double latitude,
    required double longitude,
    required String crop,
    required String category,
    File? audioFile,
    String? manualTranscript, // If user typed instead of speaking
    String type = 'question', // Added type parameter
  }) async {
    try {
      String transcript = manualTranscript ?? '';
      String? audioUrl;
      String? translatedTranscript;
      String originalLanguage = 'Unknown'; // Initialize variable

      if (audioFile != null) {
        // 1. Upload Audio
        final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _client.storage.from('audio').upload(
          fileName,
          audioFile,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        
        // Get Public URL
        audioUrl = _client.storage.from('audio').getPublicUrl(fileName);

        // 2. Transcribe via Edge Function
        try {
          final response = await _client.functions.invoke(
            'transcribe-audio',
            body: {'audioUrl': audioUrl} 
          );
          
          if (response.data != null) {
             transcript = response.data['transcript'] ?? '';
             originalLanguage = response.data['language'] ?? 'Unknown';
          }
        } catch (e) {
          print('Edge Function Transcribe Error: $e');
          // Fallback to client-side or empty logic if needed
          // For now, we proceed with whatever we have
        }
      }

      // 3. Insert Report
      final response = await _client.from('reports').insert({
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'crop': crop,
        'category': category,
        'transcript': transcript,
        'translated_transcript': null, // Will be filled by process-report
        // 'original_language': originalLanguage, // Column missing in DB
        'audio_url': audioUrl,
        'ai_generated': false,
        'created_at': DateTime.now().toIso8601String(),
        'type': type, 
        'status': 'open',
      }).select().single();

      final reportId = response['id'];

      // 4. Trigger Process Report (Async/Fire-and-forget)
      _client.functions.invoke(
        'process-report',
        body: {
          'report_id': reportId,
          'transcript': transcript,
          'type': type
        }
      ).ignore(); // Don't wait for it

      return Report.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }
}

