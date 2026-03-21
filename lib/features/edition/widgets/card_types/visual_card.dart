import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// A visual card for ~30-second reads.
///
/// Layout:
/// - Large image area (with placeholder / loading shimmer)
/// - Caption below image
/// - Short context line
/// - Light pink-tinted background
class VisualCard extends StatelessWidget {
  const VisualCard({super.key, required this.card});

  final CardModel card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.visual.withOpacity(0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            card.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
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

          // Caption / body
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    card.body,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  if (card.sourceName != null &&
                      card.sourceName!.isNotEmpty) ...[
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
        color: AppColors.visual.withOpacity(0.08),
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
