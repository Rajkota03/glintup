import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
/// Minimal Luxury + Warm Editorial redesign.
/// ──────────────────────────────────────────────────────────────
class EditionScreen extends ConsumerStatefulWidget {
  const EditionScreen({super.key});

  @override
  ConsumerState<EditionScreen> createState() => _EditionScreenState();
}

class _EditionScreenState extends ConsumerState<EditionScreen>
    with SingleTickerProviderStateMixin {
  bool _editionLoaded = false;
  final _cardRepo = CardRepository();
  late AnimationController _swipeHintController;

  @override
  void initState() {
    super.initState();
    _swipeHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _swipeHintController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editionAsync = ref.watch(todayEditionProvider('free'));
    final editionState = ref.watch(editionStateProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: editionAsync.when(
          loading: () => _ShimmerLoading(),
          error: (e, _) {
            return _ErrorState(
                error: 'Unable to load edition. Pull to refresh.');
          },
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

            final dateStr = DateFormat('EEEE, MMMM d')
                .format(edition.editionDate);

            return Column(
              children: [
                // ── Gold progress bar at very top ─────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: CardProgressBar(
                    currentIndex: editionState.currentIndex,
                    totalCards: editionState.totalCards,
                    height: 3.0,
                    color: AppColors.primary,
                    backgroundColor: AppColors.primaryLight.withOpacity(0.3),
                  ),
                ),

                // ── Header ──────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Date in serif
                            Text(
                              dateStr,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (edition.theme != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                edition.theme!,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Edition number as subtle gold badge
                      if (edition.editionNumber != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '#${edition.editionNumber}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Card counter ────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${editionState.currentIndex + 1} of ${editionState.totalCards}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        _formatTime(editionState.totalTimeSeconds),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        ),
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
                      ref
                          .read(editionStateProvider.notifier)
                          .setIndex(index);
                    },
                    onLastCardSwiped: () {
                      ref.read(editionStateProvider.notifier).markCompleted();
                      context.push('/completion');
                    },
                    onSaveToggle: (cardId) => _toggleSave(cardId),
                  ),
                ),

                // ── Bottom bar: share + swipe hint + bookmark ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Share icon
                      GestureDetector(
                        onTap: () {
                          // Share action placeholder
                        },
                        child: const Icon(
                          Icons.ios_share_rounded,
                          size: 20,
                          color: AppColors.textMuted,
                        ),
                      ),
                      // Swipe up hint
                      AnimatedBuilder(
                        animation: _swipeHintController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                                0,
                                -4 *
                                    _swipeHintController.value),
                            child: Opacity(
                              opacity:
                                  0.3 + 0.3 * _swipeHintController.value,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.keyboard_arrow_up_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                  Text(
                                    'swipe up',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textMuted,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Bookmark icon placeholder
                      GestureDetector(
                        onTap: () {
                          final currentCard =
                              editionState.currentCard?.card;
                          if (currentCard != null) {
                            _toggleSave(currentCard.id);
                          }
                        },
                        child: Icon(
                          _isCurrentCardSaved(editionState)
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          size: 20,
                          color: _isCurrentCardSaved(editionState)
                              ? AppColors.primary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  bool _isCurrentCardSaved(EditionState state) {
    final currentCard = state.currentCard?.card;
    if (currentCard == null) return false;
    return ref.read(_savedCardIdsProvider).contains(currentCard.id);
  }

  void _toggleSave(String cardId) {
    final userId = SupabaseConfig.userId;
    if (userId == null) return;

    final saved = ref.read(_savedCardIdsProvider);
    final isSaved = saved.contains(cardId);

    if (isSaved) {
      ref.read(_savedCardIdsProvider.notifier).state = {...saved}
        ..remove(cardId);
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
      padding: const EdgeInsets.all(24),
      child: Shimmer.fromColors(
        baseColor: AppColors.surfaceAlt,
        highlightColor: AppColors.background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress bar placeholder
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            // Header placeholder
            Container(
              width: 200,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 120,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
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
                color: AppColors.primary.withOpacity(0.08),
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your next daily edition is being prepared.\nCheck back soon!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
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
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
