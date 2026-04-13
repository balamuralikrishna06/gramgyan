import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';

class OllamaService {
  /// Laptop IP for Real Device testing (Updated for current network)
  static const String _realDeviceIp = '10.154.197.85';
  static const String _emulatorIp = '10.0.2.2';
  static const String _port = '11434';
  
  static const String _model = 'llama3.2:1b';

  /// Detects the correct host based on whether we are in emulator or real device.
  Future<String> _getOllamaBaseUrl() async {
    String host = _realDeviceIp;

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        if (!androidInfo.isPhysicalDevice) {
          debugPrint('OllamaService: Emulator detected, using $_emulatorIp');
          host = _emulatorIp;
        } else {
          debugPrint('OllamaService: Physical device detected, using $_realDeviceIp');
        }
      } catch (e) {
        debugPrint('OllamaService: Error detecting device type: $e');
      }
    }
    
    return 'http://$host:$_port/api/generate';
  }

  /// Generates an agricultural answer using the local Llama model via Ollama.
  /// [language] is the full name of the language (e.g., "Tamil").
  Future<String> generateLlamaAnswer(String query, {String language = 'English'}) async {
    // Forceful decision logic to prevent 'False-Refusals'
    final decisionPrompt = """
### TASK
You are "Gram Gyan AI", a dedicated Indian Agricultural Expert.

### DECISION RULES:
1. IF the user asks about crops, farming, soil, or weather -> ANSWER THE QUESTION DIRECTLY.
2. IF the user asks about non-farming topics (Sports, Politics, Movies, IPL, Actors) -> ONLY say: "I am sorry, but I am your dedicated Agricultural Assistant. I can only help you with farming and crop-related questions."

### EXAMPLES:
User: "What is ipl?"
Response: "I am sorry, but I am your dedicated Agricultural Assistant. I can only help you with farming and crop-related questions."

User: "How to grow tomatoes?"
Response: "Tomatoes require well-drained soil and 6-8 hours of sunlight. Here are the steps..."

User: "What are the major crops in India?"
Response: "The major crops in India include Rice, Wheat, Cotton, and Sugarcane..."

### CURRENT CONTEXT:
USER QUESTION: "$query"
LANGUAGE: $language

### RESPONSE (Respond in $language only):
""";

    try {
      final url = await _getOllamaBaseUrl();
      debugPrint('OllamaService: Requesting Llama at $url');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _model,
          'prompt': decisionPrompt,
          'stream': false,
          'options': {
            'temperature': 0.1, // Near-zero creativity to enforce strict rules
            'num_predict': 350,
          }
        }),
      ).timeout(const Duration(seconds: 45));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['response']?.toString().trim() ?? 'No response from local AI.';
      } else {
        debugPrint('Ollama Error: ${response.statusCode}');
        return 'Local AI server returned an error (${response.statusCode}).';
      }
    } on http.ClientException catch (e) {
      debugPrint('Ollama Connection Error: $e');
      throw Exception('OFFLINE_SERVER_NOT_FOUND');
    } catch (e) {
      debugPrint('Ollama General Error: $e');
      return 'Sorry, something went wrong with the local AI: $e';
    }
  }
}
