import 'package:flutter/material.dart';
import '../design_system/typography.dart';
import '../design_system/colors.dart';
import '../design_system/tokens.dart';

/// A reusable animated title widget with easeInQuart curve
class AnimatedTitleWidget extends StatefulWidget {

  const AnimatedTitleWidget({
    super.key,
    required this.text,
    this.style,
    this.duration,
  });
  final String text;
  final TextStyle? style;
  final Duration? duration;

  @override
  State<AnimatedTitleWidget> createState() => _AnimatedTitleWidgetState();
}

class _AnimatedTitleWidgetState extends State<AnimatedTitleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: widget.duration ??
          const Duration(milliseconds: DesignTokens.animationTitle),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInQuart,
    ));

    // Animate on first load
    _startAnimation();
  }

  void _startAnimation() {
    _animationController.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Opacity(
          opacity: _animation.value,
          child: Text(
            widget.text,
            style: widget.style ??
                AppTypography.title1.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                  fontWeight: AppTypography.weightSemiBold,
                ),
          ),
        );
      },
    );
  }

  // Public method to restart animation from outside
  void restartAnimation() {
    _startAnimation();
  }
}
