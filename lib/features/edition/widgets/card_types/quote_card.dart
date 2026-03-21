import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// A quote card for ~10-second reads.
///
/// Layout:
/// - Large decorative opening quote mark
/// - Quote text in italic, large font (20 px)
/// - Attribution: "-- Author Name"
/// - Vertically and horizontally centred
/// - Gradient background from [AppColors.quote]
class QuoteCard extends StatelessWidget {
  const QuoteCard({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    // Use the title as the attribution / author and body as the quote text.
    final quoteText = card.body;
    final attribution = card.title;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.quote.withOpacity(0.08),
            Colors.white,
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Opening quote mark
          Text(
            '\u201C', // left double quotation mark
            style: TextStyle(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: AppColors.quote.withOpacity(0.25),
              height: 0.8,
            ),
          ),
          const SizedBox(height: 8),

          // Quote text
          Text(
            quoteText,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),

          // Attribution
          Text(
            '\u2014 $attribution',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              card.sourceName!,
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
