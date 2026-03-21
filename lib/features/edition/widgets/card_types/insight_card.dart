import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// An insight card for ~30-second reads.
///
/// Layout:
/// - Bold title
/// - 3-4 sentence body with comfortable line height
/// - Optional decorative icon
/// - Light purple-tinted background
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.insight.withOpacity(0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Decorative icon
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.insight.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.lightbulb_outline_rounded,
              color: AppColors.insight,
              size: 22,
            ),
          ),
          const SizedBox(height: 20),

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

          // Body
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Text(
                card.body,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.7,
                ),
              ),
            ),
          ),

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 16),
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
