import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/data/models/topic_model.dart';
import 'package:glintup/features/explore/providers/explore_provider.dart';

/// ──────────────────────────────────────────────────────────────
/// Explore Screen — Minimal Luxury + Warm Editorial
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── Header ──────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Text(
                  'Explore',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Discover something new...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textTertiary,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      suffixIcon: isSearching
                          ? GestureDetector(
                              onTap: _clearSearch,
                              child: const Icon(
                                Icons.close_rounded,
                                color: AppColors.textTertiary,
                                size: 18,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14),
                    ),
                    style: GoogleFonts.inter(fontSize: 14),
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
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
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
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: _SectionHeader(
                      title: _topicDisplayName(
                          selectedTopic, topicsAsync.valueOrNull ?? [])
                          .toUpperCase(),
                    ),
                  ),
                ),
                _TopicCardsFeed(topic: selectedTopic),
              ],

              // ── Trending + Rabbit Holes ───────────────────
              if (selectedTopic == null) ...[
                // Trending header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                    child: Row(
                      children: [
                        Text(
                          'TRENDING',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Trending cards (first few from default topic)
                SliverToBoxAdapter(
                  child: topicsAsync.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (topics) {
                      if (topics.isEmpty) return const SizedBox.shrink();
                      return _TrendingCardsList(topic: topics.first.slug);
                    },
                  ),
                ),

                // Deep Dives header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                    child: Text(
                      'DEEP DIVES',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: rabbitHolesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    error: (e, st) => const SizedBox.shrink(),
                    data: (holes) {
                      if (holes.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Deep dives coming soon!',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 180,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 24),
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

                // Browse by topic grid
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
                    child: Text(
                      'BROWSE BY TOPIC',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                      ),
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

/// Small-caps section header with letter spacing.
class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.textTertiary,
        letterSpacing: 1.5,
      ),
    );
  }
}

/// Trending cards list for default topic.
class _TrendingCardsList extends ConsumerWidget {
  final String topic;
  const _TrendingCardsList({required this.topic});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardsAsync = ref.watch(exploreCardsProvider(topic));

    return cardsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (cards) {
        final trending = cards.take(3).toList();
        if (trending.isEmpty) return const SizedBox.shrink();
        return Column(
          children: trending
              .map((card) => _ExploreCardTile(card: card))
              .toList(),
        );
      },
    );
  }
}

/// Search results list shown when search query is active.
class _SearchResultsList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchAsync = ref.watch(searchResultsProvider);

    return searchAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      error: (e, st) => SliverToBoxAdapter(
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
                        size: 48, color: AppColors.textTertiary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No results found',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try a different search term',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: topics.length,
        separatorBuilder: (context, i) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final topic = topics[index];
          final isSelected = selectedSlug == topic.slug;

          return GestureDetector(
            onTap: () => onSelected(topic.slug),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Center(
                child: Text(
                  topic.displayName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : AppColors.textSecondary,
                  ),
                ),
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
        return Icons.science_outlined;
      case 'history_edu':
        return Icons.history_edu_outlined;
      case 'psychology':
        return Icons.psychology_outlined;
      case 'computer':
        return Icons.computer_outlined;
      case 'palette':
        return Icons.palette_outlined;
      case 'business':
        return Icons.business_outlined;
      case 'eco':
        return Icons.eco_outlined;
      case 'rocket_launch':
        return Icons.rocket_launch_outlined;
      default:
        return Icons.topic_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: topics.map((topic) {
          final color = _topicColor(topic.slug);
          return GestureDetector(
            onTap: () => onTap(topic.slug),
            child: Container(
              width: (MediaQuery.of(context).size.width - 60) / 2,
              padding: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_topicIcon(topic.iconName),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      topic.displayName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
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
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ),
      error: (e, st) => SliverToBoxAdapter(
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
                    Icon(Icons.inbox_outlined,
                        size: 48,
                        color: AppColors.textTertiary.withValues(alpha: 0.4)),
                    const SizedBox(height: 12),
                    Text(
                      'No cards yet for this topic',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textTertiary,
                      ),
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

/// A single card tile in the explore feed.
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
    final readTime = card.estimatedReadSeconds >= 60
        ? '${card.estimatedReadSeconds ~/ 60} min'
        : '${card.estimatedReadSeconds}s';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
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
                        Icon(
                          Icons.bookmark_border,
                          size: 18,
                          color: AppColors.textTertiary,
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
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hole.isPremium)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'PRO',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            hole.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${hole.totalCards} cards  ·  ${hole.estimatedTimeMinutes} min',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
