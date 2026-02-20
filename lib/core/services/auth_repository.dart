import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../services/local_storage_service.dart';
import 'backend_auth_service.dart';

/// Repository handling Firebase Authentication and Backend synchronization.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final BackendAuthService _backend = BackendAuthService();

  // ── Getters ──

  /// Currently authenticated user, or null.
  User? get currentUser => _auth.currentUser;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Sign In ──

  /// Sign in with Google.
  Future<UserCredential> signInWithGoogle() async {
    // Trigger the authentication flow
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }

    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    // Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase with the Google Credential
    return await _auth.signInWithCredential(credential);
  }

  /// Sign in with Phone Number (Verify Phone Number).
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
    );
  }

  /// Sign in with Phone OTP.
  Future<UserCredential> signInWithOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final PhoneAuthCredential credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return await _auth.signInWithCredential(credential);
  }

  // ── Backend Sync ──

  /// Verifies Firebase token with backend and checks profile status.
  /// Returns a map with 'profile_complete', 'user_id', and 'user_data'.
  Future<Map<String, dynamic>> verifyWithBackend() async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get ID Token');

    return await _backend.firebaseLogin(token);
  }

  /// Update user profile in backend.
  Future<void> updateProfile({
    required String name,
    required String state,
    required String city,
    required String language,
    String role = 'farmer',
  }) async {
    final user = currentUser;
    if (user == null) throw Exception('No authenticated user');

    await _backend.updateProfile(
      firebaseUid: user.uid,
      name: name,
      state: state,
      city: city,
      language: language,
      role: role,
    );
  }

  /// Fetches user profile from backend.
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final result = await verifyWithBackend();
      return result['user_data'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  // ── Sign Out ──

  /// Sign out from Firebase and Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
    await LocalStorageService.setProfileCompleted(false);
    await LocalStorageService.setOnboarded(false);
  }
}
