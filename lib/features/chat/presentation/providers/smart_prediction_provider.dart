import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/crop_prediction_service.dart';
import '../../../../core/services/groq_service.dart';
import '../../../../core/services/weather_service.dart';

// ── Step enum ──────────────────────────────────────────────────────────────

enum PredictionStep { idle, fetchingWeather, analyzingSoil, generatingReport, done, error }

extension PredictionStepLabel on PredictionStep {
  String get label {
    switch (this) {
      case PredictionStep.idle:             return '';
      case PredictionStep.fetchingWeather:  return '📡 Fetching weather via GPS...';
      case PredictionStep.analyzingSoil:    return '🔬 Analyzing soil with ML model...';
      case PredictionStep.generatingReport: return '🤖 Generating AI crop report...';
      case PredictionStep.done:             return '✅ Analysis complete!';
      case PredictionStep.error:            return '❌ An error occurred.';
    }
  }
}

// ── State ──────────────────────────────────────────────────────────────────

class SmartPredictionState {
  final PredictionStep step;
  final List<CropAnalysis> results;
  final String? errorMessage;

  const SmartPredictionState({
    this.step = PredictionStep.idle,
    this.results = const [],
    this.errorMessage,
  });

  SmartPredictionState copyWith({
    PredictionStep? step,
    List<CropAnalysis>? results,
    String? errorMessage,
  }) => SmartPredictionState(
    step: step ?? this.step,
    results: results ?? this.results,
    errorMessage: errorMessage ?? this.errorMessage,
  );
}

// ── Notifier ───────────────────────────────────────────────────────────────

class SmartPredictionNotifier extends StateNotifier<SmartPredictionState> {
  SmartPredictionNotifier() : super(const SmartPredictionState());

  final _cropService = CropPredictionService();
  final _groqService = GroqService();

  /// Runs the full prediction pipeline.
  ///
  /// All 7 parameters come directly from the form:
  ///   - Soil: nitrogen, phosphorus, potassium, ph, rainfall
  ///   - Weather: temperature, humidity (GPS-prefilled but user-editable)
  ///
  /// This guarantees the values match the ML model's training distribution
  /// regardless of current time-of-day GPS conditions.
  Future<void> runPrediction({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double rainfall,
    required double temperature,
    required double humidity,
    String languageCode = 'en',
  }) async {
    try {
      // Step 1: Show "analyzing" state (weather already resolved by form)
      state = state.copyWith(step: PredictionStep.analyzingSoil, results: []);

      final predictions = await _cropService.predict(
        nitrogen:    nitrogen,
        phosphorus:  phosphorus,
        potassium:   potassium,
        ph:          ph,
        temperature: temperature,
        humidity:    humidity,
        rainfall:    rainfall,
      );

      // Step 2: Groq AI report
      state = state.copyWith(step: PredictionStep.generatingReport);

      // Build a minimal WeatherData from form values for GroqService
      final weatherData = WeatherData(
        temperature: temperature,
        humidity:    humidity,
        latitude:    0,
        longitude:   0,
      );

      final analysis = await _groqService.analyzecrops(
        predictions: predictions,
        nitrogen:    nitrogen,
        phosphorus:  phosphorus,
        potassium:   potassium,
        ph:          ph,
        rainfall:    rainfall,
        weather:     weatherData,
        languageCode: languageCode,
      );

      state = state.copyWith(step: PredictionStep.done, results: analysis);
    } catch (e) {
      state = state.copyWith(
        step: PredictionStep.error,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void reset() => state = const SmartPredictionState();
}

// ── Provider ───────────────────────────────────────────────────────────────

final smartPredictionProvider =
    StateNotifierProvider.autoDispose<SmartPredictionNotifier, SmartPredictionState>(
  (ref) => SmartPredictionNotifier(),
);
