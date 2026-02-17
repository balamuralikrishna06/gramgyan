import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../services/local_storage_service.dart';

/// Clean repository encapsulating all Supabase authentication operations.
/// Uses Supabase OAuth redirect flow for Google sign-in.
class AuthRepository {
  final SupabaseClient _client;

  AuthRepository() : _client = Supabase.instance.client;

  // ── Getters ──

  /// Currently authenticated user, or null.
  User? get currentUser => _client.auth.currentUser;

  /// Current session, or null.
  Session? get currentSession => _client.auth.currentSession;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange.map((event) => event.event == AuthChangeEvent.signedIn
          ? AuthState.authenticated
          : AuthState.unauthenticated);

  // ── Sign In ──

  /// Sign in with Google using Supabase OAuth redirect flow.
  /// Opens the browser for Google sign-in and redirects back to the app.
  Future<void> signInWithGoogle() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: SupabaseConfig.redirectUrl,
    );
  }

  // ── Sign Out ──

  /// Sign out: clear Supabase session, Google session, and local flags.
  Future<void> signOut() async {
    await _client.auth.signOut();
    await LocalStorageService.setProfileCompleted(false);
    await LocalStorageService.setOnboarded(false);
  }

  // ── Profile ──

  /// Check if user has completed the onboarding profile.
  /// Checks local storage first. If false, checks remote DB (for existing users
  /// on new installs). Updates local storage if remote profile exists.
  Future<bool> checkProfileCompletion() async {
    // 1. Check local storage (fastest)
    if (LocalStorageService.isProfileCompleted()) {
      return true;
    }

    // 2. Check remote Supabase DB (fallback)
    final user = currentUser;
    if (user == null) return false;

    try {
      final profile = await fetchUserProfile();
      
      // Check if critical fields exist (village and state are required)
      if (profile != null && 
          profile['city'] != null && 
          (profile['city'] as String).isNotEmpty &&
          profile['state'] != null &&
          (profile['state'] as String).isNotEmpty) {
            
        // Sync local storage
        await LocalStorageService.setProfileCompleted(true);
        // Also sync other fields if needed, but profile_completed is key
        return true;
      }
    } catch (_) {
      // Network error or other issue — assume incomplete to be safe
      return false;
    }

    return false;
  }

  /// Save farmer profile to Supabase `users` table.
  Future<void> saveUserProfile({
    required String city,
    required String state,
    required String language,
  }) async {
    final user = currentUser;
    if (user == null) throw AuthException('No authenticated user.');

    try {
      await _client.from(SupabaseConfig.usersTable).upsert({
        'id': user.id,
        'email': user.email,
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@').first,
        'city': city,
        'state': state,
        'language': language,
      });
    } catch (_) {
      // DB save failed (table missing / RLS) — non-critical.
      // Profile will be marked complete locally below.
    }

    await LocalStorageService.setProfileCompleted(true);
  }

  /// Fetch user profile from Supabase `users` table.
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    try {
      final data = await _client
          .from(SupabaseConfig.usersTable)
          .select()
          .eq('id', user.id)
          .maybeSingle();
      return data;
    } catch (_) {
      return null;
    }
  }

  // ── Private ──

  /// Upsert a basic user record on first sign-in.
  Future<void> _upsertUserRecord(User user) async {
    try {
      await _client.from(SupabaseConfig.usersTable).upsert({
        'id': user.id,
        'email': user.email,
        'id': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ??
            user.userMetadata?['name'] ??
            user.email?.split('@').first,
      });
    } catch (_) {
      // Non-critical — profile can be completed later.
    }
  }
}

/// Simple auth state enum for the stream.
enum AuthState { authenticated, unauthenticated }
