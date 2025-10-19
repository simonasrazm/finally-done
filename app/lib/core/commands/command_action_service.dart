import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import '../../models/queued_command.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'queue_service.dart';
import '../audio/speech_service.dart';
import 'command_retry_service.dart';
import '../../utils/photo_service.dart';
import 'package:finally_done/design_system/colors.dart';

/// Service for handling command actions (retry, approve, delete)
class CommandActionService {
  /// Retry a command based on its status
  static Future<void> retryCommand(
    String commandId,
    String commandStatus,
    bool hasError,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      // Get the command to retry
      final allCommands = ref.read(queueProvider);
      final command = allCommands.firstWhere((cmd) => cmd.id == commandId);
      
      // Show loading message
      _showSnackBar(context, 'Retrying command...');
      
      if (commandStatus == 'processing') {
        // For processing commands, reset to queued state to retry processing
        ref.read(queueProvider.notifier).updateCommandStatus(commandId, CommandStatus.queued);
        ref.read(queueProvider.notifier).updateCommandFailed(commandId, false);
        ref.read(queueProvider.notifier).updateCommandErrorMessage(commandId, null);
        
        _showSnackBar(context, 'Command reset to queue for retry!', isSuccess: true);
        
      } else if (hasError && commandStatus == 'transcribing') {
        // For failed transcription, retry the transcription
        await _retryTranscription(commandId, command, ref, context);
        
      } else if (commandStatus == CommandStatus.manual_review.name) {
        // For manual review commands, retry the transcription
        await _retryTranscription(commandId, command, ref, context);
      }
      
    } catch (e, stackTrace) {
      // Store technical error for backend analysis, but show user-friendly message in UI
      Sentry.captureException(e, stackTrace: stackTrace);
      ref.read(queueProvider.notifier).updateCommandErrorMessage(commandId, e.toString());
      ref.read(queueProvider.notifier).updateCommandFailed(commandId, true);
      
      _showSnackBar(context, 'Retry failed: ${e.toString()}', isError: true);
    }
  }

  /// Retry transcription for audio commands
  static Future<void> _retryTranscription(
    String commandId,
    QueuedCommandRealm command,
    WidgetRef ref,
    BuildContext context,
  ) async {
    if (command.audioPath == null || command.audioPath!.isEmpty) {
      throw Exception('No audio file found for this command');
    }
    
    // Get full audio path
    final fullAudioPath = await _getFullAudioPath(command.audioPath!);
    
    // Process the specific audio file with Gemini
    final speechService = ref.read(speechServiceProvider);
    String transcription = await speechService.processAudioFile(fullAudioPath);
    
    // Update transcription and status - use retry service to determine correct status
    final retryResult = CommandRetryService.determineRetryAction(command.status, command.failed);
    ref.read(queueProvider.notifier).updateCommandTranscription(commandId, transcription);
    ref.read(queueProvider.notifier).updateCommandStatus(commandId, CommandStatus.values.firstWhere((s) => s.name == retryResult.newStatus));
    
    // Clear error flags based on retry service result
    if (retryResult.clearError) {
      ref.read(queueProvider.notifier).updateCommandFailed(commandId, false);
    }
    if (retryResult.clearErrorMessage) {
      ref.read(queueProvider.notifier).updateCommandErrorMessage(commandId, null);
    }
    
    // Show success message
    final message = command.status == CommandStatus.manual_review.name 
        ? 'Transcription updated! Please review the new result.'
        : 'Transcription retry completed!';
    _showSnackBar(context, message, isSuccess: true);
  }

  /// Approve manual review command
  static Future<void> approveManualReview(
    String commandId,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      // Move from manual_review to transcribing
      ref.read(queueProvider.notifier).updateCommandStatus(commandId, CommandStatus.transcribing);
      
      _showSnackBar(context, 'Audio approved for transcription!', isSuccess: true);
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      _showSnackBar(context, 'Error approving audio: $e', isError: true);
    }
  }

  /// Delete a command and its associated files
  static Future<void> deleteCommand(
    String commandId,
    WidgetRef ref,
    BuildContext context,
  ) async {
    try {
      // Get command data from current state before deletion
      final allCommands = ref.read(queueProvider);
      final command = allCommands.firstWhere((cmd) => cmd.id == commandId);
      
      // Store command data before deletion to avoid Realm invalidation issues
      final audioPath = command.audioPath;
      final photoPaths = List<String>.from(command.photoPaths);
      
      
      // Remove from queue first (this deletes from Realm)
      ref.read(queueProvider.notifier).removeCommand(commandId);
      
      // Delete associated media files after Realm deletion
      if (audioPath != null && audioPath.isNotEmpty) {
        final fullAudioPath = await _getFullAudioPath(audioPath);
        final audioFile = File(fullAudioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
        }
      }
      
      // Delete associated photo files and thumbnails
      await PhotoService.deletePhotos(photoPaths);
      
      _showSnackBar(context, 'Command deleted successfully', isSuccess: true);
      
    } catch (e, stackTrace) {
      Sentry.captureException(e, stackTrace: stackTrace);
      _showSnackBar(context, 'Error deleting command: $e', isError: true);
    }
  }

  /// Get full audio path from filename
  static Future<String> _getFullAudioPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio/$fileName';
  }

  /// Show snackbar message
  static void _showSnackBar(BuildContext context, String message, {bool isError = false, bool isSuccess = false}) {
    Color? backgroundColor;
    if (isError) {
      backgroundColor = AppColors.error;
    } else if (isSuccess) {
      backgroundColor = AppColors.success;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }
}
