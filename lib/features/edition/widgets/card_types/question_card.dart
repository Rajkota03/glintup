import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glintup/core/constants/app_colors.dart';
import 'package:glintup/data/models/card_model.dart';

/// Question card — Minimal Luxury design.
///
/// Layout:
/// - Pill badge "Question" in terracotta
/// - Question text in Playfair Display (22px)
/// - 4 answer options as elegant bordered containers
///   - Letters (A, B, C, D) in gold circles
///   - Correct: forest green border/tint, checkmark
///   - Wrong: muted red border, correct highlighted green
/// - Explanation revealed with smooth animation, forest green left border
class QuestionCard extends StatefulWidget {
  const QuestionCard({super.key, required this.card});

  final CardModel card;

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard>
    with SingleTickerProviderStateMixin {
  int? _selectedIndex;
  bool _answered = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int? get _correctIndex {
    final options = widget.card.answerOptions;
    if (options == null) return null;
    for (int i = 0; i < options.length; i++) {
      if (options[i]['is_correct'] == true) return i;
    }
    return null;
  }

  void _onOptionTap(int index) {
    if (_answered) return;
    setState(() {
      _selectedIndex = index;
      _answered = true;
    });
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.card.answerOptions ?? [];
    final questionText =
        widget.card.questionText ?? widget.card.title;

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
              color: AppColors.question.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.help_outline_rounded,
                  size: 14,
                  color: AppColors.question,
                ),
                const SizedBox(width: 4),
                Text(
                  'Question',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.question,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Question text
          Text(
            questionText,
            style: GoogleFonts.playfairDisplay(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),

          // Answer options
          Expanded(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  for (int i = 0; i < options.length; i++) ...[
                    _AnswerOption(
                      index: i,
                      text: options[i]['text'] as String? ?? '',
                      isSelected: _selectedIndex == i,
                      isCorrect: _correctIndex == i,
                      answered: _answered,
                      onTap: () => _onOptionTap(i),
                    ),
                    if (i < options.length - 1) const SizedBox(height: 10),
                  ],

                  // Explanation (shown after answering)
                  if (_answered &&
                      widget.card.correctAnswerExplanation != null) ...[
                    const SizedBox(height: 20),
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (_selectedIndex == _correctIndex
                                  ? AppColors.success
                                  : AppColors.question)
                              .withOpacity(0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: _selectedIndex == _correctIndex
                                  ? AppColors.success
                                  : AppColors.question,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _selectedIndex == _correctIndex
                                      ? Icons.check_circle_rounded
                                      : Icons.info_rounded,
                                  size: 18,
                                  color: _selectedIndex == _correctIndex
                                      ? AppColors.success
                                      : AppColors.question,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedIndex == _correctIndex
                                      ? 'Correct!'
                                      : 'Not quite',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _selectedIndex == _correctIndex
                                        ? AppColors.success
                                        : AppColors.question,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.card.correctAnswerExplanation!,
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
}

/// A single answer option — elegant bordered container with gold letter circle.
class _AnswerOption extends StatelessWidget {
  final int index;
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool answered;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.index,
    required this.text,
    required this.isSelected,
    required this.isCorrect,
    required this.answered,
    required this.onTap,
  });

  String get _label => String.fromCharCode(65 + index);

  Color get _backgroundColor {
    if (!answered) return Colors.white;
    if (isCorrect) return AppColors.success.withOpacity(0.06);
    if (isSelected) return AppColors.error.withOpacity(0.06);
    return Colors.white;
  }

  Color get _borderColor {
    if (!answered) return AppColors.border;
    if (isCorrect) return AppColors.success.withOpacity(0.5);
    if (isSelected) return AppColors.error.withOpacity(0.5);
    return AppColors.border.withOpacity(0.5);
  }

  Color get _circleColor {
    if (!answered) return AppColors.primary;
    if (isCorrect) return AppColors.success;
    if (isSelected) return AppColors.error;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        child: Row(
          children: [
            // Gold circle letter
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _circleColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: answered && isCorrect
                    ? Icon(Icons.check_rounded,
                        size: 18, color: AppColors.success)
                    : answered && isSelected && !isCorrect
                        ? Icon(Icons.close_rounded,
                            size: 18, color: AppColors.error)
                        : Text(
                            _label,
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _circleColor,
                            ),
                          ),
              ),
            ),
            const SizedBox(width: 12),

            // Option text
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      answered && (isCorrect || isSelected)
                          ? FontWeight.w600
                          : FontWeight.w400,
                  color: answered && !isCorrect && !isSelected
                      ? AppColors.textMuted
                      : AppColors.textPrimary,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
