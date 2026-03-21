import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/repositories/card_repository.dart';
import 'package:glintup/features/edition/providers/edition_provider.dart';
import 'package:glintup/features/edition/widgets/card_progress_bar.dart';
import 'package:glintup/features/edition/widgets/card_stack_widget.dart';

/// ──────────────────────────────────────────────────────────────
/// Saved-card IDs for the current user (to show bookmark state).
/// ──────────────────────────────────────────────────────────────
final _savedCardIdsProvider = StateProvider<Set<String>>((ref) => {});

/// ──────────────────────────────────────────────────────────────
/// Edition Screen — the "Today" tab.
///
/// Flow:
///   1. Fetch today's edition via [todayEditionProvider]
///   2. Load it into [editionStateProvider]
///   3. Display a vertical card swiper via [CardStackWidget]
///   4. On last-card swipe → navigate to /completion
/// ──────────────────────────────────────────────────────────────
class EditionScreen extends ConsumerStatefulWidget {
  const EditionScreen({super.key});

  @override
  ConsumerState<EditionScreen> createState() => _EditionScreenState();
}

class _EditionScreenState extends ConsumerState<EditionScreen> {
  bool _editionLoaded = false;
  final _cardRepo = CardRepository();

  @override
  Widget build(BuildContext context) {
    // We default to the 'free' tier. Swap to 'pro' when user is subscribed.
    final editionAsync = ref.watch(todayEditionProvider('free'));
    final editionState = ref.watch(editionStateProvider);

    return Scaffold(
      body: SafeArea(
        child: editionAsync.when(
          loading: () => _ShimmerLoading(),
          error: (e, _) => _ErrorState(error: e.toString()),
          data: (data) {
            final edition = data.edition;
            final cards = data.cards;

            if (edition == null || cards.isEmpty) {
              return const _EmptyEdition();
            }

            // Load edition into state notifier once.
            if (!_editionLoaded) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(editionStateProvider.notifier)
                    .loadEdition(edition, cards);
                setState(() => _editionLoaded = true);
              });
              return _ShimmerLoading();
            }

            return Column(
              children: [
                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Today\'s Edition',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          if (edition.theme != null)
                            Text(
                              edition.theme!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                        ],
                      ),
                      const Spacer(),
                      // Edition number badge
                      if (edition.editionNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${edition.editionNumber}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Progress bar ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: CardProgressBar(
                    currentIndex: editionState.currentIndex,
                    totalCards: editionState.totalCards,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${editionState.currentIndex + 1} of ${editionState.totalCards}',
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        _formatTime(editionState.totalTimeSeconds),
                        style:
                            Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // ── Card swiper ─────────────────────────────
                Expanded(
                  child: CardStackWidget(
                    cards: editionState.cards,
                    initialIndex: editionState.currentIndex,
                    savedCardIds: ref.watch(_savedCardIdsProvider),
                    onCardChanged: (index) {
                      ref.read(editionStateProvider.notifier).setIndex(index);
                    },
                    onLastCardSwiped: () {
                      ref.read(editionStateProvider.notifier).markCompleted();
                      context.push('/completion');
                    },
                    onSaveToggle: (cardId) => _toggleSave(cardId),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _toggleSave(String cardId) {
    final userId = SupabaseConfig.userId;
    if (userId == null) return;

    final saved = ref.read(_savedCardIdsProvider);
    final isSaved = saved.contains(cardId);

    // Optimistic update
    if (isSaved) {
      ref.read(_savedCardIdsProvider.notifier).state = {...saved}..remove(cardId);
      _cardRepo.unsaveCard(userId, cardId);
    } else {
      ref.read(_savedCardIdsProvider.notifier).state = {...saved, cardId};
      _cardRepo.saveCard(userId, cardId);
    }
  }

  String _formatTime(int totalSeconds) {
    if (totalSeconds < 60) return '${totalSeconds}s';
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m}m ${s}s';
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

/// Shimmer loading skeleton shown while the edition is being fetched.
class _ShimmerLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Shimmer.fromColors(
        baseColor: Colors.grey.shade200,
        highlightColor: Colors.grey.shade100,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header placeholder
            Container(
              width: 180,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 24),
            // Progress bar placeholder
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Card placeholder
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Empty state shown when no edition is available for today.
class _EmptyEdition extends StatelessWidget {
  const _EmptyEdition();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_stories_rounded,
                size: 44,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No edition today',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Your next daily edition is being prepared.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state.
class _ErrorState extends StatelessWidget {
  final String error;
  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
