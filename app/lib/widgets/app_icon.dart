import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/tokens.dart';

class FinallyDoneIcon extends StatelessWidget {
  const FinallyDoneIcon({
    super.key,
    this.size = DesignTokens.iconXl,
    this.backgroundColor,
    this.iconColor,
  });
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color accentColor = iconColor ?? scheme.secondary;
    final Color onAccentColor = scheme.onSecondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColor != null
              ? [backgroundColor!, backgroundColor!]
              : [
                  accentColor,
                  accentColor.withValues(alpha: DesignTokens.opacity80)
                ],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.textPrimary.withValues(alpha: DesignTokens.opacity20),
            blurRadius: DesignTokens.spacing2,
            offset: const Offset(0, DesignTokens.spacing1),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Voice waves (sound waves)
          Positioned(
            left: size * 0.15,
            top: size * 0.2,
            child: _buildVoiceWaves(size * 0.3, onAccentColor),
          ),

          // Task list
          Positioned(
            right: size * 0.15,
            top: size * 0.25,
            child: _buildTaskList(size * 0.25, accentColor, onAccentColor),
          ),

          // Checkmark (completion indicator)
          Positioned(
            right: size * 0.1,
            bottom: size * 0.1,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: onAccentColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary
                        .withValues(alpha: DesignTokens.opacity10),
                    blurRadius: DesignTokens.spacing1,
                    offset: const Offset(0, DesignTokens.spacing2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                color: accentColor,
                size: size * 0.12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWaves(double waveSize, Color waveColor) {
    return SizedBox(
      width: waveSize,
      height: waveSize,
      child: CustomPaint(
        painter: VoiceWavesPainter(
          color: waveColor,
        ),
      ),
    );
  }

  Widget _buildTaskList(double listSize, Color lineColor, Color background) {
    return Container(
      width: listSize,
      height: listSize * 1.2,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: listSize * 0.6,
            height: DesignTokens.borderWidth2,
            color: lineColor,
          ),
          Container(
            width: listSize * 0.8,
            height: DesignTokens.borderWidth2,
            color: lineColor,
          ),
          Container(
            width: listSize * 0.4,
            height: DesignTokens.borderWidth2,
            color: lineColor,
          ),
        ],
      ),
    );
  }
}

class VoiceWavesPainter extends CustomPainter {
  VoiceWavesPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = DesignTokens.borderWidth2;

    final center = Offset(size.width * 0.5, size.height * 0.5);

