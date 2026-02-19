import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  final apiKey = 'AIzaSyAiNBUCfYdLfIfJalDH0Ur1svfw1IgOBpY';
  final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');

  print('Listing models from: $url');
  
  try {
    final response = await http.get(url);
    print('Response Code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Available Models:');
      for (var model in data['models']) {
        if (model['supportedGenerationMethods'].contains('generateContent')) {
           print('- ${model['name']}');
        }
      }
    } else {
      print('Error Body: ${response.body}');
    }
  } catch (e) {
    print('Exception: $e');
  }
}
