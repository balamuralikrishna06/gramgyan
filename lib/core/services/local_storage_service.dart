import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';

/// Hive-based local storage service for offline persistence.
class LocalStorageService {
  static late Box _settingsBox;

  /// Initialize Hive and open required boxes.
  static Future<void> init() async {
    await Hive.initFlutter();
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // ── Language ──
  static String? getLanguage() {
    return _settingsBox.get(AppConstants.languageKey) as String?;
  }

  static Future<void> setLanguage(String languageCode) async {
    await _settingsBox.put(AppConstants.languageKey, languageCode);
  }

  // ── Dark Mode ──
  static bool getDarkMode() {
    return _settingsBox.get(AppConstants.darkModeKey, defaultValue: false) as bool;
  }

  static Future<void> setDarkMode(bool value) async {
    await _settingsBox.put(AppConstants.darkModeKey, value);
  }

  // ── Onboarding ──
  static bool isOnboarded() {
    return _settingsBox.get(AppConstants.onboardedKey, defaultValue: false) as bool;
  }

  static Future<void> setOnboarded(bool value) async {
    await _settingsBox.put(AppConstants.onboardedKey, value);
  }

  // ── Profile Completed (auth flow) ──
  static bool isProfileCompleted() {
    return _settingsBox.get(AppConstants.profileCompletedKey,
        defaultValue: false) as bool;
  }

  static Future<void> setProfileCompleted(bool value) async {
    await _settingsBox.put(AppConstants.profileCompletedKey, value);
  }

  // ── Generic KV ──
  static Future<void> put(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  static dynamic get(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }
}