    // Draw concentric arcs representing sound waves
    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.2) + (i * size.width * 0.15);
      final rect = Rect.fromCircle(center: center, radius: radius);

      // Draw arc from top-left to bottom-right
      canvas.drawArc(
        rect,
        -1.57, // -90 degrees
        3.14, // 180 degrees
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Alternative icon concepts
class Concept1Icon extends StatelessWidget {
  const Concept1Icon({
    super.key,
    this.size = DesignTokens.iconXl,
    this.backgroundColor,
    this.iconColor,
  });
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? scheme.primary;
    final iconColor = this.iconColor ?? scheme.onPrimary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.textPrimary.withValues(alpha: DesignTokens.opacity20),
            blurRadius: size * 0.05,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Microphone icon
          Icon(
            Icons.mic,
            size: size * 0.5,
            color: iconColor,
          ),
          // Checkmark overlay
          Positioned(
            bottom: size * 0.15,
            right: size * 0.15,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: const BoxDecoration(
                color: AppColors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: bgColor,
                size: size * 0.15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Concept2Icon extends StatelessWidget {
  const Concept2Icon({
    super.key,
    this.size = DesignTokens.iconXl,
    this.backgroundColor,
    this.accentColor,
  });
  final double size;
  final Color? backgroundColor;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? scheme.surface;
    final accent = accentColor ?? scheme.secondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.textPrimary.withValues(alpha: DesignTokens.opacity10),
            blurRadius: size * 0.05,
            offset: Offset(0, size * 0.02),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CheckmarkWithWavesPainter(
          accentColor: accent,
          onAccentColor: scheme.onSecondary,
          size: size,
        ),
      ),
    );
  }
}

class CheckmarkWithWavesPainter extends CustomPainter {
  CheckmarkWithWavesPainter({
    required this.accentColor,
    required this.onAccentColor,
    required this.size,
  });
  final Color accentColor;
  final Color onAccentColor;
  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(size / 2, size / 2);
    final circleRadius = size * 0.4;

    // Draw the solid green circle
    final circlePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, circleRadius, circlePaint);

    // Draw the heart-like shapes (two overlapping circles)
    final heartPaint = Paint()
      ..color = onAccentColor
      ..style = PaintingStyle.fill;

    final heartSize = size * 0.12;
    final heartCenter =
        Offset(center.dx - heartSize * 0.3, center.dy - heartSize * 0.2);

    // Left heart shape
    canvas.drawCircle(
      Offset(heartCenter.dx - heartSize * 0.3, heartCenter.dy),
      heartSize * 0.6,
      heartPaint,
    );

    // Right heart shape
    canvas.drawCircle(
      Offset(heartCenter.dx + heartSize * 0.3, heartCenter.dy),
      heartSize * 0.6,
      heartPaint,
    );

    // Bottom part of heart
    final heartBottomPath = Path();
    heartBottomPath.moveTo(heartCenter.dx - heartSize * 0.6, heartCenter.dy);
    heartBottomPath.quadraticBezierTo(
      heartCenter.dx,
      heartCenter.dy + heartSize * 0.8,
      heartCenter.dx + heartSize * 0.6,
      heartCenter.dy,
    );
    heartBottomPath.close();
    canvas.drawPath(heartBottomPath, heartPaint);

    // Draw the signal waves
    final wavePaint = Paint()
      ..color = onAccentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.025
      ..strokeCap = StrokeCap.round;

    // Upper waves (from top-left of hearts)
    final upperWaveStart = Offset(
        heartCenter.dx - heartSize * 0.4, heartCenter.dy - heartSize * 0.3);
    for (int i = 0; i < 3; i++) {
      final waveRadius = size * 0.08 + (i * size * 0.06);
      final waveCenter = Offset(upperWaveStart.dx - waveRadius * 0.3,
          upperWaveStart.dy - waveRadius * 0.2);
      final rect = Rect.fromCircle(center: waveCenter, radius: waveRadius);

      canvas.drawArc(
        rect,
        -0.5, // Start angle
        1.0, // Sweep angle
        false,
        wavePaint,
      );
    }

    // Lower waves (from bottom-right of hearts)
    final lowerWaveStart = Offset(
        heartCenter.dx + heartSize * 0.4, heartCenter.dy + heartSize * 0.3);
    for (int i = 0; i < 3; i++) {
      final waveRadius = size * 0.08 + (i * size * 0.06);
      final waveCenter = Offset(lowerWaveStart.dx + waveRadius * 0.3,
          lowerWaveStart.dy + waveRadius * 0.2);
      final rect = Rect.fromCircle(center: waveCenter, radius: waveRadius);

      canvas.drawArc(
        rect,
        2.0, // Start angle
        1.0, // Sweep angle
        false,
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Concept3Icon extends StatelessWidget {
  const Concept3Icon({
    super.key,
    this.size = DesignTokens.iconXl,
    this.backgroundColor,
    this.iconColor,
  });
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? scheme.secondary;
    final iconColor = this.iconColor ?? scheme.onSecondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bgColor, bgColor.withValues(alpha: DesignTokens.opacity80)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.textPrimary.withValues(alpha: DesignTokens.opacity20),
            blurRadius: size * 0.05,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Speech bubble
          Icon(
            Icons.chat_bubble,
            size: size * 0.6,
            color: iconColor,
          ),
          // AI sparkle
          Positioned(
            top: size * 0.15,
            right: size * 0.15,
            child: Icon(
              Icons.auto_awesome,
              size: size * 0.25,
              color: AppColors.warning,
            ),
          ),
          // Checkmark
          Positioned(
            bottom: size * 0.15,
            left: size * 0.15,
            child: Icon(
              Icons.task_alt,
              size: size * 0.25,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class Concept4Icon extends StatelessWidget {
  const Concept4Icon({
    super.key,
    this.size = DesignTokens.iconXl,
    this.backgroundColor,
    this.iconColor,
  });
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? AppColors.warning;
    final iconColor = this.iconColor ?? scheme.onSecondary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color:
                AppColors.textPrimary.withValues(alpha: DesignTokens.opacity20),
            blurRadius: size * 0.05,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Command center / control panel
          Icon(
            Icons.dashboard,
            size: size * 0.5,
            color: iconColor,
          ),
          // Voice indicator
          Positioned(
            top: size * 0.2,
            right: size * 0.2,
            child: Container(
              width: size * 0.15,
              height: size * 0.15,
              decoration: const BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                size: size * 0.08,
                color: AppColors.white,
              ),
            ),
          ),
          // Success indicator
          Positioned(
            bottom: size * 0.2,
            left: size * 0.2,
            child: Icon(
              Icons.check_circle,
              size: size * 0.2,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// App icon variants for different sizes
class AppIconVariants {
  static Widget small() =>
      const FinallyDoneIcon(size: DesignTokens.touchTargetSize);
  static Widget medium() => const FinallyDoneIcon(size: DesignTokens.iconXl);
  static Widget large() => const FinallyDoneIcon(size: DesignTokens.iconXl * 2);
  static Widget xlarge() =>
      const FinallyDoneIcon(size: DesignTokens.iconXl * 4);

  // Alternative color schemes
  static Widget blue() => const FinallyDoneIcon(
        size: DesignTokens.iconXl,
        backgroundColor: Color(0xFF4A90E2),
      );

  static Widget purple() => const FinallyDoneIcon(
        size: DesignTokens.iconXl,
        backgroundColor: Color(0xFF9C27B0),
      );

  static Widget orange() => const FinallyDoneIcon(
        size: DesignTokens.iconXl,
        backgroundColor: Color(0xFFFF6B35),
      );
}
