import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:glintup/core/network/supabase_client.dart';

/// Streams authentication state changes from Supabase.
///
/// Emits an [AuthState] each time the user signs in, signs out,
/// or their token is refreshed.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

/// Synchronously exposes the currently signed-in [User], or `null`
/// if no session exists.
final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.currentUser;
});
