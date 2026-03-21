import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/topic_model.dart';
import 'package:glintup/features/explore/providers/explore_provider.dart';

/// ──────────────────────────────────────────────────────────────
/// Explore Screen
///
/// Layout:
///   1. Working search bar with debounce
///   2. Horizontal topic chips
///   3. Vertical card feed for the selected topic
///   4. Rabbit Holes section (horizontal carousel)
/// ──────────────────────────────────────────────────────────────
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchQueryProvider.notifier).state = value;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final topicsAsync = ref.watch(topicsProvider);
    final selectedTopic = ref.watch(selectedTopicProvider);
    final rabbitHolesAsync = ref.watch(rabbitHolesProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final isSearching = searchQuery.trim().isNotEmpty;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Text(
                  'Explore',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search topics, cards...',
                      hintStyle: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade400,
                      ),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade400, size: 22),
                      suffixIcon: isSearching
                          ? GestureDetector(
                              onTap: _clearSearch,
                              child: Icon(Icons.close_rounded,
                                  color: Colors.grey.shade500, size: 20),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
            ),

            // ── Search results ────────────────────────────────
            if (isSearching) ...[
              _SearchResultsList(),
            ],

            // ── Normal explore view (when not searching) ──────
            if (!isSearching) ...[
              // ── Topic chips ─────────────────────────────────
              SliverToBoxAdapter(
                child: topicsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
                  ),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (topics) => _TopicChipsRow(
                    topics: topics,
                    selectedSlug: selectedTopic,
                    onSelected: (slug) {
                      ref.read(selectedTopicProvider.notifier).state =
                          selectedTopic == slug ? null : slug;
                    },
                  ),
                ),
              ),

              // ── Topic card feed ─────────────────────────────
              if (selectedTopic != null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Text(
                      _topicDisplayName(
                          selectedTopic, topicsAsync.valueOrNull ?? []),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                _TopicCardsFeed(topic: selectedTopic),
              ],

              // ── Rabbit Holes ────────────────────────────────
              if (selectedTopic == null) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Text(
                      'Rabbit Holes',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: rabbitHolesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (holes) {
                      if (holes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Rabbit holes coming soon!',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: holes.length,
                          separatorBuilder: (context, i) =>
                              const SizedBox(width: 14),
                          itemBuilder: (context, index) =>
                              _RabbitHoleCard(hole: holes[index]),
                        ),
                      );
                    },
                  ),
                ),

                // ── Browse by topic grid ──────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                    child: Text(
                      'Browse by Topic',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: topicsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (topics) => _TopicGrid(
                      topics: topics,
                      onTap: (slug) {
                        ref.read(selectedTopicProvider.notifier).state =
                            slug;
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _topicDisplayName(String slug, List<TopicModel> topics) {
    final match = topics.where((t) => t.slug == slug);
    return match.isNotEmpty ? match.first.displayName : slug;
  }
}

// ═══════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════

/// Search results list shown when search query is active.
class _SearchResultsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error searching: $e'),
        ),
      ),
      data: (cards) {
        if (cards.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No results found',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ExploreCardTile(card: cards[index]),
            childCount: cards.length,
          ),
        );
      },
    );
  }
}

/// Horizontal scrolling topic chips.
class _TopicChipsRow extends StatelessWidget {
  final List<TopicModel> topics;
  final String? selectedSlug;
  final ValueChanged<String> onSelected;

  const _TopicChipsRow({
    required this.topics,
    required this.selectedSlug,
    required this.onSelected,
  });

  Color _topicColor(String slug) {
    switch (slug) {
      case 'science':
        return AppColors.science;
      case 'history':
        return AppColors.history;
      case 'psychology':
        return AppColors.psychology;
      case 'technology':
        return AppColors.technology;
      case 'arts':
        return AppColors.arts;
      case 'business':
        return AppColors.business;
      case 'nature':
        return AppColors.nature;
      case 'space':
        return AppColors.space;
      default:
        return AppColors.primary;
    }
  }

