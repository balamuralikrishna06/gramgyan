import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';
import 'failover_http_client.dart';

class SarvamProcessResponse {
  final String transcript;
  final String translation;
  final String sourceLanguage;
  final String targetLanguage;

  SarvamProcessResponse({
    required this.transcript,
    required this.translation,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  factory SarvamProcessResponse.fromJson(Map<String, dynamic> json) {
    return SarvamProcessResponse(
      transcript: json['transcript'] ?? '',
      translation: json['translation'] ?? '',
      sourceLanguage: json['source_language'] ?? '',
      targetLanguage: json['target_language'] ?? '',
    );
  }
}

class SarvamApiService {
  static final _client = FailoverHttpClient(
    primaryUrl: AppConstants.backendPrimaryUrl,
    fallbackUrl: AppConstants.backendFallbackUrl,
    timeout: const Duration(seconds: 45), // Longer timeout for audio processing
  );

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<SarvamProcessResponse> processAudio(String filePath, {String sourceLanguage = 'ta-IN'}) async {
    try {
      debugPrint('Sending audio to Sarvam Backend via FailoverHttpClient...');
      final response = await _client.postMultipart(
        '/api/v1/speech/process',
        file: File(filePath),
        fileField: 'file',
        fields: {
          'source_language': sourceLanguage,
          'target_language': 'en-IN',
        },
      );

      if (response.statusCode == 200) {
        // Force UTF-8 decoding
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        return SarvamProcessResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to process audio: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Error calling Sarvam API: $e');
      rethrow;
    }
  }

  /// Converts text to speech using the Backend.
  /// Returns the path to the generated audio file.
  Future<String?> textToSpeech(String text, {String languageCode = 'ta-IN'}) async {
    try {
      debugPrint('Sarvam TTS via Backend: Converting text (${text.length} chars) to speech in $languageCode...');
      
      final response = await _client.post(
        '/api/v1/speech/speak',
        body: {
          'text': text,
          'language_code': languageCode,
        },
      );

      if (response.statusCode == 200) {
        final audioBytes = response.bodyBytes;
        
        if (audioBytes.isNotEmpty) {
          debugPrint('Sarvam TTS: Received ${audioBytes.length} bytes of audio from Backend');
          
          // Save to temp file
          final tempDir = await getTemporaryDirectory();
          final audioFile = File('${tempDir.path}/sarvam_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
          await audioFile.writeAsBytes(audioBytes);
          
          debugPrint('Sarvam TTS: Audio saved to ${audioFile.path}');
          return audioFile.path;
        } else {
          debugPrint('Sarvam TTS: Empty audio response from Backend');
        }
      } else {
        debugPrint('Sarvam TTS Backend Error: ${response.statusCode}');
        debugPrint('Sarvam TTS Backend Error Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Sarvam TTS Backend Error: $e');
    }
    return null;
  }

  /// Speaks text in the given language using Sarvam TTS.
  Future<void> speakText(String text, {String languageCode = 'ta-IN'}) async {
    final audioPath = await textToSpeech(text, languageCode: languageCode);
    if (audioPath != null) {
      await _audioPlayer.play(DeviceFileSource(audioPath));
      debugPrint('Sarvam TTS: Playing audio...');
    } else {
      debugPrint('Sarvam TTS: Failed to generate audio');
    }
  }

  /// Stops the current TTS playback.
  Future<void> stopSpeaking() async {
    await _audioPlayer.stop();
  }

  /// Translates text using the Backend.
  /// Supports English ↔ Tamil and other Indian languages.
  Future<String> translateText(String text, {
    String sourceLanguage = 'en-IN',
    String targetLanguage = 'ta-IN',
  }) async {
    try {
      debugPrint('Sarvam Translate via Backend: $sourceLanguage → $targetLanguage (${text.length} chars)');
      
      final response = await _client.post(
        '/api/v1/speech/translate',
        body: {
          'text': text,
          'source_language': sourceLanguage,
          'target_language': targetLanguage,
        },
      );

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
          final translated = jsonData['translated_text'] as String? ?? text;
          debugPrint('Sarvam Translate Backend: Success → "$translated"');
          return translated;
        } catch (_) {
          // If response fails to decode or unexpected format
          return text;
        }
      } else {
        debugPrint('Sarvam Translate Backend Error: ${response.statusCode} - ${response.body}');
        return text; // Fallback to original
      }
    } catch (e) {
      debugPrint('Sarvam Translate Backend Error: $e');
      return text; // Fallback to original
    }
  }
}
