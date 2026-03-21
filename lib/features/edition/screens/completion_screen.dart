import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/constants/app_constants.dart';
import 'package:glintup/data/repositories/stats_repository.dart';
import 'package:glintup/features/edition/providers/edition_provider.dart';

/// ──────────────────────────────────────────────────────────────
/// Completion Screen — shown after the user finishes all cards.
///
/// Displays a celebration with stats:
///   • Total cards read
///   • Time spent
///   • XP earned
///
/// Calls `StatsRepository.completeEdition()` once to persist.
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // ── Celebration icon ─────────────────────────
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 52,
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

              const SizedBox(height: 32),

              // ── Title ────────────────────────────────────
              Text(
                'Edition Complete! 🎉',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 300.ms, duration: 400.ms)
                  .slideY(begin: 0.2, end: 0),

              const SizedBox(height: 8),

              Text(
                'You\'re done for today. Great job!',
                style: Theme.of(context).textTheme.bodyMedium,
              )
                  .animate()
                  .fadeIn(delay: 500.ms, duration: 400.ms),

              const SizedBox(height: 40),

              // ── Stats row ────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _StatBubble(
                      icon: Icons.style_rounded,
                      value: '$cardsRead',
                      label: 'Cards',
                      color: AppColors.quickFact,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBubble(
                      icon: Icons.timer_rounded,
                      value: _formatTime(timeSeconds),
                      label: 'Time',
                      color: AppColors.insight,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatBubble(
                      icon: Icons.star_rounded,
                      value: '+$xpEarned',
                      label: 'XP',
                      color: AppColors.streakFire,
                    ),
                  ),
                ],
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 500.ms)
                  .slideY(begin: 0.15, end: 0),

              const Spacer(flex: 3),

              // ── CTA ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  child: const Text('Continue'),
                ),
              )
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 400.ms),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
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

class _StatBubble extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBubble({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
