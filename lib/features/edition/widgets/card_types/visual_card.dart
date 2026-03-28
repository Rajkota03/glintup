import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Visual card — Minimal Luxury design.
///
/// Layout:
/// - Pill badge "Visual" in warm amber
/// - Large image with rounded corners (12px)
/// - Title below image in Playfair Display
/// - Body in Inter
class VisualCard extends StatelessWidget {
  const VisualCard({super.key, required this.card});

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
              color: AppColors.visual.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.palette_outlined,
                  size: 14,
                  color: AppColors.visual,
                ),
                const SizedBox(width: 4),
                Text(
                  'Visual',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.visual,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _buildImage(),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            card.title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),

          // Body / caption
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.body,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.8,
                    ),
                  ),
                  if (card.sourceName != null &&
                      card.sourceName!.isNotEmpty) ...[
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (card.imageUrl != null && card.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: card.imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (context, url) => _imagePlaceholder(),
        errorWidget: (context, url, error) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.visual.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          size: 48,
          color: AppColors.visual,
        ),
      ),
    );
  }
}
