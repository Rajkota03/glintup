import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleIn = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // Navigate after splash animation
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) _navigate();
    });
  }

  Future<void> _navigate() async {
    if (SupabaseConfig.isAuthenticated) {
      // User is logged in — check if onboarding is complete
      try {
        final userId = SupabaseConfig.userId;
        final data = await SupabaseConfig.client
            .from('profiles')
            .select('onboarding_completed')
            .eq('id', userId!)
            .maybeSingle();

        if (!mounted) return;

        final onboardingDone =
            data != null && (data['onboarding_completed'] as bool? ?? false);

        if (onboardingDone) {
          context.go('/home');
        } else {
          context.go('/welcome');
        }
      } catch (_) {
        if (mounted) context.go('/home');
      }
    } else {
      // Not logged in — go to login
      if (mounted) context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Glintup',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your daily dose of learning',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppColors.textTertiary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
