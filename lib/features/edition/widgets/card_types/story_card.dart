import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Story card — Minimal Luxury design.
///
/// Layout:
/// - Pill badge "Story" in muted purple
/// - Reading time estimate with clock icon
/// - Title in Playfair Display
/// - Long body with comfortable reading typography
/// - Pull quotes in Playfair Display italic with gold left border
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.card});

  final CardModel card;

  String _readTime(int seconds) {
    if (seconds < 60) return '${seconds}s read';
    final minutes = (seconds / 60).ceil();
    return '$minutes min read';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: pill badge + reading time
          Row(
            children: [
              // Pill badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.story.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.auto_stories_outlined,
                      size: 14,
                      color: AppColors.story,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Story',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.story,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Reading time
              Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.textMuted.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                _readTime(card.estimatedReadSeconds),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

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

          // Body — markdown rendered
          Expanded(
            child: Markdown(
              data: card.body,
              shrinkWrap: false,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppColors.textSecondary,
                  height: 1.8,
                ),
                h1: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                h2: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                strong: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                em: GoogleFonts.inter(
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
                // Pull quote styling with gold left border
                blockquotePadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                blockquoteDecoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: AppColors.primary,
                      width: 3,
                    ),
                  ),
                ),
                blockquote: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textPrimary,
                  height: 1.6,
                ),
              ),
            ),
          ),

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
