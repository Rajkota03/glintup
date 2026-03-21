import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text('Library'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: savedCards.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (cards) {
          if (cards.isEmpty) {
            return _EmptyLibrary();
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final saved = cards[index];
              return _SavedCardTile(saved: saved);
            },
          );
        },
      ),
    );
  }
}

class _EmptyLibrary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_outline_rounded,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved cards yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the bookmark icon on any card\nto save it here for later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
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

  @override
  Widget build(BuildContext context) {
    final card = saved.card;
    if (card == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _CardTypeChip(cardType: card.cardType),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    card.topic,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.bookmark_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              card.title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (card.summary != null) ...[
              const SizedBox(height: 6),
              Text(
                card.summary!,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '${card.estimatedReadSeconds}s read',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardTypeChip extends StatelessWidget {
  final CardType cardType;

  const _CardTypeChip({required this.cardType});

  Color get _color => switch (cardType) {
        CardType.quickFact => AppColors.quickFact,
        CardType.insight => AppColors.insight,
        CardType.visual => AppColors.visual,
        CardType.story => AppColors.story,
        CardType.deepRead => AppColors.deepRead,
        CardType.question => AppColors.question,
        CardType.quote => AppColors.quote,
      };

  String get _label => switch (cardType) {
        CardType.quickFact => 'Fact',
        CardType.insight => 'Insight',
        CardType.visual => 'Visual',
        CardType.story => 'Story',
        CardType.deepRead => 'Deep Read',
        CardType.question => 'Question',
        CardType.quote => 'Quote',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
