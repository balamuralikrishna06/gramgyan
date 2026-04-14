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
    final topCrop =
        predictions.isNotEmpty ? predictions.first.crop : 'Unknown';

    debugPrint('GroqService Frontend: calling backend API for crop analysis...');
    debugPrint('GroqService Frontend: topCrop=$topCrop N=$nitrogen P=$phosphorus K=$potassium pH=$ph');

    final requestBody = jsonEncode({
      'predicted_top_crop': topCrop,
      'nitrogen': nitrogen,
      'phosphorus': phosphorus,
      'potassium': potassium,
      'ph': ph,
      'rainfall': rainfall,
      'temperature': weather.temperature,
      'humidity': weather.humidity,
      'language_code': languageCode,
    });

    final response = await http
        .post(
          Uri.parse('${AppConstants.backendPrimaryUrl}/api/v1/crop/analyze'),
          headers: {
            'Content-Type': 'application/json; charset=utf-8',
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 90));

    debugPrint('Backend Groq status: ${response.statusCode}');
    if (response.statusCode != 200) {
      final errBody = utf8.decode(response.bodyBytes);
      debugPrint('Backend Groq error body: $errBody');
      throw Exception(
        'Groq AI error via backend (${response.statusCode}): $errBody',
      );
    }

    final responseData = jsonDecode(utf8.decode(response.bodyBytes));
    final analysisJson = responseData['data'] as List<dynamic>? ?? [];

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
}
