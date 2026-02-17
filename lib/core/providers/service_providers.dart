import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_recorder_service.dart';
import '../services/gemini_service.dart';
import '../services/text_to_speech_service.dart';
import '../services/sarvam_api_service.dart';

final audioRecorderServiceProvider = Provider<AudioRecorderService>((ref) {
  return AudioRecorderService();
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  return GeminiService();
});

final textToSpeechServiceProvider = Provider<TextToSpeechService>((ref) {
  return TextToSpeechService();
});

final sarvamApiServiceProvider = Provider<SarvamApiService>((ref) {
  return SarvamApiService();
});
