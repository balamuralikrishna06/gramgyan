import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sarvam_api_service.dart';

class SpeechService {
  final SarvamApiService _sarvamService;

  SpeechService(this._sarvamService);

  Future<SarvamProcessResponse> processAudio(String filePath) async {
    return await _sarvamService.processAudio(filePath);
  }
}
