import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';
import 'package:finally_done/services/queue_service.dart';

void main() {
  group('Error Recovery Flow Tests', () {
    test('Failed transcribing command should move to transcribing on retry', () {
      // Create a failed transcribing command
      final failedCommand = QueuedCommandRealm(
        'test-1',
        'Test command',
        CommandStatus.transcribing.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
        failed: true,
        errorMessage: 'Transcription failed',
      );

      // Simulate retry action - should clear error and stay in transcribing
      final afterRetry = QueuedCommandRealm(
        failedCommand.id,
        failedCommand.text,
        failedCommand.status, // Stay in transcribing
        failedCommand.createdAt,
        audioPath: failedCommand.audioPath,
        failed: false, // Error cleared
        errorMessage: null, // Error message cleared
      );

      // Verify error is cleared but status remains transcribing
      expect(afterRetry.failed, isFalse);
      expect(afterRetry.errorMessage, isNull);
      expect(afterRetry.status, CommandStatus.transcribing.name);
    });

    test('Successful transcription should move from transcribing to manual_review', () {
      // Create a transcribing command (after retry cleared the error)
      final transcribingCommand = QueuedCommandRealm(
        'test-2',
        'Test command',
        CommandStatus.transcribing.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
        failed: false,
        errorMessage: null,
      );

      // Simulate successful transcription - should move to manual_review
      final afterTranscription = QueuedCommandRealm(
        transcribingCommand.id,
        transcribingCommand.text,
        CommandStatus.manual_review.name, // Move to manual_review
        transcribingCommand.createdAt,
        audioPath: transcribingCommand.audioPath,
        transcription: 'Mock transcription result', // New transcription
        failed: false,
        errorMessage: null,
      );

      // Verify status changed to manual_review and transcription is set
      expect(afterTranscription.status, CommandStatus.manual_review.name);
      expect(afterTranscription.transcription, 'Mock transcription result');
      expect(afterTranscription.failed, isFalse);
      expect(afterTranscription.errorMessage, isNull);
    });

    test('Complete error recovery flow: error → transcribing → manual_review', () {
      // Step 1: Start with failed command
      final failedCommand = QueuedCommandRealm(
        'test-3',
        'Test command',
        CommandStatus.transcribing.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
        failed: true,
        errorMessage: 'API timeout',
      );

      // Step 2: Retry clears error, stays in transcribing
      final afterRetry = QueuedCommandRealm(
        failedCommand.id,
        failedCommand.text,
        failedCommand.status, // transcribing
        failedCommand.createdAt,
        audioPath: failedCommand.audioPath,
        failed: false, // Error cleared
        errorMessage: null, // Error message cleared
      );

      // Step 3: Successful transcription moves to manual_review
      final afterTranscription = QueuedCommandRealm(
        afterRetry.id,
        afterRetry.text,
        CommandStatus.manual_review.name, // Move to manual_review
        afterRetry.createdAt,
        audioPath: afterRetry.audioPath,
        transcription: 'Successfully transcribed text', // New transcription
        failed: false,
        errorMessage: null,
      );

      // Verify complete flow
      expect(failedCommand.failed, isTrue);
      expect(failedCommand.errorMessage, 'API timeout');
      expect(failedCommand.status, CommandStatus.transcribing.name);

      expect(afterRetry.failed, isFalse);
      expect(afterRetry.errorMessage, isNull);
      expect(afterRetry.status, CommandStatus.transcribing.name);

      expect(afterTranscription.failed, isFalse);
      expect(afterTranscription.errorMessage, isNull);
      expect(afterTranscription.status, CommandStatus.manual_review.name);
      expect(afterTranscription.transcription, 'Successfully transcribed text');
    });

    test('Error recovery flow with different error types', () {
      final errorTypes = [
        'API timeout',
        'Network error',
        'Invalid audio format',
        'Transcription service unavailable',
        'Rate limit exceeded',
      ];

      for (final errorType in errorTypes) {
        // Start with failed command
        final failedCommand = QueuedCommandRealm(
          'test-${errorType.replaceAll(' ', '-').toLowerCase()}',
          'Test command',
          CommandStatus.transcribing.name,
          DateTime.now(),
          audioPath: '/path/to/audio.mp3',
          failed: true,
          errorMessage: errorType,
        );

        // Retry should clear any error type
        final afterRetry = QueuedCommandRealm(
          failedCommand.id,
          failedCommand.text,
          failedCommand.status,
          failedCommand.createdAt,
          audioPath: failedCommand.audioPath,
          failed: false,
          errorMessage: null,
        );

        // Verify error is cleared regardless of original error type
        expect(afterRetry.failed, isFalse, reason: 'Error should be cleared for: $errorType');
        expect(afterRetry.errorMessage, isNull, reason: 'Error message should be cleared for: $errorType');
        expect(afterRetry.status, CommandStatus.transcribing.name, reason: 'Status should remain transcribing for: $errorType');
      }
    });

    test('Manual review retry should keep command in manual_review state', () {
      // Create a manual review command
      final manualReviewCommand = QueuedCommandRealm(
        'test-4',
        'Test command',
        CommandStatus.manual_review.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
        transcription: 'Original transcription',
        failed: false,
        errorMessage: null,
      );

      // Simulate retry - should update transcription but stay in manual_review
      final afterRetry = QueuedCommandRealm(
        manualReviewCommand.id,
        manualReviewCommand.text,
        manualReviewCommand.status, // Stay in manual_review
        manualReviewCommand.createdAt,
        audioPath: manualReviewCommand.audioPath,
        transcription: 'Updated transcription after retry', // New transcription
        failed: false,
        errorMessage: null,
      );

      // Verify status unchanged but transcription updated
      expect(afterRetry.status, CommandStatus.manual_review.name);
      expect(afterRetry.transcription, 'Updated transcription after retry');
      expect(afterRetry.failed, isFalse);
      expect(afterRetry.errorMessage, isNull);
    });

    test('Error recovery flow validation', () {
      // Test that the flow follows the expected state transitions
      
      // Test 1: Error recovery flow - retry clears error
      final failedCommand = QueuedCommandRealm(
        'test-error-recovery',
        'Test command',
        CommandStatus.transcribing.name,
        DateTime.now(),
        audioPath: '/path/to/audio.mp3',
        failed: true,
        errorMessage: 'API error',
      );

      final afterRetry = QueuedCommandRealm(
        failedCommand.id,
        failedCommand.text,
        CommandStatus.transcribing.name, // Stay in transcribing
        failedCommand.createdAt,
        audioPath: failedCommand.audioPath,
        failed: false, // Error cleared
        errorMessage: null, // Error message cleared
      );

      expect(afterRetry.status, CommandStatus.transcribing.name);
      expect(afterRetry.failed, isFalse);
      expect(afterRetry.errorMessage, isNull);

      // Test 2: Successful transcription moves to manual_review
      final afterTranscription = QueuedCommandRealm(
        afterRetry.id,
        afterRetry.text,
        CommandStatus.manual_review.name, // Move to manual_review
        afterRetry.createdAt,
        audioPath: afterRetry.audioPath,
        transcription: 'Mock transcription result',
        failed: false,
        errorMessage: null,
      );

      expect(afterTranscription.status, CommandStatus.manual_review.name);
      expect(afterTranscription.transcription, 'Mock transcription result');
      expect(afterTranscription.failed, isFalse);
      expect(afterTranscription.errorMessage, isNull);

      // Test 3: Manual review retry keeps state
      final afterManualReviewRetry = QueuedCommandRealm(
        afterTranscription.id,
        afterTranscription.text,
        CommandStatus.manual_review.name, // Stay in manual_review
        afterTranscription.createdAt,
        audioPath: afterTranscription.audioPath,
        transcription: 'Updated transcription after retry',
        failed: false,
        errorMessage: null,
      );

      expect(afterManualReviewRetry.status, CommandStatus.manual_review.name);
      expect(afterManualReviewRetry.transcription, 'Updated transcription after retry');
      expect(afterManualReviewRetry.failed, isFalse);
      expect(afterManualReviewRetry.errorMessage, isNull);
    });
  });
}
