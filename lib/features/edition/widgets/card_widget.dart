import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
/// Minimal Luxury + Warm Editorial design:
///   - White card with very subtle shadow
///   - Card type background tints
///   - Large faded position number in background
///   - Subtle left border accent per card type
///   - Pill badge for card type
class CardWidget extends StatelessWidget {
  const CardWidget({
    super.key,
    required this.card,
    this.cardIndex = 0,
    this.isSaved = false,
    this.onSaveToggle,
  });

  final CardModel card;
  final int cardIndex;
  final bool isSaved;
  final VoidCallback? onSaveToggle;

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

  /// Returns the background tint for each card type.
  Color _cardTypeBg(CardType type) {
    switch (type) {
      case CardType.quickFact:
        return AppColors.quickFactBg;
      case CardType.insight:
        return AppColors.insightBg;
      case CardType.visual:
        return AppColors.visualBg;
      case CardType.story:
        return AppColors.storyBg;
      case CardType.deepRead:
        return AppColors.deepReadBg;
      case CardType.question:
        return AppColors.questionBg;
      case CardType.quote:
        return AppColors.quoteBg;
    }
  }

  /// Whether this card type uses a left border accent.
  bool _usesLeftBorder(CardType type) {
    return type != CardType.quote; // Quote card has centered layout, no border
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final cardHeight = screenHeight * 0.78;
    final typeColor = _cardTypeColor(card.cardType);
    final bgColor = _cardTypeBg(card.cardType);
    final positionStr =
        (cardIndex + 1).toString().padLeft(2, '0');

    return Container(
      height: cardHeight,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: _usesLeftBorder(card.cardType)
            ? Border(
                left: BorderSide(
                  color: typeColor.withValues(alpha: 0.5),
                  width: 3,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background tint
            Positioned.fill(
              child: Container(color: bgColor),
            ),

            // Large faded position number
            Positioned(
              right: 16,
              bottom: 24,
              child: Text(
                positionStr,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 80,
                  fontWeight: FontWeight.w700,
                  color: typeColor.withValues(alpha: 0.05),
                  height: 1.0,
                ),
              ),
            ),

            // Card content
            Positioned.fill(
              child: _buildCardContent(),
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
