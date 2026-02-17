/// Supabase configuration constants.
/// Replace these placeholder values with your actual Supabase project credentials.
class SupabaseConfig {
  SupabaseConfig._();

  // ── Supabase Project Credentials ──
  // Get these from: Supabase Dashboard → Settings → API
  static const String url = 'https://cepcxehqwlcmhcsohaxs.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNlcGN4ZWhxd2xjbWhjc29oYXhzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzEwOTkxMTUsImV4cCI6MjA4NjY3NTExNX0.6uTsPnF0xj1w-3SZhwkjszkVystrAo-7GXOhHABZHPg';

  // ── OAuth Redirect URL ──
  // Must match: Supabase Dashboard → Authentication → URL Configuration → Redirect URLs
  static const String redirectUrl =
      'io.supabase.gramgyan://login-callback/';

  // ── Google OAuth ──
  // Web Client ID from Google Cloud Console → Credentials → OAuth 2.0 Client IDs
  // This is the WEB client ID (not Android), used by Supabase for token exchange.
  static const String googleWebClientId = '106834776476-7au2dr48eu3h0neethhc75sk0qko6h55.apps.googleusercontent.com';

  // ── Supabase Table Names ──
  static const String usersTable = 'users';
}
