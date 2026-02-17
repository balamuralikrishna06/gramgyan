import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

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
