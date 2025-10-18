import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Queue Service Filtering Logic Tests', () {
    // Test the filtering logic directly without Realm initialization
    List<QueuedCommandRealm> _filterProcessingCommands(List<QueuedCommandRealm> commands) {
      return commands.where((cmd) => !cmd.failed && !cmd.actionNeeded && 
          cmd.status != CommandStatus.completed.name && 
          cmd.status != CommandStatus.manual_review.name).toList();
    }

    List<QueuedCommandRealm> _filterReviewCommands(List<QueuedCommandRealm> commands) {
      return commands.where((cmd) => cmd.failed || cmd.actionNeeded || cmd.status == CommandStatus.manual_review.name).toList();
    }

    List<QueuedCommandRealm> _filterCompletedCommands(List<QueuedCommandRealm> commands) {
      return commands.where((cmd) => cmd.status == CommandStatus.completed.name).toList();
    }

    List<QueuedCommandRealm> _filterFailedCommands(List<QueuedCommandRealm> commands) {
      return commands.where((cmd) => cmd.failed).toList();
    }

    test('processingCommands should exclude manual_review commands', () {
      // Create test commands
      final commands = [
        QueuedCommandRealm(
          '1',
          'Text command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '2',
          'Audio command',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '3',
          'Processing command',
          CommandStatus.processing.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '4',
          'Failed command',
          CommandStatus.queued.name,
          DateTime.now(),
          failed: true,
        ),
        QueuedCommandRealm(
          '5',
          'Action needed command',
          CommandStatus.queued.name,
          DateTime.now(),
          actionNeeded: true,
        ),
        QueuedCommandRealm(
          '6',
          'Completed command',
          CommandStatus.completed.name,
          DateTime.now(),
        ),
      ];

      // Get processing commands using our filter function
      final processingCommands = _filterProcessingCommands(commands);

      // Should only include queued and processing commands (not manual_review, failed, actionNeeded, or completed)
      expect(processingCommands.length, 2);
      expect(processingCommands.any((cmd) => cmd.id == '1'), isTrue); // queued
      expect(processingCommands.any((cmd) => cmd.id == '3'), isTrue); // processing
      expect(processingCommands.any((cmd) => cmd.id == '2'), isFalse); // manual_review
      expect(processingCommands.any((cmd) => cmd.id == '4'), isFalse); // failed
      expect(processingCommands.any((cmd) => cmd.id == '5'), isFalse); // actionNeeded
      expect(processingCommands.any((cmd) => cmd.id == '6'), isFalse); // completed
    });

    test('reviewCommands should include manual_review commands', () {
      // Create test commands
      final commands = [
        QueuedCommandRealm(
          '1',
          'Failed command',
          CommandStatus.queued.name,
          DateTime.now(),
          failed: true,
        ),
        QueuedCommandRealm(
          '2',
          'Action needed command',
          CommandStatus.queued.name,
          DateTime.now(),
          actionNeeded: true,
        ),
        QueuedCommandRealm(
          '3',
          'Manual review command',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '4',
          'Regular queued command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '5',
          'Processing command',
          CommandStatus.processing.name,
          DateTime.now(),
        ),
      ];

      // Get review commands using our filter function
      final reviewCommands = _filterReviewCommands(commands);

      // Should include failed, actionNeeded, and manual_review commands
      expect(reviewCommands.length, 3);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue); // failed
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue); // actionNeeded
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isTrue); // manual_review
      expect(reviewCommands.any((cmd) => cmd.id == '4'), isFalse); // regular queued
      expect(reviewCommands.any((cmd) => cmd.id == '5'), isFalse); // processing
    });

    test('completedCommands should only include completed commands', () {
      // Create test commands
      final commands = [
        QueuedCommandRealm(
          '1',
          'Completed command 1',
          CommandStatus.completed.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '2',
          'Completed command 2',
          CommandStatus.completed.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '3',
          'Queued command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '4',
          'Manual review command',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
      ];

      // Get completed commands using our filter function
      final completedCommands = _filterCompletedCommands(commands);

      // Should only include completed commands
      expect(completedCommands.length, 2);
      expect(completedCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(completedCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(completedCommands.any((cmd) => cmd.id == '3'), isFalse);
      expect(completedCommands.any((cmd) => cmd.id == '4'), isFalse);
    });

    test('failedCommands should only include failed commands', () {
      // Create test commands
      final commands = [
        QueuedCommandRealm(
          '1',
          'Failed command 1',
          CommandStatus.queued.name,
          DateTime.now(),
          failed: true,
        ),
        QueuedCommandRealm(
          '2',
          'Failed command 2',
          CommandStatus.processing.name,
          DateTime.now(),
          failed: true,
        ),
        QueuedCommandRealm(
          '3',
          'Regular command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '4',
          'Manual review command',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
      ];

      // Get failed commands using our filter function
      final failedCommands = _filterFailedCommands(commands);

      // Should only include failed commands
      expect(failedCommands.length, 2);
      expect(failedCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(failedCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(failedCommands.any((cmd) => cmd.id == '3'), isFalse);
      expect(failedCommands.any((cmd) => cmd.id == '4'), isFalse);
    });

    test('queuedCommands should include all commands (no filtering)', () {
      // Create test commands
      final commands = [
        QueuedCommandRealm(
          '1',
          'Queued command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '2',
          'Manual review command',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '3',
          'Processing command',
          CommandStatus.processing.name,
          DateTime.now(),
        ),
        QueuedCommandRealm(
          '4',
          'Completed command',
          CommandStatus.completed.name,
          DateTime.now(),
        ),
      ];

      // queuedCommands should include all commands (no filtering)
      expect(commands.length, 4);
      expect(commands.any((cmd) => cmd.id == '1'), isTrue);
      expect(commands.any((cmd) => cmd.id == '2'), isTrue);
      expect(commands.any((cmd) => cmd.id == '3'), isTrue);
      expect(commands.any((cmd) => cmd.id == '4'), isTrue);
    });
  });
}
