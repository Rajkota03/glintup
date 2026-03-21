import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  static GoTrueClient get auth => client.auth;
  static User? get currentUser => auth.currentUser;
  static String? get userId => currentUser?.id;
  static bool get isAuthenticated => currentUser != null;

  static FunctionsClient get functions => client.functions;

  static Future<Map<String, dynamic>> invokeFunction(
    String functionName, {
    Map<String, dynamic>? body,
    HttpMethod method = HttpMethod.post,
  }) async {
    final response = await functions.invoke(
      functionName,
      body: body,
      method: method,
    );
    return response.data as Map<String, dynamic>;
  }
}
