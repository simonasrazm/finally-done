import '../models/queued_command.dart';

class CommandUIService {
  /// Safely extracts command properties to avoid Realm invalidation errors
  static CommandProperties extractCommandProperties(QueuedCommandRealm command) {
    try {
      return CommandProperties(
        text: command.text,
        status: command.status,
        audioPath: command.audioPath,
        transcription: command.transcription,
        createdAt: command.createdAt,
        photoPaths: List<String>.from(command.photoPaths),
        failed: command.failed,
        actionNeeded: command.actionNeeded,
        errorMessage: command.errorMessage,
        isValid: true,
      );
    } catch (e) {
      return CommandProperties.invalid();
    }
  }

  /// Determines if edit button should be shown based on command state and tab context
  static bool shouldShowEditButton(
    QueuedCommandRealm command, 
    String commandStatus, 
    int currentTabIndex,
  ) {
    // If command is failed, actionNeeded, or in manual_review, it should always have edit button (Review tab logic)
    if (command.failed || command.actionNeeded || commandStatus == CommandStatus.manual_review.name) {
      return true;
    }
    
    // For other commands, check tab context
    switch (currentTabIndex) {
      case 0: // Processing tab
        // Only show edit button for queued commands
        return commandStatus == 'queued';
      case 1: // Completed tab
        // No edit button for completed commands
        return false;
      case 2: // Review tab
        // This should not happen since failed/actionNeeded/manual_review is handled above
        return false;
      default:
        return false;
    }
  }
}

class CommandProperties {
  final String text;
  final String status;
  final String? audioPath;
  final String? transcription;
  final DateTime createdAt;
  final List<String> photoPaths;
  final bool failed;
  final bool actionNeeded;
  final String? errorMessage;
  final bool isValid;

  CommandProperties({
    required this.text,
    required this.status,
    required this.audioPath,
    required this.transcription,
    required this.createdAt,
    required this.photoPaths,
    required this.failed,
    required this.actionNeeded,
    required this.errorMessage,
    required this.isValid,
  });

  factory CommandProperties.invalid() {
    return CommandProperties(
      text: '',
      status: '',
      audioPath: null,
      transcription: null,
      createdAt: DateTime.now(),
      photoPaths: [],
      failed: false,
      actionNeeded: false,
      errorMessage: null,
      isValid: false,
    );
  }
}
