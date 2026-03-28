import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glintup/core/network/supabase_client.dart';

class AuthRepository {
  /// Sends an OTP to the given phone number by invoking the
  /// `send-otp` Supabase Edge Function.
  ///
  /// [phoneNumber] should include the country code, e.g. "+919876543210".
  Future<Map<String, dynamic>> sendOtp(String phoneNumber) async {
    final response = await SupabaseConfig.invokeFunction(
      'send-otp',
      body: {'phone': phoneNumber},
    );
    return response;
  }

  /// Verifies the OTP for the given phone number by invoking the
  /// `verify-otp` Supabase Edge Function, then signs the user in.
  ///
  /// Returns the response data from the edge function which may include
  /// session and user information.
  Future<Map<String, dynamic>> verifyOtp(
    String phoneNumber,
    String otp,
  ) async {
    final response = await SupabaseConfig.invokeFunction(
      'verify-otp',
      body: {
        'phone': phoneNumber,
        'otp': otp,
      },
    );

    // Set the session from the edge function response
    if (response['success'] == true && response['session'] != null) {
      final session = response['session'] as Map<String, dynamic>;
      await SupabaseConfig.auth.setSession(session['access_token'] as String);
    }

    return response;
  }

  /// Signs the current user out.
  Future<void> signOut() async {
    await SupabaseConfig.auth.signOut();
  }

  /// Returns the currently authenticated [User], or `null` if not signed in.
  User? get currentUser => SupabaseConfig.currentUser;

  /// A stream that emits [AuthState] changes (sign-in, sign-out, token refresh).
  Stream<AuthState> get authStateChanges =>
      SupabaseConfig.auth.onAuthStateChange;
}
