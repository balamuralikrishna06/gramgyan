import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyDE4R7kKKi7R0vSvVPtltNJBMLTcqGEiGI';
  print('Testing Gemini Embedding with Key: ${apiKey.substring(0, 5)}...');

  final modelNames = [
    'text-embedding-004',
    'models/text-embedding-004',
    'embedding-001',
    'models/embedding-001'
  ];

  for (final modelName in modelNames) {
    print('\n--- Testing Model: $modelName ---');
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final content = Content.text('The quick brown fox jumps over the lazy dog.');
      
      // Test Document Embedding
      print('Attempting retrievalDocument task...');
      final resultDoc = await model.embedContent(content, taskType: TaskType.retrievalDocument);
      print('✅ SUCCESS (Document): Vector length: ${resultDoc.embedding.values.length}');

      // Test Query Embedding
      print('Attempting retrievalQuery task...');
      final resultQuery = await model.embedContent(content, taskType: TaskType.retrievalQuery);
      print('✅ SUCCESS (Query): Vector length: ${resultQuery.embedding.values.length}');
      
    } catch (e) {
      print('❌ FAILED: $e');
    }
  }
}
