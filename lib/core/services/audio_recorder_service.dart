import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _audioRecorder = AudioRecorder();

  Future<bool> hasPermission() async {
    final status = await Permission.microphone.request();
    return status == PermissionStatus.granted;
  }

  Future<void> startRecording() async {
    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted');
    }

    final directory = await getApplicationDocumentsDirectory();
    final filepath = '${directory.path}/temp_recording_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Start recording to file
    await _audioRecorder.start(const RecordConfig(), path: filepath);
  }

  Future<String?> stopRecording() async {
    return await _audioRecorder.stop();
  }

  Future<void> cancelRecording() async {
    await _audioRecorder.cancel();
  }

  Future<void> dispose() async {
    _audioRecorder.dispose();
  }
}
