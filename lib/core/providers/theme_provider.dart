import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/local_storage_service.dart';

/// Provider for dark mode toggle, persisted via Hive.
final darkModeProvider = StateNotifierProvider<DarkModeNotifier, bool>((ref) {
  return DarkModeNotifier();
});

class DarkModeNotifier extends StateNotifier<bool> {
  DarkModeNotifier() : super(LocalStorageService.getDarkMode());

  Future<void> toggle() async {
    state = !state;
    await LocalStorageService.setDarkMode(state);
  }
}
