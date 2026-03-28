import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Illustration placeholder
              Center(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    size: 96,
                    color: AppColors.primary,
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Heading
              Text(
                'Welcome to ${AppConstants.appName}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),

              const SizedBox(height: 12),

              // Subtitle
              Text(
                'Your daily dose of learning.\nThen you\'re done.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),

              const Spacer(flex: 2),

              // Get Started button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/onboarding/topics'),
                  child: const Text('Get Started'),
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
