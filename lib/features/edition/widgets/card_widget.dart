import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';
import 'package:glintup/features/edition/widgets/card_types/quick_fact_card.dart';
import 'package:glintup/features/edition/widgets/card_types/insight_card.dart';
import 'package:glintup/features/edition/widgets/card_types/visual_card.dart';
import 'package:glintup/features/edition/widgets/card_types/story_card.dart';
import 'package:glintup/features/edition/widgets/card_types/quote_card.dart';
import 'package:glintup/features/edition/widgets/card_types/question_card.dart';
import 'package:glintup/features/edition/widgets/card_types/deep_read_card.dart';

/// Base card widget that delegates to the appropriate card-type renderer.
///
/// Wraps every card in a rounded container with shadow and provides
/// consistent chrome:
///   - Topic label chip (top-left)
///   - Estimated read time (top-right)
///   - Save / bookmark button (top-right, passed in via callback)
///   - Source attribution at bottom (when available)
class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.isSaved = false,
    this.onSaveToggle,
  });

  final CardModel card;
  final bool isSaved;
  final VoidCallback? onSaveToggle;

  /// Returns a human-readable read-time string.
  String _readTime(int seconds) {
    if (seconds < 60) return '${seconds}s read';
    final minutes = (seconds / 60).ceil();
    return '$minutes min read';
  }

  /// Returns the colour associated with the card type.
  Color _cardTypeColor(CardType type) {
    switch (type) {
      case CardType.quickFact:
        return AppColors.quickFact;
      case CardType.insight:
        return AppColors.insight;
      case CardType.visual:
        return AppColors.visual;
      case CardType.story:
        return AppColors.story;
      case CardType.deepRead:
        return AppColors.deepRead;
      case CardType.question:
        return AppColors.question;
      case CardType.quote:
        return AppColors.quote;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.78;
    final typeColor = _cardTypeColor(card.cardType);

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Card content
            Positioned.fill(
              child: _buildCardContent(),
            ),

            // Top overlay: topic chip + read time + bookmark
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Topic chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      card.topic,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: typeColor,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Read time
                  Text(
                    _readTime(card.estimatedReadSeconds),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bookmark / save button
                  if (onSaveToggle != null)
                    GestureDetector(
                      onTap: onSaveToggle,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSaved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          key: ValueKey(isSaved),
                          size: 22,
                          color:
                              isSaved ? AppColors.accent : AppColors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Bottom source attribution
            if (card.sourceName != null && card.sourceName!.isNotEmpty)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Text(
                  card.sourceName!,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: AppColors.textMuted.withOpacity(0.7),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Delegates rendering to the appropriate card type widget.
  Widget _buildCardContent() {
    switch (card.cardType) {
      case CardType.quickFact:
        return QuickFactCard(card: card);
      case CardType.insight:
        return InsightCard(card: card);
      case CardType.visual:
        return VisualCard(card: card);
      case CardType.story:
        return StoryCard(card: card);
      case CardType.quote:
        return QuoteCard(card: card);
      case CardType.deepRead:
        return DeepReadCard(card: card);
      case CardType.question:
        return QuestionCard(card: card);
    }
  }
}
