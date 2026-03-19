import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import 'failover_http_client.dart';

/// A single crop prediction from the ML model.
class CropPrediction {
  final String crop;
  final double probability; // 0.0 – 1.0

  const CropPrediction({required this.crop, required this.probability});

  String get confidencePercent => '${(probability * 100).toStringAsFixed(1)}%';

  @override
  String toString() => 'CropPrediction($crop, $confidencePercent)';
}

class CropPredictionService {
  static final _client = FailoverHttpClient(
    primaryUrl: AppConstants.cropPredictionPrimaryUrl,
    fallbackUrl: AppConstants.cropPredictionFallbackUrl,
    timeout: const Duration(seconds: 90),
  );

  /// Calls the ML API with automatic failover between Render and Railway.
  ///
  /// Response format:
  ///   { "predicted_crop": "muskmelon",
  ///     "predictions": [{"crop":"muskmelon","probability":0.42,"rank":1}, ...] }
  Future<List<CropPrediction>> predict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double temperature,
    required double humidity,
    required double rainfall,
  }) async {
    final body = {
      'N': nitrogen,
      'P': phosphorus,
      'K': potassium,
      'ph': ph,
      'temperature': temperature,
      'humidity': humidity,
      'rainfall': rainfall,
    };

    debugPrint('CropPredictionService POST /predict (with failover)');

    final response = await _client.post('/predict', body: body);

    if (response.statusCode != 200) {
      throw Exception(
        'Crop prediction API error (${response.statusCode}). '
        'Both Render and Railway may be unavailable — please retry.',
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes));
    debugPrint('Crop API response: $data');

    if (data is Map) {
      // ── NEW format: { "predictions": [...Top-5 with probs...] } ──
      if (data.containsKey('predictions')) {
        final list = data['predictions'] as List;
        if (list.isNotEmpty) {
          final results = list.map((item) {
            final name = (item['crop'] ?? item['label'] ?? 'Unknown').toString();
            final prob = (item['probability'] ?? item['confidence'] ?? 0.5) as num;
            return CropPrediction(
              crop: _cap(name),
              probability: prob.toDouble().clamp(0.0, 1.0),
            );
          }).toList();
          results.sort((a, b) => b.probability.compareTo(a.probability));
          debugPrint('Using TOP-5 from predict_proba: ${results.map((r) => "${r.crop}=${r.confidencePercent}").join(", ")}');
          return results.take(5).toList();
        }
      }

      // ── OLD / fallback: { "predicted_crop": "muskmelon" } ──
      final cropName =
          (data['predicted_crop'] ?? data['crop'] ?? '').toString().trim();
      if (cropName.isNotEmpty) {
        debugPrint('Using fallback single-crop response: $cropName');
        return [CropPrediction(crop: _cap(cropName), probability: 1.0)];
      }

      // ── top_crops array ──
      if (data.containsKey('top_crops')) {
        return _fromList(data['top_crops'] as List);
      }
    }

    if (data is List) return _fromList(data);

    throw Exception('Unexpected API response format: $data');
  }

  List<CropPrediction> _fromList(List<dynamic> list) {
    final preds = list.map((item) {
      final c = (item['crop'] ?? item['label'] ?? 'Unknown').toString();
      final p = (item['probability'] ?? item['confidence'] ?? 0.5) as num;
      return CropPrediction(crop: _cap(c), probability: p.toDouble());
    }).toList();
    preds.sort((a, b) => b.probability.compareTo(a.probability));
    return preds.take(5).toList();
  }

  String _cap(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}
