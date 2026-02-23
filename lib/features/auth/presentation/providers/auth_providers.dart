import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/services/auth_repository.dart';
import '../../domain/models/auth_state.dart' as app;

/// Singleton auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state notifier — manages the auth state machine.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, app.AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

/// StateNotifier controlling authentication state transitions.
class AuthNotifier extends StateNotifier<app.AuthState> {
  final AuthRepository _repo;
  final Ref _ref;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._repo, this._ref) : super(const app.AuthInitial()) {
    // Listen for Firebase auth changes
    _authSub = _repo.authStateChanges.listen((User? user) {
      if (user != null) {
        _handleSignedIn(user);
      } else {
        state = const app.AuthUnauthenticated();
      }
    });
  }

  /// Handle a successful sign-in event from Firebase.
  Future<void> _handleSignedIn(User user) async {
    try {
      final backendData = await _repo.verifyWithBackend();
      final isProfileComplete = backendData['profile_complete'] as bool? ?? false;
      final userData = backendData['user_data'] as Map<String, dynamic>? ?? {};

      // Prefer name from Supabase DB over Firebase (phone users have no Firebase displayName)
      final dbName = userData['name'] as String?;
      final resolvedName = (dbName != null && dbName.isNotEmpty) ? dbName : user.displayName;

      // Supabase internal UUID
      final supabaseUserId = backendData['user_id'] as String?;

      if (!isProfileComplete) {
        state = app.AuthProfileIncomplete(
          userId: supabaseUserId ?? user.uid,
          email: user.email ?? '',
          phoneNumber: user.phoneNumber,
          displayName: resolvedName,
          avatarUrl: user.photoURL,
        );
      } else {
        // ── Sync language from Supabase → languageProvider ──
        final dbLanguage = userData['language'] as String?;
        if (dbLanguage != null) _syncLanguage(dbLanguage);

        state = app.AuthAuthenticated(
          userId: supabaseUserId ?? user.uid,
          email: user.email ?? '',
          displayName: resolvedName,
          avatarUrl: user.photoURL,
          city: userData['city'] as String?,
          role: userData['role'] as String? ?? 'farmer',
        );
      }
    } catch (e) {
      // Backend unreachable (e.g. Render sleeping, no network).
      // Fallback: treat as profile-incomplete so user can still log in / complete profile.
      // This prevents infinite loading on the splash screen.
      state = app.AuthProfileIncomplete(
        userId: user.uid,
        email: user.email ?? '',
        phoneNumber: user.phoneNumber,
        displayName: user.displayName,
        avatarUrl: user.photoURL,
      );
    }
  }

  /// Maps the DB language English name (e.g. 'Tamil') → short code ('ta')
  /// and persists it in languageProvider + Hive.
  void _syncLanguage(String dbLanguageName) {
    // Find the matching code from supportedLanguages
    final match = AppConstants.supportedLanguages.firstWhere(
      (l) => l['english']!.toLowerCase() == dbLanguageName.toLowerCase() ||
             l['name'] == dbLanguageName ||
             l['code'] == dbLanguageName,
      orElse: () => {},
    );
    final code = match['code'];
    if (code != null && code.isNotEmpty) {
      _ref.read(languageProvider.notifier).setLanguage(code);
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Check current session on app launch.
  Future<void> checkSession() async {
    final user = _repo.currentUser;
    if (user != null) {
       await _handleSignedIn(user);
    } else {
      state = const app.AuthUnauthenticated();
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    state = const app.AuthLoading('Connecting to Google…');
    try {
      await _repo.signInWithGoogle();
      // Auth state will update via listener
    } catch (e) {
      state = app.AuthError('Login failed: ${e.toString()}');
    }
  }

  /// Verify phone number.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    await _repo.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Sign in with OTP.
  Future<void> signInWithOtp(String verificationId, String smsCode) async {
    state = const app.AuthLoading('Verifying OTP...');
    try {
      await _repo.signInWithOtp(
          verificationId: verificationId, smsCode: smsCode);
    } catch (e) {
      state = app.AuthError('OTP Verification failed: ${e.toString()}');
    }
  }

  Future<void> completeProfile({
    required String name,
    required String city,
    required String selectedState,
    required String language,
    String role = 'farmer',
    String? phone,
    String? email,
  }) async {
    state = const app.AuthLoading('Saving profile…');
    try {
      await _repo.updateProfile(
        city: city,
        state: selectedState,
        language: language,
        name: name,
        role: role,
        phone: phone,
        email: email,
      );

      // Immediately sync language to languageProvider so STT uses the right code
      _syncLanguage(language);

      // Force refresh of state
      final user = _repo.currentUser;
      if (user != null) {
         await _handleSignedIn(user);
      }
    } catch (e) {
      state = app.AuthError('Failed to save profile: ${e.toString()}');
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    state = const app.AuthLoading('Signing out…');
    try {
      await _repo.signOut();
    } catch (_) {}
    state = const app.AuthUnauthenticated();
  }
  
  void resetError() {
    state = const app.AuthUnauthenticated();
  }
}
