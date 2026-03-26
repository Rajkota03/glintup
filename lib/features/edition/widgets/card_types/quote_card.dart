import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Quote card — Minimal Luxury design.
///
/// COMPLETELY different layout: minimal, centered.
/// - Large decorative quotation mark in gold (72px)
/// - Quote text in Playfair Display italic, 22px, centered
/// - Attribution in small caps Inter
/// - Warm gold gradient background (very subtle)
/// - No left border, centered elegant layout
/// - Extra vertical padding for breathing room
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.04),
            AppColors.primaryLight.withOpacity(0.06),
            Colors.white.withOpacity(0.0),
          ],
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Large decorative opening quote mark in gold
          Text(
            '\u201C',
            style: GoogleFonts.playfairDisplay(
              fontSize: 72,
              fontWeight: FontWeight.w700,
              color: AppColors.primary.withOpacity(0.35),
              height: 0.8,
            ),
          ),
          const SizedBox(height: 16),

          // Quote text
          Text(
            quoteText,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 28),

          // Thin gold divider
          Container(
            width: 40,
            height: 1,
            color: AppColors.primary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),

          // Attribution in small caps
          Text(
            '\u2014 ${attribution.toUpperCase()}',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              letterSpacing: 1.5,
            ),
          ),

          // Source
          if (card.sourceName != null && card.sourceName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              card.sourceName!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w400,
                color: AppColors.textMuted,
              ),
            ),
          ],

          const Spacer(flex: 1),
        ],
      ),
    );
  }
}
