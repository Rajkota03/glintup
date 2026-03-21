import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// A deep-read card for longer, immersive reads.
///
/// Layout:
/// - Reading progress indicator (thin bar at top showing scroll position)
/// - Bold title
/// - Larger, more readable body text with markdown support
/// - Section breaks (horizontal rules)
/// - "Key Takeaway" box at the bottom with lightbulb icon
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.deepRead.withOpacity(0.04),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reading progress bar
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
                  // Decorative icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.deepRead.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: AppColors.deepRead,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.card.title,
                    style: const TextStyle(
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Section break
                  _sectionBreak(),

                  const SizedBox(height: 16),

                  // Body — markdown rendered, larger text for readability
                  MarkdownBody(
                    data: widget.card.body,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                        height: 1.8,
                      ),
                      h1: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      h2: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      h3: const TextStyle(
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
                      horizontalRuleDecoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.deepRead.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      blockquotePadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      blockquoteDecoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: AppColors.deepRead.withOpacity(0.5),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Source
                  if (widget.card.sourceName != null &&
                      widget.card.sourceName!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _sectionBreak(),
                    const SizedBox(height: 12),
                    Text(
                      'Source: ${widget.card.sourceName}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
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
                        color: AppColors.deepRead.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.deepRead.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.deepRead.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.lightbulb_rounded,
                              color: AppColors.deepRead,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Key Takeaway',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.deepRead,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  widget.card.summary!,
                                  style: const TextStyle(
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

                  // Bottom spacing so content isn't hidden behind overlay
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionBreak() {
    return Container(
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            AppColors.deepRead.withOpacity(0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}
