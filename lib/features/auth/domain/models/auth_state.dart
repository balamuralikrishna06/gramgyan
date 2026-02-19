/// Sealed class representing distinct authentication states.
sealed class AuthState {
  const AuthState();
}

/// Initial state — app just launched, checking session.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading — actively authenticating or checking session.
class AuthLoading extends AuthState {
  final String message;
  const AuthLoading([this.message = 'Loading...']);
}

/// Authenticated — valid session exists.
class AuthAuthenticated extends AuthState {
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String? city;
  final String role; // 'farmer', 'expert', 'admin'

  const AuthAuthenticated({
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
    this.city,
    this.role = 'farmer',
  });
}

/// Unauthenticated — no valid session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Profile incomplete — authenticated but first-time user needs to fill profile.
class AuthProfileIncomplete extends AuthState {
  final String userId;
  final String email;
  final String? displayName;
  final String? avatarUrl;

  const AuthProfileIncomplete({
    required this.userId,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });
}

/// Error — authentication failed.
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}
