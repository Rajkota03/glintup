import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Insight card — Minimal Luxury design.
///
/// Layout:
/// - Pill badge "Insight" in dusty blue
/// - Topic in small caps
/// - Title in Playfair Display
/// - Body in Inter with generous line-height
/// - Key Takeaway section at bottom
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pill badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.insight.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 14,
                  color: AppColors.insight,
                ),
                const SizedBox(width: 4),
                Text(
                  'Insight',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.insight,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Topic in small caps
          Text(
            card.topic.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),

          // Title
          Text(
            card.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
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
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.8,
                ),
              ),
            ),
          ),

          // Key Takeaway section
          if (card.summary != null && card.summary!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.insight.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(
                    color: AppColors.insight.withValues(alpha: 0.4),
                    width: 3,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_rounded,
                    size: 18,
                    color: AppColors.insight.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Key Takeaway',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.insight,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          card.summary!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '\u2014 ${card.sourceName}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
