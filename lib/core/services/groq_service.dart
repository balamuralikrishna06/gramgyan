import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import 'crop_prediction_service.dart';
import 'weather_service.dart';

/// The final enriched analysis for a single crop, produced by Groq.
class CropAnalysis {
  final String crop;
  final double probability;
  final String riskLevel;
  final String riskCause;
  final String whySuitable;
  final List<String> improvementSteps;
  final List<String> plantingAdvice;

  const CropAnalysis({
    required this.crop,
    required this.probability,
    required this.riskLevel,
    required this.riskCause,
    required this.whySuitable,
    required this.improvementSteps,
    required this.plantingAdvice,
  });

  int get confidencePct => (probability * 100).round();
}

class GroqService {
  static const String _groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  // llama-3.3-70b-versatile is much better at multilingual tasks and avoids repetition loops
  static const String _model = 'llama-3.3-70b-versatile';

  Future<List<CropAnalysis>> analyzecrops({
    required List<CropPrediction> predictions,
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double rainfall,
    required WeatherData weather,
    String languageCode = 'en',
  }) async {
    final apiKey = AppConstants.groqApiKey;
    if (apiKey.isEmpty || apiKey == 'YOUR_GROQ_KEY_HERE') {
      throw Exception(
        'Groq API key is not configured. Add GROQ_API_KEY to your .env file.',
      );
    }

    final topCrop =
        predictions.isNotEmpty ? predictions.first.crop : 'Unknown';
    final tempStr = weather.temperature.toStringAsFixed(1);
    final humStr = weather.humidity.toStringAsFixed(1);

    // Build the prompt using string concatenation to avoid any
    // unicode/interpolation issues inside triple-quoted strings.
    final mlHint = predictions.isNotEmpty
        ? 'An ML model predicted: $topCrop for these values.'
        : '';

    final prompt =
        'You are an expert agricultural AI for Indian farmers. '
        'You have deep knowledge of the Kaggle Crop Recommendation dataset '
        'which contains these key crop profiles (N/P/K in kg/ha, temp in C, humidity %, rainfall in mm):\n'
        '- Rice:       N=60-100, P=35-60, K=35-45, temp=20-27, humidity=80-85, rainfall=183-298\n'
        '- Maize:      N=60-100, P=35-60, K=15-25, temp=18-27, humidity=55-74, rainfall=60-110\n'
        '- Chickpea:   N=20-60,  P=55-80, K=75-85, temp=17-21, humidity=14-20, rainfall=65-95\n'
        '- KidneyBeans:N=0-40,   P=55-80, K=15-25, temp=15-24, humidity=18-25, rainfall=60-150\n'
        '- PigeonPeas: N=0-40,   P=55-80, K=15-25, temp=18-37, humidity=30-68, rainfall=90-199\n'
        '- MothBeans:  N=0-40,   P=35-60, K=15-25, temp=24-32, humidity=40-65, rainfall=30-75\n'
        '- MungBean:   N=0-40,   P=35-60, K=15-25, temp=27-30, humidity=80-90, rainfall=36-60\n'
        '- BlackGram:  N=20-60,  P=55-80, K=15-25, temp=25-35, humidity=60-70, rainfall=60-75\n'
        '- Lentil:     N=18-28,  P=55-80, K=15-25, temp=18-24, humidity=60-70, rainfall=36-60\n'
        '- Pomegranate:N=0-20,   P=55-80, K=35-45, temp=18-24, humidity=85-95, rainfall=100-130\n'
        '- Banana:     N=80-120, P=55-80, K=45-55, temp=25-30, humidity=78-92, rainfall=100-160\n'
        '- Mango:      N=0-20,   P=15-25, K=25-35, temp=27-37, humidity=45-55, rainfall=90-130\n'
        '- Grapes:     N=0-20,   P=55-80, K=35-45, temp=8-42,  humidity=80-90, rainfall=65-80\n'
        '- Watermelon: N=80-120, P=55-80, K=45-55, temp=24-27, humidity=83-97, rainfall=50-60\n'
        '- Muskmelon:  N=80-100, P=55-80, K=45-55, temp=28-32, humidity=90-95, rainfall=20-35\n'
        '- Apple:      N=0-20,   P=55-80, K=35-45, temp=0-22,  humidity=90-95, rainfall=100-125\n'
        '- Orange:     N=0-20,   P=15-25, K=5-15,  temp=10-35, humidity=90-95, rainfall=100-120\n'
        '- Papaya:     N=40-60,  P=55-80, K=35-45, temp=33-38, humidity=92-97, rainfall=145-175\n'
        '- Coconut:    N=0-20,   P=15-25, K=25-35, temp=25-30, humidity=90-95, rainfall=100-150\n'
        '- Cotton:     N=100-140,P=35-60, K=15-25, temp=23-37, humidity=79-92, rainfall=60-100\n'
        '- Jute:       N=60-80,  P=35-60, K=35-45, temp=23-27, humidity=78-92, rainfall=150-200\n'
        '- Coffee:     N=100-140,P=15-25, K=25-35, temp=22-30, humidity=55-65, rainfall=158-200\n\n'
        'A farmer entered these values:\n'
        '- N: $nitrogen  P: $phosphorus  K: $potassium  pH: $ph\n'
        '- Temperature: $tempStr C  Humidity: $humStr%  Rainfall: ${rainfall.toStringAsFixed(0)} mm\n'
        '$mlHint\n\n'
        'Match the farmer values to the crop profiles above. '
        'Recommend TOP 5 crops that best match ALL parameters simultaneously. '
        'Give priority to crops with the closest N/P/K/temp/humidity/rainfall match. '
        'Ignore crops that clearly do not match (e.g. Apple if temp>30). '
        'Indian context: prefer crops actually grown in India.\n\n'
        'Return ONLY a valid JSON array of exactly 5 objects with these fields:\n'
        '- "crop": string (ALWAYS in English, e.g. "Maize")\n'
        '- "confidence_score": 0.0-1.0 (match quality, descending order)\n'
        '- "risk_level": "Low"/"Medium"/"High" (>= 0.70 = Low, 0.40-0.69 = Medium, < 0.40 = High)\n'
        '- "risk_cause": string (one sentence: which parameter is furthest from ideal)\n'
        '- "why_suitable": string (two sentences: which parameters match well)\n'
        '- "improvement_steps": array of 3 strings\n'
        '- "planting_advice": array of 4 strings\n\n'
        'IMPORTANT: Write ALL text fields (risk_cause, why_suitable, improvement_steps, planting_advice) '
        'in ${_languageName(languageCode)}. Keep the "crop" field in English.\n'
        'No markdown, no extra text. Only the JSON array.';

    debugPrint('GroqService: calling model $_model...');
    debugPrint('GroqService: topCrop=$topCrop N=$nitrogen P=$phosphorus K=$potassium pH=$ph');

    final requestBody = jsonEncode({
      'model': _model,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0.5,
      'frequency_penalty': 0.3,
      'presence_penalty': 0.3,
      'max_tokens': 4096,
    });

    final response = await http
        .post(
          Uri.parse(_groqUrl),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
            'Authorization': 'Bearer $apiKey',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 60));

