import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';

/// A thin animated progress bar shown at the top of the edition screen.
///
/// Displays the fraction of cards completed as a filled width that
/// animates smoothly when [currentIndex] changes.
class CardProgressBar extends StatelessWidget {
  const CardProgressBar({
    super.key,
    required this.currentIndex,
    required this.totalCards,
    this.height = 3.0,
    this.color,
    this.backgroundColor,
  });

  /// Zero-based index of the card currently being viewed.
  final int currentIndex;

  /// Total number of cards in the edition.
  final int totalCards;

  /// Bar thickness in logical pixels.
  final double height;

  /// Fill colour (defaults to [AppColors.primary]).
  final Color? color;

  /// Track colour behind the fill.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final fraction =
        totalCards > 0 ? (currentIndex + 1) / totalCards : 0.0;

    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Stack(
          children: [
            // Track
            Container(
              color: backgroundColor ?? Colors.grey.shade200,
            ),
            // Fill
            AnimatedFractionallySizedBox(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              widthFactor: fraction.clamp(0.0, 1.0),
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: color ?? AppColors.primary,
                  borderRadius: BorderRadius.circular(height / 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A [FractionallySizedBox] whose [widthFactor] animates smoothly.
class AnimatedFractionallySizedBox extends ImplicitlyAnimatedWidget {
  const AnimatedFractionallySizedBox({
    super.key,
    required super.duration,
    super.curve,
    required this.widthFactor,
    this.alignment = Alignment.center,
    this.child,
  });

  final double widthFactor;
  final AlignmentGeometry alignment;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<AnimatedFractionallySizedBox> createState() =>
      _AnimatedFractionallySizedBoxState();
}

class _AnimatedFractionallySizedBoxState
    extends AnimatedWidgetBaseState<AnimatedFractionallySizedBox> {
  Tween<double>? _widthFactor;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _widthFactor = visitor(
      _widthFactor,
      widget.widthFactor,
      (dynamic value) => Tween<double>(begin: value as double),
    ) as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: _widthFactor?.evaluate(animation) ?? widget.widthFactor,
      alignment: widget.alignment,
      child: widget.child,
    );
  }
}
