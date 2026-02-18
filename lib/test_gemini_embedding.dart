import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyDE4R7kKKi7R0vSvVPtltNJBMLTcqGEiGI';
  
  if (apiKey.isEmpty) {
    print('No API key found.');
    exit(1);
  }

  print('Generating embedding with API Key: $apiKey');

  final model = GenerativeModel(
    model: 'text-embedding-004',
    apiKey: apiKey,
  );

  final content = Content.text('This is a test sentence for embedding generation.');

  try {
    stderr.writeln('Sending request...');
    final result = await model.embedContent(content);
    stderr.writeln('Success!');
    stderr.writeln('Embedding length: ${result.embedding.values.length}');
  } catch (e) {
    stderr.writeln('Error generating embedding:');
    stderr.writeln(e.toString());
  }
}
