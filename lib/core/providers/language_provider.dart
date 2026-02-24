import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

/// Maps short app language code to a Sarvam-compatible BCP-47 code.
/// e.g. 'ta' → 'ta-IN', 'hi' → 'hi-IN', 'en' → 'en-IN'
String toSarvamCode(String? langCode) {
  switch (langCode) {
    case 'ta': return 'ta-IN';
    case 'hi': return 'hi-IN';
    case 'pa': return 'pa-IN';
    case 'te': return 'te-IN';
    case 'bn': return 'bn-IN';
    case 'mr': return 'mr-IN';
    case 'gu': return 'gu-IN';
    case 'kn': return 'kn-IN';
    case 'ml': return 'ml-IN';
    case 'or': return 'or-IN';
    case 'en': return 'en-IN';
    default:   return 'en-IN';
  }
}

/// Provider for the selected language code (e.g. 'ta', 'hi', 'en').
/// Persisted via Hive.
final languageProvider = StateNotifierProvider<LanguageNotifier, String?>((ref) {
  return LanguageNotifier();
});

class LanguageNotifier extends StateNotifier<String?> {
  LanguageNotifier() : super(LocalStorageService.getLanguage());

  Future<void> setLanguage(String code) async {
    await LocalStorageService.setLanguage(code);
    state = code;
  }
}
