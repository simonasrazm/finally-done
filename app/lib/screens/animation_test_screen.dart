import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';

class AnimationTestScreen extends StatefulWidget {
  const AnimationTestScreen({super.key});

  @override
  State<AnimationTestScreen> createState() => _AnimationTestScreenState();
}

class _AnimationTestScreenState extends State<AnimationTestScreen>
    with TickerProviderStateMixin {
  late AnimationController _squashController;
  late Animation<double> _squashAnimation;

  @override
  void initState() {
    super.initState();

    // Squash & Stretch animation
    _squashController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _squashAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _squashController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _squashController.dispose();
    super.dispose();
  }

  void _triggerSquash() {
    _playSquashSound();
    unawaited(_squashController.forward().then((_) {
      unawaited(_squashController.reverse());
    }));
  }

  void _playSquashSound() {
    unawaited(HapticFeedback.lightImpact());
    unawaited(_playSoundPattern([200, 150, 200])); // Short-short-short pattern
  }

  Future<void> _playSoundPattern(List<int> delays) async {
    for (int delay in delays) {
      SystemSound.play(SystemSoundType.click);
      await Future.delayed(Duration(milliseconds: delay));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Animation Test'),
        backgroundColor: AppColors.getBackgroundColor(context),
        foregroundColor: AppColors.getTextPrimaryColor(context),
      ),
      backgroundColor: AppColors.getBackgroundColor(context),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tap the task to test the squash & stretch effect:',
              style: AppTypography.title2.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 20),

            // Test task item with squash animation
            GestureDetector(
              onTap: _triggerSquash,
              child: AnimatedBuilder(
                animation: _squashAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _squashAnimation.value,
                    child: child,
                  );
                },
                child: _buildTaskItem(),
              ),
            ),

            const SizedBox(height: 30),

            Text(
              'This is the effect that will be used for task completion in the "All Tasks" list.',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Features:',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextPrimaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '• Quick squash down, then bounce back (150ms)',
              style: AppTypography.subhead.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            Text(
              '• Light haptic feedback',
              style: AppTypography.subhead.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            Text(
              '• Short-short-short sound pattern',
              style: AppTypography.subhead.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
            Text(
              '• No layout changes - won\'t block adjacent tasks',
              style: AppTypography.subhead.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getBackgroundColor(context),
        border: Border.all(
          color:
              AppColors.getTextSecondaryColor(context).withValues(alpha: 0.3),
          width: DesignTokens.borderWidthMedium,
        ),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
      ),
      child: Row(
        children: [
          Container(
            width: DesignTokens.checkboxSize,
            height: DesignTokens.checkboxSize,
            decoration: BoxDecoration(
              color: AppColors.transparent,
              border: Border.all(
                color: AppColors.getTextSecondaryColor(context),
                width: DesignTokens.borderWidthMedium,
              ),
              borderRadius:
                  BorderRadius.circular(DesignTokens.borderRadiusSmall),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Complete this task (tap to test)',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextPrimaryColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
