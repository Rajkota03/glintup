import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Deep Read card — Minimal Luxury design.
///
/// Layout:
/// - Pill badge "Deep Read" in deep teal
/// - Thin reading progress bar at top (teal)
/// - Larger body text (17px) with extra line-height (1.9)
/// - Section breaks as elegant thin gold dividers with diamond center
/// - Key Takeaway box at bottom with teal left border + lightbulb
class DeepReadCard extends StatefulWidget {
  const DeepReadCard({super.key, required this.card});

  final CardModel card;

  @override
  State<DeepReadCard> createState() => _DeepReadCardState();
}

class _DeepReadCardState extends State<DeepReadCard> {
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0) {
      setState(() => _scrollProgress = 1.0);
      return;
    }
    setState(() {
      _scrollProgress =
          (_scrollController.offset / maxScroll).clamp(0.0, 1.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thin teal reading progress bar at top
        AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          height: 3,
          width: MediaQuery.of(context).size.width * _scrollProgress,
          decoration: BoxDecoration(
            color: AppColors.deepRead,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const ClampingScrollPhysics(),
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pill badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.deepRead.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: AppColors.deepRead,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Deep Read',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.deepRead,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  widget.card.title,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),

                if (widget.card.subtitle != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.card.subtitle!,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Elegant gold divider with diamond
                _goldDivider(),

                const SizedBox(height: 20),

                // Body — markdown rendered, larger text
                MarkdownBody(
                  data: widget.card.body,
                  shrinkWrap: true,
                  styleSheet: MarkdownStyleSheet(
                    p: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                      height: 1.9,
                    ),
                    h1: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    h2: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    h3: GoogleFonts.playfairDisplay(
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
                    horizontalRuleDecoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.primary.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                    ),
                    blockquotePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    blockquoteDecoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary.withOpacity(0.5),
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

                // Source
                if (widget.card.sourceName != null &&
                    widget.card.sourceName!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _goldDivider(),
                  const SizedBox(height: 12),
                  Text(
                    '\u2014 ${widget.card.sourceName}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],

                // Key Takeaway box
                if (widget.card.summary != null &&
                    widget.card.summary!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.deepRead.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                        left: BorderSide(
                          color: AppColors.deepRead.withOpacity(0.5),
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
                          color: AppColors.deepRead.withOpacity(0.7),
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
                                  color: AppColors.deepRead,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                widget.card.summary!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.textSecondary,
                                  height: 1.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Bottom spacing
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Elegant thin gold divider with a diamond in the center.
  Widget _goldDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '\u25C6', // diamond
            style: TextStyle(
              fontSize: 8,
              color: AppColors.primary.withOpacity(0.4),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.primary.withOpacity(0.15),
          ),
        ),
      ],
    );
  }
}
