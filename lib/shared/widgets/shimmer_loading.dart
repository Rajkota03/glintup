import 'package:flutter/material.dart';
import 'package:glintup/core/constants/app_colors.dart';

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      listenable: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(80, 16),
              const SizedBox(height: 16),
              _shimmerBox(double.infinity, 24),
              const SizedBox(height: 12),
              _shimmerBox(double.infinity, 14),
              const SizedBox(height: 8),
              _shimmerBox(double.infinity, 14),
              const SizedBox(height: 8),
              _shimmerBox(200, 14),
              const SizedBox(height: 20),
              _shimmerBox(120, 12),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            AppColors.surfaceAlt,
            Color(0xFFFAFAF8),
            AppColors.surfaceAlt,
          ],
        ),
      ),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext, Widget?) builder;

  const AnimatedBuilder({
    super.key,
    required super.listenable,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return builder(context, null);
  }
}

class ShimmerList extends StatelessWidget {
  final int count;

  const ShimmerList({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      itemBuilder: (context, index) => const ShimmerCard(),
    );
  }
}
