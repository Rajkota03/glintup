import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glintup/core/network/supabase_client.dart';

class AuthRepository {
  // TODO: Replace with your actual Google OAuth Client IDs from
  // Google Cloud Console → APIs & Services → Credentials
  // iOS: Create an iOS OAuth client ID
  // Web: Create a Web OAuth client ID (used as serverClientId)
  static const _webClientId =
      'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com';
  static const _iosClientId =
      'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _iosClientId,
      serverClientId: _webClientId,
    );
    _initialized = true;
  }

  /// Sign in with Google using native Google Sign-In + Supabase auth.
  Future<AuthResponse> signInWithGoogle() async {
    await _ensureInitialized();

    final googleUser = await GoogleSignIn.instance.authenticate();

    final idToken = googleUser.authentication.idToken;
    if (idToken == null) {
      throw Exception('Failed to get Google ID token');
    }

    // Sign in to Supabase with the Google ID token
    final response = await SupabaseConfig.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );

    return response;
  }

  /// Signs the current user out of both Google and Supabase.
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Google sign-out may fail if not signed in via Google
    }
    await SupabaseConfig.auth.signOut();
  }

  /// Returns the currently authenticated [User], or `null` if not signed in.
  User? get currentUser => SupabaseConfig.currentUser;

  /// A stream that emits [AuthState] changes.
  Stream<AuthState> get authStateChanges =>
      SupabaseConfig.auth.onAuthStateChange;
}
