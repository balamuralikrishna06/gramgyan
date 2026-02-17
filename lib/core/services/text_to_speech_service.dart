import 'package:flutter_tts/flutter_tts.dart';

class TextToSpeechService {
  final FlutterTts _flutterTts = FlutterTts();

  Future<void> init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  Future<void> speak(String text, {String language = 'en-US'}) async {
    await _flutterTts.setLanguage(language);
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
