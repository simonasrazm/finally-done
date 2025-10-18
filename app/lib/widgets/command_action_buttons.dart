import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/colors.dart';
import '../design_system/tokens.dart';
import '../models/queued_command.dart';
import '../core/audio/audio_playback_service.dart';
import '../core/commands/command_action_service.dart';
import '../generated/app_localizations.dart';

class CommandActionButtons extends ConsumerWidget {
  final QueuedCommandRealm command;
  final String commandStatus;
  final String commandText;
  final String? transcription;
  final String? audioPath;
  final Set<String> retryingCommands;
  final VoidCallback onRetry;
  final VoidCallback onEdit;

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Play button (for audio commands)
        if (audioPath != null && audioPath!.isNotEmpty) ...[
          GestureDetector(
            onTap: () {
              if (audioPath != null) {
                AudioPlaybackService.playAudio(audioPath!, context);
              }
            },
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                Icons.play_arrow,
                size: DesignTokens.iconSm,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],
        
        // Retry button (for transcribing + failed commands, processing commands, OR manual review commands)
        if ((command.failed && (commandStatus == 'transcribing' || commandStatus == 'recorded')) || 
commandStatus == 'processing' || 
            commandStatus == CommandStatus.manual_review.name) ...[
          GestureDetector(
            onTap: retryingCommands.contains(command.id) 
                ? null 
                : onRetry,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: retryingCommands.contains(command.id)
                    ? AppColors.primary.withOpacity(0.1)
                    : AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: retryingCommands.contains(command.id)
                  ? SizedBox(
                      width: DesignTokens.iconSm,
                      height: DesignTokens.iconSm,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    )
                  : Icon(
                      Icons.refresh_outlined,
                      size: DesignTokens.iconSm,
                      color: AppColors.success,
                    ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],
        
        // Manual review action buttons
        if (commandStatus == CommandStatus.manual_review.name) ...[
          // Approve button
          GestureDetector(
            onTap: () => CommandActionService.approveManualReview(command.id, ref, context),
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
                Icons.check,
                size: DesignTokens.iconSm,
                color: AppColors.success,
              ),
            ),
          ),
          const SizedBox(width: DesignTokens.spacing2),
        ],
        
        // Edit button (tab-specific logic)
        if (_shouldShowEditButton(command, commandStatus)) ...[
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: EdgeInsets.all(DesignTokens.spacing1),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
              ),
              child: Icon(
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
    if (command.failed || command.actionNeeded || commandStatus == CommandStatus.manual_review.name) {
      return true;
    }
    
    // For other commands, only show edit button for queued commands
    return commandStatus == 'queued';
  }
}
