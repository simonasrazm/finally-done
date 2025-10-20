import 'package:flutter/material.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/haptic_service.dart';
import '../services/audio_service.dart';

class SoundTestScreen extends StatefulWidget {
  const SoundTestScreen({super.key});

  @override
  State<SoundTestScreen> createState() => _SoundTestScreenState();
}

class _SoundTestScreenState extends State<SoundTestScreen> {
  int _soundCounter = 0;

  void _playOriginalMagicSweep() async {
    HapticService.lightImpact();
    await AudioService.playAudioFile('audio/magic-astral-sweep.aac');
    _showFeedback('ORIGINAL MAGIC SWEEP (4s)', AppColors.primary);
  }

  void _play1SecondMagicSweep() async {
    HapticService.lightImpact();
    await AudioService.playAudioFile('audio/magic-astral-sweep-1s.aac');
    _showFeedback('DEFAULT 1s MAGIC SWEEP', AppColors.secondary);
  }

  void _play1Second150msMagicSweep() async {
    HapticService.lightImpact();
    await AudioService.playAudioFile('audio/magic-astral-sweep-1s-150ms.aac');
    _showFeedback('1s +150ms MAGIC SWEEP', AppColors.secondary);
  }

  void _testAudioState() async {
    HapticService.lightImpact();

    // Test current audio state
    final bool isSoundEnabled = await HapticService.isSoundEnabled;
    final bool isHapticEnabled = HapticService.isHapticEnabled;

    _showFeedback('Audio State: Sound=$isSoundEnabled, Haptic=$isHapticEnabled',
        AppColors.error);
  }

  void _showFeedback(String name, Color color) {
    _soundCounter++;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$name (Sound #$_soundCounter)',
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sound Test'),
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
              'Tap each button to test different sound patterns:',
              style: AppTypography.title2.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildSoundButton(
                    'Original (4s)',
                    'Full magic astral sweep - original length',
                    AppColors.primary,
                    _playOriginalMagicSweep,
                  ),
                  _buildSoundButton(
                    'Default (1s)',
                    '1s magic sweep with fade-in/out - perfect for instant feedback',
                    AppColors.secondary,
                    _play1SecondMagicSweep,
                  ),
                  _buildSoundButton(
                    '1s +150ms',
                    '1s starting at 150ms offset',
                    AppColors.secondary,
                    _play1Second150msMagicSweep,
                  ),
                  _buildSoundButton(
                    'Test Audio State',
                    'Check current device audio state',
                    AppColors.error,
                    _testAudioState,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Total sounds played: $_soundCounter',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextSecondaryColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundButton(
    String title,
    String description,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(DesignTokens.borderRadiusSmall),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.volume_up,
                color: color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: AppTypography.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTypography.subhead.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