    debugPrint('Groq status: ${response.statusCode}');
    if (response.statusCode != 200) {
      final errBody = utf8.decode(response.bodyBytes);
      debugPrint('Groq error body: $errBody');
      throw Exception(
        'Groq AI error (${response.statusCode}): $errBody',
      );
    }

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    final content =
        responseData['choices'][0]['message']['content'] as String;

    debugPrint('Groq response length: ${content.length} chars');

    List<dynamic> analysisJson;
    try {
      // Strip any markdown code fences Groq might add
      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      analysisJson = jsonDecode(cleaned) as List<dynamic>;
    } catch (_) {
      // Try to extract the JSON array by finding [ ... ]
      final start = content.indexOf('[');
      final end = content.lastIndexOf(']');
      if (start != -1 && end != -1 && end > start) {
        analysisJson =
            jsonDecode(content.substring(start, end + 1)) as List<dynamic>;
      } else {
        throw Exception(
          'Could not parse Groq response as JSON array. Response: $content',
        );
      }
    }

    return analysisJson.map((entry) {
      final item = entry as Map<String, dynamic>;
      final prob = ((item['confidence_score'] as num?) ?? 0.5)
          .toDouble()
          .clamp(0.0, 1.0);

      return CropAnalysis(
        crop: item['crop']?.toString() ?? 'Unknown',
        probability: prob,
        riskLevel: item['risk_level']?.toString() ?? 'Medium',
        riskCause:
            item['risk_cause']?.toString() ?? 'No specific cause identified.',
        whySuitable: item['why_suitable']?.toString() ?? '',
        improvementSteps: _toStringList(item['improvement_steps']),
        plantingAdvice: _toStringList(item['planting_advice']),
      );
    }).toList();
  }

  List<String> _toStringList(dynamic val) {
    if (val is List) return val.map((e) => e.toString()).toList();
    return [];
  }

  /// Maps language code (e.g. 'ta') to full name for the Groq prompt.
  String _languageName(String code) {
    switch (code) {
      case 'ta': return 'Tamil';
      case 'hi': return 'Hindi';
      case 'te': return 'Telugu';
      case 'kn': return 'Kannada';
      case 'ml': return 'Malayalam';
      case 'bn': return 'Bengali';
      case 'mr': return 'Marathi';
      case 'gu': return 'Gujarati';
      case 'pa': return 'Punjabi';
      case 'or': return 'Odia';
      default:   return 'English';
    }
  }
}
