import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:async';

// Helper to read API key from .env without flutter dependencies
String getApiKey() {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    // Try looking one level up if run from test dir
    final parentEnv = File('../.env');
    if (parentEnv.existsSync()) return _parseEnv(parentEnv);
    throw Exception('.env file not found');
  }
  return _parseEnv(envFile);
}

String _parseEnv(File file) {
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    if (line.trim().startsWith('GEMINI_API_KEY=')) {
      return line.split('=')[1].trim();
    }
  }
  throw Exception('GEMINI_API_KEY not found in .env');
}

void main() async {
  print('--- Testing Gemini Answer Generation WITH RETRY ---');
  final apiKey = getApiKey();
  final model = GenerativeModel(
    model: 'gemini-2.5-flash', 
    apiKey: apiKey,
  );

  // Helper function mimicking the one added to GeminiService
  Future<GenerateContentResponse> generateWithRetry(List<Content> prompt, {int maxRetries = 3}) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        return await model.generateContent(prompt);
      } catch (e) {
        attempt++;
        final errorStr = e.toString().toLowerCase();
        if (errorStr.contains('429') || 
            errorStr.contains('resource has been exhausted') ||
            errorStr.contains('quota') ||
            errorStr.contains('limit')) {
          print('Gemini Rate Limit/Quota hit. Retrying in ${2 * attempt} seconds...');
          await Future.delayed(Duration(seconds: 2 * attempt));
        } else {
          rethrow;
        }
      }
    }
    throw Exception('Gemini Rate Limit Exceeded after $maxRetries retries.');
  }

  final queries = [
    'How to get roses?',
    'Best fertilizer for paddy?',
    'How to grow tomato?', // Added more to likely trigger limit
    'Watering schedule for cotton?',
  ];

  for (final query in queries) {
    print('\nQuery: "$query"');
    try {
      final prompt = 'Provide a clear, simple agricultural solution for this farmer question: "$query". Keep the answer concise and easy to understand for a farmer.';
      
      final response = await generateWithRetry([Content.text(prompt)]);
      print('SUCCESS: ${response.text?.substring(0, 50)}...');

    } catch (e) {
      print('ERROR: $e');
    }
  }
}
