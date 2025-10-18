import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Review Commands Filtering Tests', () {
    // Test the filtering logic directly without Realm initialization
    List<QueuedCommandRealm> _filterReviewCommands(List<QueuedCommandRealm> commands) {
      return commands.where((cmd) => 
          cmd.failed || 
          cmd.actionNeeded || 
          cmd.status == CommandStatus.manual_review.name
      ).toList();
    }

    test('reviewCommands should include failed commands', () {
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
      ];

      final reviewCommands = _filterReviewCommands(commands);

      expect(reviewCommands.length, 2);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isFalse);
    });

    test('reviewCommands should include actionNeeded commands', () {
      final commands = [
        QueuedCommandRealm(
          '1',
          'Action needed command 1',
          CommandStatus.queued.name,
          DateTime.now(),
          actionNeeded: true,
        ),
        QueuedCommandRealm(
          '2',
          'Action needed command 2',
          CommandStatus.processing.name,
          DateTime.now(),
          actionNeeded: true,
        ),
        QueuedCommandRealm(
          '3',
          'Regular command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
      ];

      final reviewCommands = _filterReviewCommands(commands);

      expect(reviewCommands.length, 2);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isFalse);
    });

    test('reviewCommands should include manual_review commands', () {
      final commands = [
        QueuedCommandRealm(
          '1',
          'Manual review command 1',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio1.mp3',
        ),
        QueuedCommandRealm(
          '2',
          'Manual review command 2',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio2.mp3',
        ),
        QueuedCommandRealm(
          '3',
          'Regular command',
          CommandStatus.queued.name,
          DateTime.now(),
        ),
      ];

      final reviewCommands = _filterReviewCommands(commands);

      expect(reviewCommands.length, 2);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isFalse);
    });

    test('reviewCommands should include all types of review commands', () {
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
        QueuedCommandRealm(
          '6',
          'Completed command',
          CommandStatus.completed.name,
          DateTime.now(),
        ),
      ];

      final reviewCommands = _filterReviewCommands(commands);

      expect(reviewCommands.length, 3);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue); // failed
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue); // actionNeeded
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isTrue); // manual_review
      expect(reviewCommands.any((cmd) => cmd.id == '4'), isFalse); // regular queued
      expect(reviewCommands.any((cmd) => cmd.id == '5'), isFalse); // processing
      expect(reviewCommands.any((cmd) => cmd.id == '6'), isFalse); // completed
    });

    test('reviewCommands should handle mixed states correctly', () {
      final commands = [
        QueuedCommandRealm(
          '1',
          'Failed + Action needed',
          CommandStatus.queued.name,
          DateTime.now(),
          failed: true,
          actionNeeded: true,
        ),
        QueuedCommandRealm(
          '2',
          'Failed + Manual review',
          CommandStatus.manual_review.name,
          DateTime.now(),
          failed: true,
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '3',
          'Action needed + Manual review',
          CommandStatus.manual_review.name,
          DateTime.now(),
          actionNeeded: true,
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '4',
          'All three flags',
          CommandStatus.manual_review.name,
          DateTime.now(),
          failed: true,
          actionNeeded: true,
          audioPath: '/path/to/audio.mp3',
        ),
        QueuedCommandRealm(
          '5',
          'Clean manual review',
          CommandStatus.manual_review.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
        ),
      ];

      final reviewCommands = _filterReviewCommands(commands);

      // All commands should be included since they all have at least one review flag
      expect(reviewCommands.length, 5);
      expect(reviewCommands.any((cmd) => cmd.id == '1'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '2'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '3'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '4'), isTrue);
      expect(reviewCommands.any((cmd) => cmd.id == '5'), isTrue);
    });
  });
}
