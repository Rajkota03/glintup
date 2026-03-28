import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glintup/features/onboarding/screens/welcome_screen.dart';
import 'package:glintup/features/onboarding/screens/topic_selection_screen.dart';
import 'package:glintup/features/onboarding/screens/notification_setup_screen.dart';
import 'package:glintup/features/edition/screens/edition_screen.dart';
import 'package:glintup/features/edition/screens/completion_screen.dart';
import 'package:glintup/features/library/screens/library_screen.dart';
import 'package:glintup/features/explore/screens/explore_screen.dart';
import 'package:glintup/features/profile/screens/profile_screen.dart';
import 'package:glintup/features/profile/screens/settings_screen.dart';
import 'package:glintup/features/auth/screens/login_screen.dart';
import 'package:glintup/shared/widgets/app_shell.dart';
import 'package:glintup/shared/widgets/splash_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/topics',
        builder: (context, state) => const TopicSelectionScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const NotificationSetupScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EditionScreen(),
            ),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryScreen(),
            ),
          ),
          GoRoute(
            path: '/explore',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ExploreScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfileScreen(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/completion',
        builder: (context, state) => const CompletionScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
