import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

/// Service to handle Audio Recording for Sarvam Backend.
class VoiceService {
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  /// Initializes the recorder (checks permissions).
  Future<bool> initialize() async {
    try {
      return await _audioRecorder.hasPermission();
    } catch (e) {
      debugPrint('VoiceService Initialization Failed: $e');
      return false;
    }
  }

  /// Starts recording to a temporary file in WAV format (optimal for Sarvam STT).
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        // Use .wav extension — Sarvam STT returns native script reliably with WAV (16kHz mono PCM)
        final filePath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
        
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,    // PCM WAV — understood by Sarvam STT
            sampleRate: 16000,            // 16 kHz — Sarvam STT optimal
            numChannels: 1,               // Mono
            bitRate: 256000,
          ),
          path: filePath,
        );
        _isRecording = true;
        debugPrint('Started recording to $filePath');
      }
    } catch (e) {
      debugPrint('VoiceService Start Recording Failed: $e');
    }
  }

  /// Stops recording and returns the file path.
  Future<String?> stopRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        _isRecording = false;
        debugPrint('Stopped recording, file saved at $path');
        return path;
      }
      return null;
    } catch (e) {
      debugPrint('VoiceService Stop Recording Failed: $e');
      return null;
    }
  }

  /// Checks if the service is currently recording.
  bool get isRecording => _isRecording;
  
  void dispose() {
    _audioRecorder.dispose();
  }
}
