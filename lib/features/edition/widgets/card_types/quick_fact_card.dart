import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// A short, punchy card for 10-second reads.
///
/// Layout:
/// - Large emoji / icon at top
/// - Bold title (22 px)
/// - 1-2 sentence body
/// - Source attribution at the bottom
/// - Subtle gradient background
class QuickFactCard extends StatelessWidget {
  const QuickFactCard({super.key, required this.card});

  final CardModel card;

  /// Returns a contextual emoji based on the topic.
  String _topicEmoji(String topic) {
    switch (topic.toLowerCase()) {
      case 'science':
        return '\u{1F52C}'; // microscope
      case 'history':
        return '\u{1F3DB}'; // classical building
      case 'psychology':
        return '\u{1F9E0}'; // brain
      case 'technology':
        return '\u{1F4BB}'; // laptop
      case 'arts':
        return '\u{1F3A8}'; // palette
      case 'business':
        return '\u{1F4C8}'; // chart increasing
      case 'nature':
        return '\u{1F33F}'; // herb
      case 'space':
        return '\u{1F680}'; // rocket
      default:
        return '\u{2728}'; // sparkles
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.quickFact.withOpacity(0.05),
            Colors.white,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji / icon
          Text(
            _topicEmoji(card.topic),
            style: const TextStyle(fontSize: 48),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            card.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Body
          Text(
            card.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Source: ${card.sourceName}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
