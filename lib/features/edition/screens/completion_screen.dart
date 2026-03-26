import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/data/repositories/stats_repository.dart';
import 'package:glintup/features/edition/providers/edition_provider.dart';

/// ──────────────────────────────────────────────────────────────
/// Completion Screen — Minimal Luxury + Warm Editorial redesign.
///
/// Clean, centered layout with:
///   - Gold checkmark icon
///   - "Edition Complete" in Playfair Display
///   - Stats row separated by gold dividers
///   - Streak section with warm gradient
///   - "See You Tomorrow" gold button
///   - Static sparkle decorations
/// ──────────────────────────────────────────────────────────────
class CompletionScreen extends ConsumerStatefulWidget {
  const CompletionScreen({super.key});

  @override
  ConsumerState<CompletionScreen> createState() => _CompletionScreenState();
}

class _CompletionScreenState extends ConsumerState<CompletionScreen> {
  bool _persisted = false;

  @override
  void initState() {
    super.initState();
    _persistCompletion();
  }

  Future<void> _persistCompletion() async {
    if (_persisted) return;
    _persisted = true;

    final state = ref.read(editionStateProvider);
    if (state.edition == null) return;

    try {
      await StatsRepository().completeEdition(
        state.edition!.id,
        state.totalTimeSeconds,
      );
    } catch (_) {
      // Fail silently — we don't want to block the celebration.
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editionStateProvider);
    final cardsRead = state.totalCards;
    final timeSeconds = state.totalTimeSeconds;
    final xpEarned =
        cardsRead * AppConstants.xpPerCard + AppConstants.xpStreakBonus;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // Sparkle decorations
            ..._buildSparkles(context),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const Spacer(flex: 2),

                  // ── Gold checkmark icon ─────────────────
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.primary,
                      size: 44,
                    ),
                  )
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      )
                      .fadeIn(duration: 400.ms),

                  const SizedBox(height: 28),

                  // ── Title ────────────────────────────────
                  Text(
                    'Edition Complete',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 8),

                  Text(
                    'You\'re done for today. Great job!',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 36),

                  // ── Stats row with gold dividers ─────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 24, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatItem(
                              value: '$cardsRead',
                              label: 'cards',
                            ),
                          ),
                          Container(
                            width: 1,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _StatItem(
                              value: _formatTime(timeSeconds),
                              label: 'time',
                            ),
                          ),
                          Container(
                            width: 1,
                            color: AppColors.primary.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _StatItem(
                              value: '+$xpEarned',
                              label: 'XP',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 700.ms, duration: 500.ms)
                      .slideY(begin: 0.15, end: 0),

                  const SizedBox(height: 24),

                  // ── Streak section ───────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: AppColors.goldGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              '\u{1F525}',
                              style: TextStyle(fontSize: 20),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '7 Day Streak',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        // 7 dots for the week
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: List.generate(7, (i) {
                            // Simulate all 7 days filled for demo
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < 7
                                      ? Colors.white
                                      : Colors.white
                                          .withOpacity(0.3),
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 900.ms, duration: 500.ms)
                      .slideY(begin: 0.1, end: 0),

                  const Spacer(flex: 3),

                  // ── CTA: "See You Tomorrow" ─────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'See You Tomorrow',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1100.ms, duration: 400.ms),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds static sparkle/star decorations positioned around the screen.
  List<Widget> _buildSparkles(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final rng = Random(42); // Fixed seed for consistent positions

    return List.generate(8, (i) {
      final x = rng.nextDouble() * (size.width - 40) + 20;
      final y = rng.nextDouble() * (size.height * 0.5) + 60;
      final sparkleSize = 12.0 + rng.nextDouble() * 12;
      final delay = 400 + i * 200;

      return Positioned(
        left: x,
        top: y,
        child: Icon(
          Icons.auto_awesome,
          size: sparkleSize,
          color: AppColors.primary.withOpacity(0.15 + rng.nextDouble() * 0.1),
        )
            .animate()
            .fadeIn(delay: delay.ms, duration: 600.ms)
            .scale(
              begin: const Offset(0, 0),
              end: const Offset(1, 1),
              delay: delay.ms,
              duration: 600.ms,
              curve: Curves.elasticOut,
            ),
      );
    });
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    if (s == 0) return '${m}m';
    return '${m}m ${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

/// A single stat item in the completion stats row.
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
