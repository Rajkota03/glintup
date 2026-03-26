import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glintup/app.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/core/services/cache_service.dart';
import 'package:glintup/core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await CacheService.initialize();
  await NotificationService().initialize();
  runApp(const ProviderScope(child: GlintupApp()));
}
