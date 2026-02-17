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

  /// Starts recording to a temporary file.
  Future<void> startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/temp_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // Start recording to file
        await _audioRecorder.start(const RecordConfig(), path: filePath);
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
