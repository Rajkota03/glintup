import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/core/network/supabase_client.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/saved_card_model.dart';

final savedCardsProvider = FutureProvider<List<SavedCardModel>>((ref) async {
  final userId = SupabaseConfig.userId;
  if (userId == null) return [];

  final response = await SupabaseConfig.client
      .from('saved_cards')
      .select('*, card:cards(*)')
      .eq('user_id', userId)
      .order('created_at', ascending: false);

  return (response as List)
      .map((json) => SavedCardModel.fromJson(json))
      .toList();
});

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedCards = ref.watch(savedCardsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text(
                'Library',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            // Content
            Expanded(
              child: savedCards.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (_, _) => _EmptyLibrary(),
                data: (cards) {
                  if (cards.isEmpty) {
                    return _EmptyLibrary();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                    itemCount: cards.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final saved = cards[index];
                      return _SavedCardTile(saved: saved);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border,
              size: 64,
              color: AppColors.primary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved cards yet',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any card\nto save it here',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textTertiary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedCardTile extends StatelessWidget {
  final SavedCardModel saved;

  const _SavedCardTile({required this.saved});

  Color _typeColor(CardType type) => switch (type) {
        CardType.quickFact => AppColors.quickFact,
        CardType.insight => AppColors.insight,
        CardType.visual => AppColors.visual,
        CardType.story => AppColors.story,
        CardType.deepRead => AppColors.deepRead,
        CardType.question => AppColors.question,
        CardType.quote => AppColors.quote,
      };

  String _typeLabel(CardType type) => switch (type) {
        CardType.quickFact => 'Fact',
        CardType.insight => 'Insight',
        CardType.visual => 'Visual',
        CardType.story => 'Story',
        CardType.deepRead => 'Deep Read',
        CardType.question => 'Question',
        CardType.quote => 'Quote',
      };

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final card = saved.card;
    if (card == null) return const SizedBox.shrink();

    final color = _typeColor(card.cardType);
    final readTime = card.estimatedReadSeconds >= 60
        ? '${card.estimatedReadSeconds ~/ 60} min'
        : '${card.estimatedReadSeconds}s';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left colored border
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Topic label
                    Text(
                      card.topic.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Title
                    Text(
                      card.title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (card.summary != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        card.summary!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 10),
                    // Bottom row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _typeLabel(card.cardType),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          readTime,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Saved ${_formatDate(saved.createdAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.bookmark_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
