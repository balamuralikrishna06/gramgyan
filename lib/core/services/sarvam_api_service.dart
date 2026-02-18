import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../constants/app_constants.dart';

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
  // Use Render Production URL from Constants
  static const String _baseUrl = '${AppConstants.backendUrl}api/v1/speech';
  static const String _sarvamTtsUrl = 'https://api.sarvam.ai/text-to-speech';

  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<SarvamProcessResponse> processAudio(String filePath) async {
    final uri = Uri.parse('$_baseUrl/process');
    
    var request = http.MultipartRequest('POST', uri);
    
    request.files.add(await http.MultipartFile.fromPath(
      'file', 
      filePath,
    ));

    // Add fields if needed
    request.fields['source_language'] = 'ta-IN';
    request.fields['target_language'] = 'en-IN';

    try {
      debugPrint('Sending audio to Sarvam Backend: $uri');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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

  /// Converts text to speech using Sarvam AI TTS (Bulbul v2).
  /// Returns the path to the generated audio file.
  Future<String?> textToSpeech(String text, {String languageCode = 'ta-IN'}) async {
    try {
      debugPrint('Sarvam TTS: Converting text (${text.length} chars) to speech in $languageCode...');
      debugPrint('Sarvam TTS: Text = "$text"');
      
      // Clean the API key (remove any prefix like 'sarvam ')
      final apiKey = AppConstants.sarvamApiKey.trim();
      debugPrint('Sarvam TTS: Using API key starting with: ${apiKey.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse(_sarvamTtsUrl),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': apiKey,
        },
        body: jsonEncode({
          'inputs': [text],
          'target_language_code': languageCode,
          'speaker': 'meera',
          'model': 'bulbul:v2',
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> audios = jsonData['audios'];
        
        if (audios.isNotEmpty) {
          // Decode base64 audio
          final audioBytes = base64Decode(audios[0] as String);
          debugPrint('Sarvam TTS: Decoded ${audioBytes.length} bytes of audio');
          
          // Save to temp file
          final tempDir = await getTemporaryDirectory();
          final audioFile = File('${tempDir.path}/sarvam_tts_${DateTime.now().millisecondsSinceEpoch}.wav');
          await audioFile.writeAsBytes(audioBytes);
          
          debugPrint('Sarvam TTS: Audio saved to ${audioFile.path}');
          return audioFile.path;
        } else {
          debugPrint('Sarvam TTS: No audios in response');
        }
      } else {
        debugPrint('Sarvam TTS Error: ${response.statusCode}');
        debugPrint('Sarvam TTS Error Body: ${response.body}');
      }
    } catch (e) {
      debugPrint('Sarvam TTS Error: $e');
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

  /// Translates text using Sarvam AI Translate API (mayura:v1).
  /// Supports English ↔ Tamil and other Indian languages.
  Future<String> translateText(String text, {
    String sourceLanguage = 'en-IN',
    String targetLanguage = 'ta-IN',
  }) async {
    try {
      debugPrint('Sarvam Translate: $sourceLanguage → $targetLanguage (${text.length} chars)');
      
      final apiKey = AppConstants.sarvamApiKey.trim();
      final response = await http.post(
        Uri.parse('https://api.sarvam.ai/translate'),
        headers: {
          'Content-Type': 'application/json',
          'api-subscription-key': apiKey,
        },
        body: jsonEncode({
          'input': text,
          'source_language_code': sourceLanguage,
          'target_language_code': targetLanguage,
          'model': 'mayura:v1',
          'mode': 'classic-colloquial',
        }),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(utf8.decode(response.bodyBytes));
        final translated = jsonData['translated_text'] as String? ?? text;
        debugPrint('Sarvam Translate: Success → "$translated"');
        return translated;
      } else {
        debugPrint('Sarvam Translate Error: ${response.statusCode} - ${response.body}');
        return text; // Fallback to original
      }
    } catch (e) {
      debugPrint('Sarvam Translate Error: $e');
      return text; // Fallback to original
    }
  }
}
