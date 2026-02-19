import 'package:flutter_test/flutter_test.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() {
  test('Test Gemini Embeddings', () async {
    final apiKey = 'AIzaSyAiNBUCfYdLfIfJalDH0Ur1svfw1IgOBpY';
    final outputFile = File('embedding_results.txt');
    await outputFile.writeAsString('Starting Test...\n');

    // Test Text Generation to verify Key is valid at all
    await outputFile.writeAsString('\n--- Testing Generative Model (gemini-1.5-flash) ---\n', mode: FileMode.append);
    try {
      final genModel = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      final response = await genModel.generateContent([Content.text('Hello')]);
      await outputFile.writeAsString('✅ SUCCESS (Generate): ${response.text}\n', mode: FileMode.append);
    } catch (e) {
      await outputFile.writeAsString('❌ FAILED (Generate): $e\n', mode: FileMode.append);
    }

    final modelNames = [
      'models/gemini-embedding-001',
      'gemini-embedding-001',
      'models/embedding-001'
    ];

    for (final modelName in modelNames) {
      await outputFile.writeAsString('\n--- Testing Model: $modelName ---\n', mode: FileMode.append);
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        final content = Content.text('The quick brown fox jumps over the lazy dog.');
        
        // Test Document Embedding
        await outputFile.writeAsString('Attempting retrievalDocument task...\n', mode: FileMode.append);
        final resultDoc = await model.embedContent(content, taskType: TaskType.retrievalDocument);
        await outputFile.writeAsString('✅ SUCCESS (Document): Vector length: ${resultDoc.embedding.values.length}\n', mode: FileMode.append);

        // Test Query Embedding
        await outputFile.writeAsString('Attempting retrievalQuery task...\n', mode: FileMode.append);
        final resultQuery = await model.embedContent(content, taskType: TaskType.retrievalQuery);
        await outputFile.writeAsString('✅ SUCCESS (Query): Vector length: ${resultQuery.embedding.values.length}\n', mode: FileMode.append);
        
      } catch (e) {
        await outputFile.writeAsString('❌ FAILED: $e\n', mode: FileMode.append);
      }
    }
  });
}
