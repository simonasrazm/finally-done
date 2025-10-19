import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

void main() {
  runApp(const AnimationTesterApp());
}

class AnimationTesterApp extends StatelessWidget {
  const AnimationTesterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Animation Tester',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2A2A2A),
          foregroundColor: Colors.white,
        ),
      ),
      home: const AnimationTesterScreen(),
    );
  }
}

class AnimationTesterScreen extends StatefulWidget {
  const AnimationTesterScreen({super.key});

  @override
  State<AnimationTesterScreen> createState() => _AnimationTesterScreenState();
}

class _AnimationTesterScreenState extends State<AnimationTesterScreen>
    with TickerProviderStateMixin {
  late AnimationController _squashController;
  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late AnimationController _checkmarkController;

  late Animation<double> _squashAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _checkmarkAnimation;

  // Sound effects using system sounds and visual feedback
  int _soundCounter = 0;

  @override
  void initState() {
    super.initState();

    // Squash & Stretch
    _squashController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _squashAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _squashController, curve: Curves.easeInOut),
    );

    // Shimmer
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Checkmark
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkmarkAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _checkmarkController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _squashController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    _checkmarkController.dispose();
    super.dispose();
  }

  void _triggerSquash() {
    _playSquashSound();
    _squashController.forward().then((_) {
      _squashController.reverse();
    });
  }

  void _triggerShimmer() {
    _playShimmerSound();
    _shimmerController.forward().then((_) {
      _shimmerController.reverse();
    });
  }

  void _triggerPulse() {
    _playPulseSound();
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  void _triggerCheckmark() {
    _playCheckmarkSound();
    _checkmarkController.reset();
    _checkmarkController.forward();
  }

  // Sound effect methods with visual feedback for web
  void _playSquashSound() {
    HapticFeedback.lightImpact();
    _playSoundPattern([200, 150, 200]); // Short-short-short
    _showSoundFeedback('SQUASH!', Colors.orange);
  }

  void _playShimmerSound() {
    HapticFeedback.mediumImpact();
    _playSoundPattern([300, 100, 300, 100, 300]); // Long-short-long-short-long
    _showSoundFeedback('SHIMMER!', Colors.purple);
  }

  void _playPulseSound() {
    HapticFeedback.heavyImpact();
    _playSoundPattern([400, 200, 400]); // Long-short-long
    _showSoundFeedback('PULSE!', Colors.green);
  }

  void _playCheckmarkSound() {
    HapticFeedback.heavyImpact();
    _playSoundPattern(
        [100, 100, 100, 100, 100, 100, 100, 100, 100, 100]); // Rapid clicks
    _showSoundFeedback('SUCCESS!', Colors.red);
  }

  void _playSoundPattern(List<int> delays) async {
    for (int delay in delays) {
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  void _showSoundFeedback(String text, Color color) {
    _soundCounter++;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$text (Sound #$_soundCounter)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        duration: const Duration(milliseconds: 500),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Tester'),
        backgroundColor: const Color(0xFF2A2A2A),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tap each item to test the animation:',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: Sounds work on mobile devices. On web, you\'ll see visual feedback instead.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Squash & Stretch
            _buildTestItem(
              '1. Squash & Stretch',
              'Quick squash down, then bounce back + Light haptic + Short-short-short sound pattern',
              Colors.orange,
              _triggerSquash,
              AnimatedBuilder(
                animation: _squashAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _squashAnimation.value,
                    child: child,
                  );
                },
                child: _buildTaskItem('Complete this task', Colors.orange),
              ),
            ),

            const SizedBox(height: 20),

            // Shimmer
            _buildTestItem(
              '2. Shimmer Effect',
              'Brightness flash across the item + Medium haptic + Long-short-long-short-long pattern',
              Colors.purple,
              _triggerShimmer,
              AnimatedBuilder(
                animation: _shimmerAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.purple.withOpacity(0.3),
                          Colors.white
                              .withOpacity(0.8 * _shimmerAnimation.value),
                          Colors.purple.withOpacity(0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                    child: _buildTaskItem('Complete this task', Colors.purple),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Pulse
            _buildTestItem(
              '3. Pulse Effect',
              'Quick opacity pulse + Heavy haptic + Long-short-long pattern',
              Colors.green,
              _triggerPulse,
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: _buildTaskItem('Complete this task', Colors.green),
              ),
            ),

            const SizedBox(height: 20),

            // Checkmark Explosion
            _buildTestItem(
              '4. Checkmark Explosion',
              'Checkmark scales up briefly + Heavy haptic + Rapid click pattern (10 clicks)',
              Colors.red,
              _triggerCheckmark,
              Stack(
                children: [
                  _buildTaskItem('Complete this task', Colors.red),
                  AnimatedBuilder(
                    animation: _checkmarkAnimation,
                    builder: (context, child) {
                      return Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Transform.scale(
                            scale: _checkmarkAnimation.value * 1.5,
                            child: Opacity(
                              opacity: _checkmarkAnimation.value,
                              child: const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestItem(
    String title,
    String description,
    Color color,
    VoidCallback onTap,
    Widget animatedChild,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
          child: animatedChild,
        ),
      ],
    );
  }

  Widget _buildTaskItem(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.transparent,
              border: Border.all(color: color, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