  IconData _topicIcon(String? iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science_rounded;
      case 'history_edu':
        return Icons.history_edu_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.topic_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: topics.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final isSelected = selectedSlug == topic.slug;
          final color = _topicColor(topic.slug);

          return GestureDetector(
            onTap: () => onSelected(topic.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _topicIcon(topic.iconName),
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    topic.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Grid of topic cards shown when no topic is selected.
class _TopicGrid extends StatelessWidget {
  final List<TopicModel> topics;
  final ValueChanged<String> onTap;

  const _TopicGrid({required this.topics, required this.onTap});

  Color _topicColor(String slug) {
    switch (slug) {
      case 'science':
        return AppColors.science;
      case 'history':
        return AppColors.history;
      case 'psychology':
        return AppColors.psychology;
      case 'technology':
        return AppColors.technology;
      case 'arts':
        return AppColors.arts;
      case 'business':
        return AppColors.business;
      case 'nature':
        return AppColors.nature;
      case 'space':
        return AppColors.space;
      default:
        return AppColors.primary;
    }
  }

  IconData _topicIcon(String? iconName) {
    switch (iconName) {
      case 'science':
        return Icons.science_rounded;
      case 'history_edu':
        return Icons.history_edu_rounded;
      case 'psychology':
        return Icons.psychology_rounded;
      case 'computer':
        return Icons.computer_rounded;
      case 'palette':
        return Icons.palette_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'eco':
        return Icons.eco_rounded;
      case 'rocket_launch':
        return Icons.rocket_launch_rounded;
      default:
        return Icons.topic_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: topics.map((topic) {
          final color = _topicColor(topic.slug);
          return GestureDetector(
            onTap: () => onTap(topic.slug),
            child: Container(
              width: (MediaQuery.of(context).size.width - 52) / 2,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_topicIcon(topic.iconName),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Feed of published cards for a specific topic.
class _TopicCardsFeed extends ConsumerWidget {
  final String topic;
  const _TopicCardsFeed({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(exploreCardsProvider(topic));

    return cardsAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('Error loading cards: $e'),
        ),
      ),
      data: (cards) {
        if (cards.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded,
                        size: 48, color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    Text(
                      'No cards yet for this topic',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          );
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _ExploreCardTile(card: cards[index]),
            childCount: cards.length,
          ),
        );
      },
    );
  }
}

/// A single card tile in the topic feed.
class _ExploreCardTile extends StatelessWidget {
  final CardModel card;
  const _ExploreCardTile({required this.card});

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

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(card.cardType);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _typeLabel(card.cardType),
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${card.estimatedReadSeconds}s',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            card.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (card.summary != null) ...[
            const SizedBox(height: 4),
            Text(
              card.summary!,
              style: Theme.of(context).textTheme.bodyMedium,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

/// Rabbit hole card in the horizontal carousel.
class _RabbitHoleCard extends StatelessWidget {
  final RabbitHoleModel hole;
  const _RabbitHoleCard({required this.hole});

  Color _topicColor(String topic) {
    switch (topic) {
      case 'science':
        return AppColors.science;
      case 'history':
        return AppColors.history;
      case 'psychology':
        return AppColors.psychology;
      case 'technology':
        return AppColors.technology;
      case 'arts':
        return AppColors.arts;
      case 'business':
        return AppColors.business;
      case 'nature':
        return AppColors.nature;
      case 'space':
        return AppColors.space;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _topicColor(hole.topic);

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.02)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  hole.topic,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              if (hole.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRO',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            hole.title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (hole.description != null) ...[
            const SizedBox(height: 4),
            Text(
              hole.description!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const Spacer(),
          Row(
            children: [
              Icon(Icons.style_rounded,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${hole.totalCards} cards',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.timer_outlined,
                  size: 14, color: Colors.grey.shade400),
              const SizedBox(width: 4),
              Text(
                '${hole.estimatedTimeMinutes}m',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
