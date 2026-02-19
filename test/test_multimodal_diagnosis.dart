import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';
import 'dart:async';

// Helper to read API key from .env without flutter dependencies
String getApiKey() {
  final envFile = File('.env');
  if (envFile.existsSync()) return _parseEnv(envFile);
  
  // Try looking one level up if run from test dir
  final parentEnv = File('../.env');
  if (parentEnv.existsSync()) return _parseEnv(parentEnv);
  
  throw Exception('.env file not found');
}

String _parseEnv(File file) {
  final lines = file.readAsLinesSync();
  for (var line in lines) {
    // Check for multi-key first
    if (line.trim().startsWith('GEMINI_API_KEYS=')) {
      final keys = line.split('=')[1].trim();
      if (keys.isNotEmpty) {
        return keys.split(',').first.trim();
      }
    }
    // Fallback to single key
    if (line.trim().startsWith('GEMINI_API_KEY=')) {
      return line.split('=')[1].trim();
    }
  }
  throw Exception('GEMINI_API_KEYS not found in .env');
}

void main(List<String> args) async {
  print('--- Testing Multimodal Crop Diagnosis ---');
  
  if (args.isEmpty) {
    print('Usage: dart test/test_multimodal_diagnosis.dart <path_to_crop_image>');
    print('Example: dart test/test_multimodal_diagnosis.dart test/assets/tomato_leaf.jpg');
    exit(1);
  }

  final imagePath = args[0];
  final imageFile = File(imagePath);

  if (!imageFile.existsSync()) {
    print('Error: Image file not found at "$imagePath"');
    exit(1);
  }

  final apiKey = getApiKey();
  final model = GenerativeModel(
    model: 'gemini-2.5-flash', 
    apiKey: apiKey,
  );

  final query = 'What is wrong with my crop? The leaves are turning yellow.';
  
  print('Image: $imagePath');
  print('Query: "$query"');
  print('Analyzing...');

  try {
    final imageBytes = await imageFile.readAsBytes();
    
    // Construct the Master Prompt (Copied from GeminiService)
     final promptText = '''
Role: You are the "Gram Gyan" Senior Multimodal Agronomist. Your mission is to support rural farmers in India by identifying crop diseases and providing actionable, safe, and culturally relevant farming advice.

Step-by-Step Logic:
1. Visual Diagnosis: Carefully inspect the image. Identify the crop and detect symptoms like necrosis, chlorosis, fungal growth, or pest infestation.
2. Contextual Analysis: Cross-reference the visual symptoms with the user's description: "$query"
3. Validation: If the image is not related to agriculture, or is too blurry to identify, politely ask for a clearer photo.
4. Treatment Plan: Provide a dual solution (Organic and Chemical).
5. Radar Impact: Determine if this issue is contagious.

Response Constraints (Strict JSON):
Return ONLY a JSON object with this structure:
{
"crop": "string",
"diagnosis": "string",
"confidence_score": 0.0 to 1.0,
"solutions": {
"organic": "string",
"chemical": "string"
},
"prevention_tips": ["tip 1", "tip 2"],
"radar_severity": "LOW" | "MEDIUM" | "HIGH",
"summary_for_farmer": "A friendly, empathetic summary in English."
}
''';

    final content = [
      Content.multi([
        TextPart(promptText),
        DataPart('image/jpeg', imageBytes),
      ])
    ];

    final response = await model.generateContent(content);
    print('\n--- Analysis Result ---');
    print(response.text);

  } catch (e) {
    print('Error: $e');
  }
}
