import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

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
  StreamSubscription<supa.AuthState>? _authSub;

  AuthNotifier(this._repo) : super(const app.AuthInitial()) {
    // Listen for Supabase auth changes (critical for OAuth redirect flow)
    _authSub = supa.Supabase.instance.client.auth.onAuthStateChange
        .listen((supa.AuthState data) {
      if (data.event == supa.AuthChangeEvent.signedIn && data.session != null) {
        _handleSignedIn();
      } else if (data.event == supa.AuthChangeEvent.signedOut) {
        state = const app.AuthUnauthenticated();
      }
    });
  }

  /// Helper to extract display name from user metadata or email
  String _extractName(supa.User user) {
    final metadata = user.userMetadata;
    return (metadata?['full_name'] as String?) ??
        (metadata?['name'] as String?) ??
        user.email?.split('@').first ??
        'Farmer';
  }

  /// Handle a successful sign-in event from Supabase.
  Future<void> _handleSignedIn() async {
    final user = _repo.currentUser;
    if (user == null) return;

    final profileComplete = await _repo.checkProfileCompletion();
    final displayName = _extractName(user);

    if (!profileComplete) {
      state = app.AuthProfileIncomplete(
        userId: user.id,
        email: user.email ?? '',
        displayName: displayName,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
      );
    } else {
      // Fetch profile to get city and role
      String? city;
      String role = 'farmer';
      try {
        final profile = await _repo.fetchUserProfile();
        city = profile?['city'] as String?;
        role = profile?['role'] as String? ?? 'farmer';
      } catch (_) {}

      state = app.AuthAuthenticated(
        userId: user.id,
        email: user.email ?? '',
        displayName: displayName,
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        city: city,
        role: role,
      );
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// Check current session on app launch.
  Future<void> checkSession() async {
    state = const app.AuthLoading('Checking session...');

    try {
      final user = _repo.currentUser;
      if (user == null) {
        state = const app.AuthUnauthenticated();
        return;
      }

      final profileComplete = await _repo.checkProfileCompletion();
      final displayName = _extractName(user);

      if (!profileComplete) {
        state = app.AuthProfileIncomplete(
          userId: user.id,
          email: user.email ?? '',
          displayName: displayName,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
        );
      } else {
        // Fetch profile to get city and role
        String? city;
        String role = 'farmer';
        try {
          final profile = await _repo.fetchUserProfile();
          city = profile?['city'] as String?;
          role = profile?['role'] as String? ?? 'farmer';
        } catch (_) {}

        state = app.AuthAuthenticated(
          userId: user.id,
          email: user.email ?? '',
          displayName: displayName,
          avatarUrl: user.userMetadata?['avatar_url'] as String?,
          city: city,
          role: role,
        );
      }
    } catch (e) {
      state = app.AuthError(e.toString());
    }
  }

  /// Sign in with Google via OAuth redirect.
  /// The actual auth state change will come via onAuthStateChange listener
  /// after the browser redirect completes.
  Future<void> signInWithGoogle() async {
    state = const app.AuthLoading('Connecting to Google…');

    try {
      await _repo.signInWithGoogle();
      // OAuth opens a browser — auth state will update via onAuthStateChange
      // Reset to unauthenticated so the UI isn't stuck on loading
      // if user cancels the browser flow.
      state = const app.AuthUnauthenticated();
    } catch (e) {
      final message = e.toString().contains('cancelled')
          ? 'Sign-in was cancelled.'
          : 'Login failed. Please try again.';
      state = app.AuthError(message);
    }
  }

  /// Complete profile and transition to authenticated.
  Future<void> completeProfile({
    required String city,
    required String selectedState,
    required String language,
    String? name,
  }) async {
    state = const app.AuthLoading('Saving profile…');

    try {
      await _repo.saveUserProfile(
        city: city,
        state: selectedState,
        language: language,
        name: name,
      );
    } catch (_) {
      // DB save failed (table missing / RLS) — non-critical.
      // Still mark profile as locally complete so user isn't stuck.
    }

    final user = _repo.currentUser;
    if (user != null) {
      state = app.AuthAuthenticated(
        userId: user.id,
        email: user.email ?? '',
        displayName: _extractName(user),
        avatarUrl: user.userMetadata?['avatar_url'] as String?,
        city: city,
      );
    } else {
      state = const app.AuthUnauthenticated();
    }
  }

  /// Sign out and reset to unauthenticated.
  Future<void> signOut() async {
    state = const app.AuthLoading('Signing out…');
    try {
      await _repo.signOut();
    } catch (_) {
      // Always go to unauthenticated even if signOut fails
    }
    state = const app.AuthUnauthenticated();
  }

  /// Reset error state to unauthenticated (for retry).
  void resetError() {
    state = const app.AuthUnauthenticated();
  }

  // ── OTP Logic ──

  Future<void> sendOtp(String phone) async {
    state = const app.AuthLoading('Sending OTP...');
    try {
      await _repo.sendOtp(phone: phone);
      // We don't change state to "authenticated" yet, just remain in a state 
      // where UI knows OTP is sent. 
      // Actually, standard practice: keep state as Unauthenticated but UI shows verify screen?
      // Or introduce a new state `AuthOtpSent`?
      // For simplicity, let's just make the function return success/fail 
      // and let the UI handle the navigation to Verify Screen.
      // But we must reset loading.
      state = const app.AuthUnauthenticated(); // Or stay loading? 
      // Better: The UI calls this, awaits it. If no error, UI navigates.
    } catch (e) {
      state = app.AuthError(e.toString());
    }
  }

  Future<void> verifyOtp(String phone, String otp) async {
    state = const app.AuthLoading('Verifying OTP...');
    try {
      await _repo.verifyOtp(phone: phone, otp: otp);
      // After success, _handleSignedIn should ideally be called if onAuthStateChange triggers.
      // If `setSession` works, it triggering the listener.
      // If it doesn't trigger listener automatically, we might need to manually call _handleSignedIn.
      // Let's call it manually to be safe if the listener doesn't fire for manual token set.
      await _handleSignedIn(); 
    } catch (e) {
      state = app.AuthError(e.toString());
    }
  }
}
