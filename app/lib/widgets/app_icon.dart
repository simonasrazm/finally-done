import 'package:flutter/material.dart';

class FinallyDoneIcon extends StatelessWidget {
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;

  const FinallyDoneIcon({
    Key? key,
    this.size = 64.0,
    this.backgroundColor,
    this.iconColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: backgroundColor != null 
            ? [backgroundColor!, backgroundColor!]
            : [const Color(0xFF00C851), const Color(0xFF00A86B)],
        ),
        borderRadius: BorderRadius.circular(size * 0.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Voice waves (sound waves)
          Positioned(
            left: size * 0.15,
            top: size * 0.2,
            child: _buildVoiceWaves(size * 0.3),
          ),
          
          // Task list
          Positioned(
            right: size * 0.15,
            top: size * 0.25,
            child: _buildTaskList(size * 0.25),
          ),
          
          // Checkmark (completion indicator)
          Positioned(
            right: size * 0.1,
            bottom: size * 0.1,
            child: Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check,
                color: const Color(0xFF00C851),
                size: size * 0.12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceWaves(double waveSize) {
    return SizedBox(
      width: waveSize,
      height: waveSize,
      child: CustomPaint(
        painter: VoiceWavesPainter(
          color: iconColor ?? Colors.white,
        ),
      ),
    );
  }

  Widget _buildTaskList(double listSize) {
    return Container(
      width: listSize,
      height: listSize * 1.2,
      decoration: BoxDecoration(
        color: iconColor ?? Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            width: listSize * 0.6,
            height: 2,
            color: const Color(0xFF00C851),
          ),
          Container(
            width: listSize * 0.8,
            height: 2,
            color: const Color(0xFF00C851),
          ),
          Container(
            width: listSize * 0.4,
            height: 2,
            color: const Color(0xFF00C851),
          ),
        ],
      ),
    );
  }
}

class VoiceWavesPainter extends CustomPainter {
  final Color color;

  VoiceWavesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width * 0.5, size.height * 0.5);
    
    // Draw concentric arcs representing sound waves
    for (int i = 0; i < 3; i++) {
      final radius = (size.width * 0.2) + (i * size.width * 0.15);
      final rect = Rect.fromCircle(center: center, radius: radius);
      
      // Draw arc from top-left to bottom-right
      canvas.drawArc(
        rect,
        -1.57, // -90 degrees
        3.14,  // 180 degrees
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
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const Concept1Icon({
    Key? key,
    this.size = 64.0,
    this.backgroundColor = const Color(0xFF007AFF),
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: backgroundColor,
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
  final double size;
  final Color backgroundColor;
  final Color accentColor;

  const Concept2Icon({
    Key? key,
    this.size = 64.0,
    this.backgroundColor = Colors.white,
    this.accentColor = const Color(0xFF34C759),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: size * 0.05,
            offset: Offset(0, size * 0.02),
          ),
        ],
      ),
      child: CustomPaint(
        painter: CheckmarkWithWavesPainter(
          accentColor: accentColor,
          size: size,
        ),
      ),
    );
  }
}

class CheckmarkWithWavesPainter extends CustomPainter {
  final Color accentColor;
  final double size;

  CheckmarkWithWavesPainter({
    required this.accentColor,
    required this.size,
  });

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
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final heartSize = size * 0.12;
    final heartCenter = Offset(center.dx - heartSize * 0.3, center.dy - heartSize * 0.2);
    
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
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.025
      ..strokeCap = StrokeCap.round;
    
    // Upper waves (from top-left of hearts)
    final upperWaveStart = Offset(heartCenter.dx - heartSize * 0.4, heartCenter.dy - heartSize * 0.3);
    for (int i = 0; i < 3; i++) {
      final waveRadius = size * 0.08 + (i * size * 0.06);
      final waveCenter = Offset(upperWaveStart.dx - waveRadius * 0.3, upperWaveStart.dy - waveRadius * 0.2);
      final rect = Rect.fromCircle(center: waveCenter, radius: waveRadius);
      
      canvas.drawArc(
        rect,
        -0.5, // Start angle
        1.0,  // Sweep angle
        false,
        wavePaint,
      );
    }
    
    // Lower waves (from bottom-right of hearts)
    final lowerWaveStart = Offset(heartCenter.dx + heartSize * 0.4, heartCenter.dy + heartSize * 0.3);
    for (int i = 0; i < 3; i++) {
      final waveRadius = size * 0.08 + (i * size * 0.06);
      final waveCenter = Offset(lowerWaveStart.dx + waveRadius * 0.3, lowerWaveStart.dy + waveRadius * 0.2);
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
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const Concept3Icon({
    Key? key,
    this.size = 64.0,
    this.backgroundColor = const Color(0xFF5856D6),
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withOpacity(0.8)],
        ),
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              color: Colors.yellow,
            ),
          ),
          // Checkmark
          Positioned(
            bottom: size * 0.15,
            left: size * 0.15,
            child: Icon(
              Icons.task_alt,
              size: size * 0.25,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

class Concept4Icon extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color iconColor;

  const Concept4Icon({
    Key? key,
    this.size = 64.0,
    this.backgroundColor = const Color(0xFFFF9500),
    this.iconColor = Colors.white,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.mic,
                size: size * 0.08,
                color: Colors.white,
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
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}

// App icon variants for different sizes
class AppIconVariants {
  static Widget small() => const FinallyDoneIcon(size: 32.0);
  static Widget medium() => const FinallyDoneIcon(size: 64.0);
  static Widget large() => const FinallyDoneIcon(size: 128.0);
  static Widget xlarge() => const FinallyDoneIcon(size: 256.0);
  
  // Alternative color schemes
  static Widget blue() => FinallyDoneIcon(
    size: 64.0,
    backgroundColor: const Color(0xFF4A90E2),
  );
  
  static Widget purple() => FinallyDoneIcon(
    size: 64.0,
    backgroundColor: const Color(0xFF9C27B0),
  );
  
  static Widget orange() => FinallyDoneIcon(
    size: 64.0,
    backgroundColor: const Color(0xFFFF6B35),
  );
}
