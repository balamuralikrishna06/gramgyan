import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class StorageService {
  final SupabaseClient _client;

  StorageService(this._client);

  Future<String> uploadAudio(File audioFile) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      await _client.storage.from('knowledge-audio').upload(
        fileName,
        audioFile,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final audioUrl = _client.storage
          .from('knowledge-audio')
          .getPublicUrl(fileName);
          
      return audioUrl;
    } catch (e) {
      throw Exception('Failed to upload audio safely: $e');
    }
  }
}
