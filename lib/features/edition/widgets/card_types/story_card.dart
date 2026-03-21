import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// A story card for ~2-minute reads.
///
/// Layout:
/// - Bold title at top
/// - Longer body rendered as markdown
/// - Scrollable within the card if content overflows
/// - Light amber-tinted background
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.story.withOpacity(0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.story.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_stories_outlined,
              color: AppColors.story,
              size: 22,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),

          // Body — markdown rendered, scrollable
          Expanded(
            child: Markdown(
              data: card.body,
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
                h1: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                h2: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                strong: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                em: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                blockquotePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                blockquoteDecoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.story.withOpacity(0.5),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Source: ${card.sourceName}',
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
