import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
  // Use ngrok URL for remote mobile testing
  static const String _baseUrl = 'https://cadence-remedial-collegiately.ngrok-free.dev/api/v1/speech';

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
}
