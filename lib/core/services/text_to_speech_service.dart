import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';

import '../constants/app_constants.dart';

class TextToSpeechService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  
  Stream<PlayerState> get onPlayerStateChanged => _audioPlayer.onPlayerStateChanged;
  PlayerState get playerState => _audioPlayer.state;

  Future<void> init() async {
    // No-op for network TTS
  }

  Future<void> speak(String text, {String language = 'ta-IN'}) async {
    if (text.trim().isEmpty) return;

    // Stop any current playback without awaiting (non-blocking)
    unawaited(_audioPlayer.stop());

    try {
      _isPlaying = true;

      final uri = Uri.parse('${AppConstants.backendPrimaryUrl}/api/v1/speech/stream').replace(
        queryParameters: {
          'text': text,
          'language_code': language,
        },
      );

      // play() returns as soon as playback starts — does not block until audio ends
      await _audioPlayer.play(UrlSource(uri.toString()));

    } catch (e) {
      _isPlaying = false;
      debugPrint('TTS Error: $e');
    }
  }

  Future<void> pause() async {
    _isPlaying = false;
    await _audioPlayer.pause();
  }

  Future<void> resume() async {
    _isPlaying = true;
    await _audioPlayer.resume();
  }

  Future<void> stop() async {
    _isPlaying = false;
    await _audioPlayer.stop();
  }
}
