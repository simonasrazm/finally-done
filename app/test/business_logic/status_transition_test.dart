import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Status Transition Business Logic', () {
    test('Voice command flow - valid transitions', () {
      // Test valid voice command flow
      final validTransitions = [
        CommandStatus.recorded,      // 1. Audio recorded
        CommandStatus.manual_review,  // 2. Manual review required
        CommandStatus.transcribing,   // 3. Being transcribed
        CommandStatus.queued,        // 4. Ready to process
        CommandStatus.processing,    // 5. Being processed
        CommandStatus.completed,     // 6. Successfully executed
      ];
      
      // Verify each transition is valid
      for (int i = 0; i < validTransitions.length - 1; i++) {
        final current = validTransitions[i];
        final next = validTransitions[i + 1];
        expect(_isValidTransition(current, next), isTrue, 
          reason: 'Transition from $current to $next should be valid');
      }
    });
    
    test('Voice command flow - can complete from processing state', () {
      // Test that voice commands can complete from processing state
      expect(_isValidTransition(CommandStatus.processing, CommandStatus.completed), isTrue,
        reason: 'Voice command should be able to complete from processing state');
    });
    
    test('Text command flow - valid transitions', () {
      // Test valid text command flow
      final validTransitions = [
        CommandStatus.queued,      // 1. Ready to process
        CommandStatus.processing,  // 2. Being processed
        CommandStatus.completed,   // 3. Successfully executed
      ];
      
      // Verify each transition is valid
      for (int i = 0; i < validTransitions.length - 1; i++) {
        final current = validTransitions[i];
        final next = validTransitions[i + 1];
        expect(_isValidTransition(current, next), isTrue,
          reason: 'Transition from $current to $next should be valid');
      }
    });
    
    test('Text command flow - can complete from processing state', () {
      // Test that text commands can complete from processing state
      expect(_isValidTransition(CommandStatus.processing, CommandStatus.completed), isTrue,
        reason: 'Text command should be able to complete from processing state');
    });
    
    
    test('Invalid transitions - should be rejected', () {
      // Can't go backwards in voice flow
      expect(_isValidTransition(CommandStatus.manual_review, CommandStatus.recorded), isFalse);
      expect(_isValidTransition(CommandStatus.transcribing, CommandStatus.manual_review), isFalse);
      expect(_isValidTransition(CommandStatus.queued, CommandStatus.transcribing), isFalse);
      expect(_isValidTransition(CommandStatus.processing, CommandStatus.queued), isFalse);
      
      // Can't go from completed to anything else (terminal state)
      expect(_isValidTransition(CommandStatus.completed, CommandStatus.processing), isFalse);
      expect(_isValidTransition(CommandStatus.completed, CommandStatus.queued), isFalse);
      
      // Can't skip manual_review for voice commands
      expect(_isValidTransition(CommandStatus.recorded, CommandStatus.transcribing), isFalse);
      expect(_isValidTransition(CommandStatus.recorded, CommandStatus.queued), isFalse);
    });
    
    test('Status validation - required fields', () {
      // Voice commands must have audioPath
      final voiceCommand = QueuedCommandRealm(
        'test-id',
        'Test voice command',
        CommandStatus.recorded.name,
        DateTime.now(),
        audioPath: 'test-audio.m4a',
      );
      expect(_isValidCommand(voiceCommand), isTrue);
      
      // Voice command without audioPath is invalid
      final invalidVoiceCommand = QueuedCommandRealm(
        'test-id',
        'Test voice command',
        CommandStatus.recorded.name,
        DateTime.now(),
        audioPath: null,
      );
      expect(_isValidCommand(invalidVoiceCommand), isFalse);
    });
    
    test('Status validation - content requirements', () {
      // Valid queued command with text
      final validTextCommand = QueuedCommandRealm(
        'test-id',
        'Test command',
        CommandStatus.queued.name,
        DateTime.now(),
        transcription: null,
      );
      expect(_isValidCommand(validTextCommand), isTrue);
      
      // Valid queued command with transcription
      final validTranscribedCommand = QueuedCommandRealm(
        'test-id',
        'Recording...',
        CommandStatus.queued.name,
        DateTime.now(),
        transcription: 'Transcribed text',
      );
      expect(_isValidCommand(validTranscribedCommand), isTrue);
      
      // Invalid queued command - no text and no transcription
      final invalidCommand = QueuedCommandRealm(
        'test-id',
        '',
        CommandStatus.queued.name,
        DateTime.now(),
        transcription: null,
      );
      expect(_isValidCommand(invalidCommand), isFalse);
    });
  });
}

/// Business logic: Check if status transition is valid
bool _isValidTransition(CommandStatus from, CommandStatus to) {
  // Terminal states - no transitions allowed
  if (from == CommandStatus.completed) {
    return false;
  }
  
  // Define valid transitions
  final validTransitions = {
    CommandStatus.recorded: [CommandStatus.manual_review],
    CommandStatus.manual_review: [CommandStatus.transcribing],
    CommandStatus.transcribing: [CommandStatus.queued],
    CommandStatus.queued: [CommandStatus.processing],
    CommandStatus.processing: [CommandStatus.completed],
  };
  
  return validTransitions[from]?.contains(to) ?? false;
}

/// Business logic: Check if command is valid for its current status
bool _isValidCommand(QueuedCommandRealm command) {
  switch (CommandStatus.values.firstWhere((s) => s.name == command.status)) {
    case CommandStatus.recorded:
      // Voice commands must have audioPath
      return command.audioPath != null && command.audioPath!.isNotEmpty;
      
    case CommandStatus.manual_review:
      // Manual review commands must have audioPath
      return command.audioPath != null && command.audioPath!.isNotEmpty;
      
    case CommandStatus.transcribing:
      // Transcribing commands must have audioPath
      return command.audioPath != null && command.audioPath!.isNotEmpty;
      
    case CommandStatus.queued:
      // Queued commands must have either text or transcription
      return command.text.isNotEmpty || 
             (command.transcription != null && command.transcription!.isNotEmpty);
      
    case CommandStatus.processing:
      // Processing commands must have text content
      return command.text.isNotEmpty || 
             (command.transcription != null && command.transcription!.isNotEmpty);
      
    case CommandStatus.completed:
      // Terminal state - any content is valid
      return true;
  }
}
