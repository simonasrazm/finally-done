import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Command Validation Business Logic', () {
    test('Text command validation', () {
      // Valid text command
      final validTextCommand = QueuedCommandRealm(
        'test-id',
        'Buy milk tomorrow',
        CommandStatus.queued.name,
        DateTime.now(),
      );
      expect(_validateCommand(validTextCommand), isEmpty);
      
      // Invalid text command - empty text
      final invalidTextCommand = QueuedCommandRealm(
        'test-id',
        '',
        CommandStatus.queued.name,
        DateTime.now(),
      );
      final errors = _validateCommand(invalidTextCommand);
      expect(errors, contains('Command must have text or transcription content'));
    });
    
    test('Voice command validation', () {
      // Valid voice command
      final validVoiceCommand = QueuedCommandRealm(
        'test-id',
        'Recording...',
        CommandStatus.recorded.name,
        DateTime.now(),
        audioPath: 'audio_123.m4a',
      );
      expect(_validateCommand(validVoiceCommand), isEmpty);
      
      // Invalid voice command - missing audioPath
      final invalidVoiceCommand = QueuedCommandRealm(
        'test-id',
        'Recording...',
        CommandStatus.recorded.name,
        DateTime.now(),
        audioPath: null,
      );
      final errors = _validateCommand(invalidVoiceCommand);
      expect(errors, contains('Voice command must have audioPath'));
    });
    
    test('Transcription validation', () {
      // Valid transcribed command
      final validTranscribedCommand = QueuedCommandRealm(
        'test-id',
        'Buy milk tomorrow',
        CommandStatus.queued.name,
        DateTime.now(),
        transcription: 'Buy milk tomorrow',
      );
      expect(_validateCommand(validTranscribedCommand), isEmpty);
      
      // Invalid transcribed command - empty transcription
      final invalidTranscribedCommand = QueuedCommandRealm(
        'test-id',
        '', // Empty text
        CommandStatus.queued.name,
        DateTime.now(),
        transcription: '', // Empty transcription
      );
      final errors = _validateCommand(invalidTranscribedCommand);
      expect(errors, contains('Command must have text or transcription content'));
    });
    
    test('Photo attachment validation', () {
      // Valid command with photos
      final validPhotoCommand = QueuedCommandRealm(
        'test-id',
        'Remember this document',
        CommandStatus.queued.name,
        DateTime.now(),
        photoPaths: ['photo1.jpg', 'photo2.jpg'],
      );
      expect(_validateCommand(validPhotoCommand), isEmpty);
      
      // Invalid command - empty photo filename
      final invalidPhotoCommand = QueuedCommandRealm(
        'test-id',
        'Remember this document',
        CommandStatus.queued.name,
        DateTime.now(),
        photoPaths: ['', 'photo2.jpg'],
      );
      final errors = _validateCommand(invalidPhotoCommand);
      expect(errors, contains('Photo paths must not be empty'));
    });
    
    test('Error message validation', () {
      // Valid completed command with error message
      final validCompletedCommand = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.completed.name,
        DateTime.now(),
        errorMessage: 'API timeout',
      );
      expect(_validateCommand(validCompletedCommand), isEmpty);
      
      // Completed command without error message (still valid, but not ideal)
      final completedCommandWithoutError = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.completed.name,
        DateTime.now(),
        errorMessage: null,
      );
      expect(_validateCommand(completedCommandWithoutError), isEmpty);
    });
    
    test('ID validation', () {
      // Valid ID
      final validCommand = QueuedCommandRealm(
        'test-id-123',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now(),
      );
      expect(_validateCommand(validCommand), isEmpty);
      
      // Invalid ID - empty
      final invalidIdCommand = QueuedCommandRealm(
        '',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now(),
      );
      final errors = _validateCommand(invalidIdCommand);
      expect(errors, contains('Command ID must not be empty'));
    });
    
    test('Timestamp validation', () {
      // Valid timestamp
      final validCommand = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now(),
      );
      expect(_validateCommand(validCommand), isEmpty);
      
      // Invalid timestamp - future date
      final futureCommand = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now().add(Duration(days: 1)),
      );
      final errors = _validateCommand(futureCommand);
      expect(errors, contains('Command timestamp cannot be in the future'));
    });
  });
}

/// Business logic: Validate command based on business rules
List<String> _validateCommand(QueuedCommandRealm command) {
  final errors = <String>[];
  
  // ID validation
  if (command.id.isEmpty) {
    errors.add('Command ID must not be empty');
  }
  
  // Timestamp validation
  if (command.createdAt.isAfter(DateTime.now())) {
    errors.add('Command timestamp cannot be in the future');
  }
  
  // Status-specific validation
  switch (CommandStatus.values.firstWhere((s) => s.name == command.status)) {
    case CommandStatus.recorded:
    case CommandStatus.manual_review:
    case CommandStatus.transcribing:
      // Voice commands must have audioPath
      if (command.audioPath == null || command.audioPath!.isEmpty) {
        errors.add('Voice command must have audioPath');
      }
      break;
      
    case CommandStatus.queued:
    case CommandStatus.processing:
      // Must have either text or transcription
      if (command.text.isEmpty && 
          (command.transcription == null || command.transcription!.isEmpty)) {
        errors.add('Command must have text or transcription content');
      }
      break;
      
    case CommandStatus.completed:
    // CommandStatus.failed was removed from the enum
      // Terminal states - no additional validation needed
      break;
  }
  
  // Photo validation
  for (final photoPath in command.photoPaths) {
    if (photoPath.isEmpty) {
      errors.add('Photo paths must not be empty');
      break;
    }
  }
  
  return errors;
}
