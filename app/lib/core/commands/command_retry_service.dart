import 'package:finally_done/models/queued_command.dart';

/// Service for handling command retry logic
/// Separated from UI to enable unit testing
class CommandRetryService {
  /// Determines the next status after retrying a command
  /// 
  /// Returns a [RetryResult] containing the new status and whether to clear errors
  static RetryResult determineRetryAction(String currentStatus, bool hasError) {
    switch (currentStatus) {
      case 'processing':
        // Processing commands reset to queued for retry
        return RetryResult(
          newStatus: CommandStatus.queued.name,
          clearError: true,
          clearErrorMessage: true,
        );
        
      case 'transcribing':
        if (hasError) {
          // Failed transcribing commands stay in transcribing but clear error
          return RetryResult(
            newStatus: CommandStatus.transcribing.name,
            clearError: true,
            clearErrorMessage: true,
          );
        } else {
          // Regular transcribing commands stay as is
          return RetryResult(
            newStatus: CommandStatus.transcribing.name,
            clearError: false,
            clearErrorMessage: false,
          );
        }
        
      case 'manual_review':
        // Manual review commands stay in manual_review (don't change status)
        return RetryResult(
          newStatus: CommandStatus.manual_review.name,
          clearError: true,
          clearErrorMessage: true,
        );
        
      default:
        // Unknown status - don't change anything
        return RetryResult(
          newStatus: currentStatus,
          clearError: false,
          clearErrorMessage: false,
        );
    }
  }

  /// Determines if a command can be retried
  static bool canRetryCommand(String status, bool hasError) {
    switch (status) {
      case 'processing':
        return true; // Can always retry processing commands
        
      case 'transcribing':
        return hasError; // Can only retry if there was an error
        
      case 'manual_review':
        return true; // Can always retry manual review commands
        
      case 'completed':
        return false; // Cannot retry completed commands
        
      case 'queued':
        return false; // Cannot retry queued commands (they're waiting)
        
      default:
        return false; // Unknown status - cannot retry
    }
  }

  /// Determines the next status after successful transcription
  static String getStatusAfterTranscription(String currentStatus) {
    switch (currentStatus) {
      case 'transcribing':
        return CommandStatus.manual_review.name; // Move to manual review
        
      case 'manual_review':
        return CommandStatus.manual_review.name; // Stay in manual review
        
      default:
        return currentStatus; // Don't change unknown statuses
    }
  }

  /// Determines if a command needs manual review after transcription
  static bool needsManualReviewAfterTranscription(String currentStatus) {
    // All voice commands (transcribing) go to manual review
    // Manual review commands stay in manual review
    return currentStatus == 'transcribing' || currentStatus == 'manual_review';
  }
}

/// Result of a retry action
class RetryResult {

  const RetryResult({
    required this.newStatus,
    required this.clearError,
    required this.clearErrorMessage,
  });
  final String newStatus;
  final bool clearError;
  final bool clearErrorMessage;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RetryResult &&
        other.newStatus == newStatus &&
        other.clearError == clearError &&
        other.clearErrorMessage == clearErrorMessage;
  }

  @override
  int get hashCode {
    return newStatus.hashCode ^ clearError.hashCode ^ clearErrorMessage.hashCode;
  }

  @override
  String toString() {
    return 'RetryResult(newStatus: $newStatus, clearError: $clearError, clearErrorMessage: $clearErrorMessage)';
  }
}
