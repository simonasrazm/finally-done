import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Queue Service Tests', () {
    test('CommandStatus enum values', () {
      expect(CommandStatus.recorded.name, 'recorded');
      expect(CommandStatus.transcribing.name, 'transcribing');
      expect(CommandStatus.queued.name, 'queued');
      expect(CommandStatus.processing.name, 'processing');
      expect(CommandStatus.completed.name, 'completed');
      expect(CommandStatus.failed.name, 'failed');
    });
    
    test('QueuedCommandRealm constructor', () {
      final command = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now(),
        audioPath: 'test-audio.m4a',
        photoPaths: ['photo1.jpg', 'photo2.jpg'],
        transcription: 'Test transcription',
        errorMessage: null,
      );
      
      expect(command.id, 'test-id');
      expect(command.text, 'Test command');
      expect(command.status, CommandStatus.queued.name);
      expect(command.audioPath, 'test-audio.m4a');
      expect(command.photoPaths.length, 2);
      expect(command.transcription, 'Test transcription');
      expect(command.errorMessage, null);
    });
    
    test('Status flow validation', () {
      // Test that status transitions make sense
      final statuses = CommandStatus.values.map((s) => s.name).toList();
      expect(statuses, contains('recorded'));
      expect(statuses, contains('transcribing'));
      expect(statuses, contains('queued'));
      expect(statuses, contains('processing'));
      expect(statuses, contains('completed'));
      expect(statuses, contains('failed'));
      
      // Test logical flow order
      expect(statuses.indexOf('recorded'), lessThan(statuses.indexOf('transcribing')));
      expect(statuses.indexOf('transcribing'), lessThan(statuses.indexOf('queued')));
      expect(statuses.indexOf('queued'), lessThan(statuses.indexOf('processing')));
      expect(statuses.indexOf('processing'), lessThan(statuses.indexOf('completed')));
      expect(statuses.indexOf('processing'), lessThan(statuses.indexOf('failed')));
    });
  });
}
