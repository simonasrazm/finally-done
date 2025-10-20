import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/colors.dart';
import '../design_system/tokens.dart';
import '../models/queued_command.dart';
import '../core/audio/audio_playback_service.dart';
import '../core/commands/command_action_service.dart';

class CommandActionButtons extends ConsumerStatefulWidget {
  const CommandActionButtons({
    super.key,
    required this.command,
    required this.commandStatus,
    required this.commandText,
    required this.transcription,
    required this.audioPath,
    required this.retryingCommands,
    required this.onRetry,
    required this.onEdit,
  });
  final QueuedCommandRealm command;
  final String commandStatus;
  final String commandText;
  final String? transcription;
  final String? audioPath;
  final Set<String> retryingCommands;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

  @override
  ConsumerState<CommandActionButtons> createState() =>
      _CommandActionButtonsState();
}

class _CommandActionButtonsState extends ConsumerState<CommandActionButtons> {
  bool _isAudioPlaying = false;
  StreamSubscription<Map<String, dynamic>>? _audioStateSubscription;

  @override
  void initState() {
    super.initState();
    _updateAudioState();
    _setupAudioStateListener();
  }

  @override
  void didUpdateWidget(CommandActionButtons oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioPath != widget.audioPath) {
      _updateAudioState();
    }
  }

  @override
  void dispose() {
    _audioStateSubscription?.cancel();
    super.dispose();
  }

  void _setupAudioStateListener() {
    _audioStateSubscription = AudioPlaybackService.audioStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isAudioPlaying = widget.audioPath != null &&
              state['currentAudioPath'] == widget.audioPath &&
              state['isPlaying'] == true;
        });
      }
    });
  }

  void _updateAudioState() {
    if (widget.audioPath != null &&
        AudioPlaybackService.currentAudioPath == widget.audioPath) {
      setState(() {
        _isAudioPlaying = AudioPlaybackService.isPlaying;
      });
    } else {
      setState(() {
        _isAudioPlaying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play/Pause button (for audio commands)
        if (widget.audioPath != null && widget.audioPath!.isNotEmpty) ...[
          GestureDetector(
            onTap: () async {
              if (widget.audioPath != null) {
                if (_isAudioPlaying) {
                  await AudioPlaybackService.pauseAudio(context);
                } else {
                  await AudioPlaybackService.playAudio(
                      widget.audioPath!, context);
                }
                _updateAudioState();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                _isAudioPlaying ? Icons.pause : Icons.play_arrow,
                size: DesignTokens.iconSm,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],

        // Retry button (for transcribing + failed commands, processing commands, OR manual review commands)
        if ((widget.command.failed &&
                (widget.commandStatus == 'transcribing' ||
                    widget.commandStatus == 'recorded')) ||
            widget.commandStatus == 'processing' ||
            widget.commandStatus == CommandStatus.manual_review.name) ...[
          GestureDetector(
            onTap: widget.retryingCommands.contains(widget.command.id)
                ? null
                : widget.onRetry,
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: widget.retryingCommands.contains(widget.command.id)
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: widget.retryingCommands.contains(widget.command.id)
                  ? const SizedBox(
                      width: DesignTokens.iconSm,
                      height: DesignTokens.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : const Icon(
                      Icons.refresh_outlined,
                      size: DesignTokens.iconSm,
                      color: AppColors.success,
                    ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],

        // Manual review action buttons
        if (widget.commandStatus == CommandStatus.manual_review.name) ...[
          // Approve button
          GestureDetector(
            onTap: () => CommandActionService.approveManualReview(
                widget.command.id, ref, context),
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Icon(
                Icons.check,
                size: DesignTokens.iconSm,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],

        // Edit button (tab-specific logic)
        if (_shouldShowEditButton(widget.command, widget.commandStatus)) ...[
          GestureDetector(
            onTap: widget.onEdit,
            child: Container(
              padding: const EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: DesignTokens.iconSm,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],
      ],
    );
  }

  bool _shouldShowEditButton(QueuedCommandRealm command, String commandStatus) {
    // If command is failed, actionNeeded, or in manual_review, it should always have edit button (Review tab logic)
    if (command.failed ||
        command.actionNeeded ||
        commandStatus == CommandStatus.manual_review.name) {
      return true;
    }

    // For other commands, only show edit button for queued commands
    return commandStatus == 'queued';
  }
}
