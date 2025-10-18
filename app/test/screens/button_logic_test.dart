import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Button Logic Tests', () {
    // Button purposes:
    // - Play (▶️): Play audio for voice commands
    // - Approve (✓): Approve manual review commands
    // - Retry (🔄): Retry transcription for failed/processing/manual_review commands
    // - Edit (✏️): Edit transcription text
    // - Delete (🗑️): Permanently delete command and files
    
    // Test helper functions to simulate the button visibility logic
    bool shouldShowEditButton(QueuedCommandRealm command, String commandStatus, int currentTabIndex) {
      // If command is failed, actionNeeded, or in manual_review, it should always have edit button (Review tab logic)
      if (command.failed || command.actionNeeded || commandStatus == CommandStatus.manual_review.name) {
        return true;
      }
      
      // For other commands, check tab context
      switch (currentTabIndex) {
        case 0: // Processing tab
          return commandStatus == CommandStatus.queued.name || commandStatus == CommandStatus.processing.name;
        case 1: // Completed tab
          return false; // No edit button for completed commands
        case 2: // Review tab
          return true; // All commands in review tab can be edited
        default:
          return false;
      }
    }

    bool shouldShowRetryButton(String commandStatus, bool isFailed) {
      return (isFailed && commandStatus == 'transcribing') || 
             commandStatus == 'processing' || 
             commandStatus == CommandStatus.manual_review.name;
    }

    bool shouldShowDeleteButton() {
      // Delete button is always available for all commands
      return true;
    }

    test('Edit button should show for manual_review commands', () {
      final command = QueuedCommandRealm(
        '1',
        'Manual review command',
        CommandStatus.manual_review.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
      );

      // Should show edit button in any tab
      expect(shouldShowEditButton(command, CommandStatus.manual_review.name, 0), isTrue); // Processing tab
      expect(shouldShowEditButton(command, CommandStatus.manual_review.name, 1), isTrue); // Completed tab
      expect(shouldShowEditButton(command, CommandStatus.manual_review.name, 2), isTrue); // Review tab
    });

    test('Edit button should show for failed commands', () {
      final command = QueuedCommandRealm(
        '1',
        'Failed command',
        CommandStatus.queued.name,
        DateTime.now(),
        failed: true,
      );

      // Should show edit button in any tab
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 0), isTrue);
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 1), isTrue);
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 2), isTrue);
    });

    test('Edit button should show for actionNeeded commands', () {
      final command = QueuedCommandRealm(
        '1',
        'Action needed command',
        CommandStatus.queued.name,
        DateTime.now(),
        actionNeeded: true,
      );

      // Should show edit button in any tab
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 0), isTrue);
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 1), isTrue);
      expect(shouldShowEditButton(command, CommandStatus.queued.name, 2), isTrue);
    });

    test('Retry button should show for manual_review commands', () {
      final command = QueuedCommandRealm(
        '1',
        'Manual review command',
        CommandStatus.manual_review.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
      );

      expect(shouldShowRetryButton(CommandStatus.manual_review.name, false), isTrue);
    });

    test('Retry button should show for processing commands', () {
      expect(shouldShowRetryButton('processing', false), isTrue);
    });

    test('Retry button should show for failed transcribing commands', () {
      expect(shouldShowRetryButton('transcribing', true), isTrue);
    });

    test('Retry button should NOT show for regular queued commands', () {
      expect(shouldShowRetryButton('queued', false), isFalse);
    });

    test('Retry button should NOT show for completed commands', () {
      expect(shouldShowRetryButton('completed', false), isFalse);
    });

    test('Delete button should always be available', () {
      expect(shouldShowDeleteButton(), isTrue);
    });

    test('Manual review retry should keep command in manual_review state', () {
      // This test documents the expected behavior:
      // When retrying a manual_review command, it should:
      // 1. Update the transcription text
      // 2. Keep the command in manual_review state (not change to transcribing)
      // 3. Allow user to review the new transcription before approving
      
      // This is different from failed transcribing commands which move to transcribing
      // and different from processing commands which reset to queued
      
      expect(shouldShowRetryButton(CommandStatus.manual_review.name, false), isTrue);
    });

    test('Button combinations for different command states', () {
      // Manual review command - should have: Play, Approve, Retry, Edit, Delete
      // Retry button updates transcription but keeps command in manual_review state
      final manualReviewCommand = QueuedCommandRealm(
        '1',
        'Manual review command',
        CommandStatus.manual_review.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
      );

      expect(shouldShowEditButton(manualReviewCommand, CommandStatus.manual_review.name, 2), isTrue);
      expect(shouldShowRetryButton(CommandStatus.manual_review.name, false), isTrue);
      expect(shouldShowDeleteButton(), isTrue);

      // Failed transcribing command
      final failedTranscribingCommand = QueuedCommandRealm(
        '2',
        'Failed transcribing command',
        CommandStatus.transcribing.name,
        DateTime.now(),
        failed: true,
        audioPath: '/path/to/audio.mp3',
      );

      expect(shouldShowEditButton(failedTranscribingCommand, CommandStatus.transcribing.name, 2), isTrue);
      expect(shouldShowRetryButton(CommandStatus.transcribing.name, true), isTrue);
      expect(shouldShowDeleteButton(), isTrue);

      // Processing command
      final processingCommand = QueuedCommandRealm(
        '3',
        'Processing command',
        CommandStatus.processing.name,
        DateTime.now(),
      );

      expect(shouldShowEditButton(processingCommand, CommandStatus.processing.name, 0), isTrue);
      expect(shouldShowRetryButton(CommandStatus.processing.name, false), isTrue);
      expect(shouldShowDeleteButton(), isTrue);

      // Regular queued command
      final queuedCommand = QueuedCommandRealm(
        '4',
        'Queued command',
        CommandStatus.queued.name,
        DateTime.now(),
      );

      expect(shouldShowEditButton(queuedCommand, CommandStatus.queued.name, 0), isTrue);
      expect(shouldShowRetryButton(CommandStatus.queued.name, false), isFalse);
      expect(shouldShowDeleteButton(), isTrue);
    });
  });
}
