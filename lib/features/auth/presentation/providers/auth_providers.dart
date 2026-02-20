import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/auth_repository.dart';
import '../../domain/models/auth_state.dart' as app;

/// Singleton auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth state notifier — manages the auth state machine.
final authStateProvider =
    StateNotifierProvider<AuthNotifier, app.AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

/// StateNotifier controlling authentication state transitions.
class AuthNotifier extends StateNotifier<app.AuthState> {
  final AuthRepository _repo;
  StreamSubscription<User?>? _authSub;

  AuthNotifier(this._repo) : super(const app.AuthInitial()) {
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
    // state = const app.AuthLoading('Verifying profile...'); 
    // Commented out loading state to avoid flickering if already authenticated
    
    try {
      final backendData = await _repo.verifyWithBackend();
      final isProfileComplete = backendData['profile_complete'] as bool? ?? false;
      final userData = backendData['user_data'] as Map<String, dynamic>? ?? {};

      if (!isProfileComplete) {
        state = app.AuthProfileIncomplete(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          avatarUrl: user.photoURL,
        );
      } else {
        state = app.AuthAuthenticated(
          userId: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          avatarUrl: user.photoURL,
          city: userData['city'] as String?,
          role: userData['role'] as String? ?? 'farmer',
        );
      }
    } catch (e) {
      state = app.AuthError(e.toString());
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

  /// Complete profile and transition to authenticated.
  Future<void> completeProfile({
    required String name,
    required String city,
    required String selectedState,
    required String language,
    String role = 'farmer',
  }) async {
    state = const app.AuthLoading('Saving profile…');
    try {
      await _repo.updateProfile(
        city: city,
        state: selectedState,
        language: language,
        name: name,
        role: role,
      );
      
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
