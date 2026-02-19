import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

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
  print('--- Listing Available Models ---');
  final apiKey = getApiKey();
  final model = GenerativeModel(
    model: 'gemini-pro', // Dummy model to init
    apiKey: apiKey,
  );

  try {
    // There isn't a direct listModels method on GenerativeModel easily accessible in this version 
    // without using the REST API directly, but let's try a known working model 
    // or just try to generate with 'gemini-pro' to see if it works.
    
    // Instead of listing (which requires HTTP), I'll try a few model names.
    final List<String> toTry = ['gemini-pro', 'gemini-1.5-flash', 'gemini-1.0-pro'];
    
    for (final m in toTry) {
      print('\nTesting model: $m');
      final testModel = GenerativeModel(model: m, apiKey: apiKey);
      try {
        final res = await testModel.generateContent([Content.text('Hi')]);
        print('SUCCESS with $m');
      } catch (e) {
        print('FAILED with $m: $e');
      }
    }

  } catch (e) {
    print('Error: $e');
  }
}
