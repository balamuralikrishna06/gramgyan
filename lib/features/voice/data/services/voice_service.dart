import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

/// Service to handle Speech-to-Text operations using the device's native capabilities.
class VoiceService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// Initializes the speech recognition service.
  /// Returns true if successful, false otherwise.
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speech.initialize(
        onError: (val) => debugPrint('VoiceService Error: $val'),
        onStatus: (val) => debugPrint('VoiceService Status: $val'),
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('VoiceService Initialization Failed: $e');
      return false;
    }
  }

  /// Starts listening to the microphone and returns the recognized text via callback.
  /// 
  /// [onResult] Callback function that receives the recognized text.
  /// [locale] Optional locale ID (e.g., 'en_IN', 'ta_IN', 'hi_IN').
  Future<void> startListening({
    required Function(String) onResult,
    String? locale = 'en_IN',
  }) async {
    if (!_isInitialized) {
      bool success = await initialize();
      if (!success) return;
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult || result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        localeId: locale,
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      );
    } catch (e) {
      debugPrint('VoiceService Start Listening Failed: $e');
    }
  }

  /// Stops listening to the microphone.
  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  /// Checks if the service is currently listening.
  bool get isListening => _speech.isListening;

  /// Returns a list of available locales (E.g. for language selection UI).
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) await initialize();
    return await _speech.locales();
  }
}
