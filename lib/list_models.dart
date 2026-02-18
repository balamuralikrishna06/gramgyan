import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() async {
  const apiKey = 'AIzaSyDE4R7kKKi7R0vSvVPtltNJBMLTcqGEiGI';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  try {
    print('Fetching models from: $url');
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final models = json['models'] as List;
      final file = File('models_full.txt');
      final sink = file.openWrite();
      
      sink.writeln('Found ${models.length} models:');
      for (var m in models) {
        final name = m['name'];
        final methods = m['supportedGenerationMethods'];
        sink.writeln('name: $name, methods: $methods');
      }
      await sink.close();
      print('Written to models_full.txt');
    } else {
      print('Error: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Exception: $e');
  }
}
