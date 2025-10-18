import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/core/commands/command_retry_service.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('CommandRetryService Tests', () {
    group('determineRetryAction', () {
      test('processing command should reset to queued', () {
        final result = CommandRetryService.determineRetryAction('processing', false);
        
        expect(result.newStatus, CommandStatus.queued.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });

      test('failed transcribing command should stay in transcribing but clear error', () {
        final result = CommandRetryService.determineRetryAction('transcribing', true);
        
        expect(result.newStatus, CommandStatus.transcribing.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });

      test('successful transcribing command should stay in transcribing', () {
        final result = CommandRetryService.determineRetryAction('transcribing', false);
        
        expect(result.newStatus, CommandStatus.transcribing.name);
        expect(result.clearError, isFalse);
        expect(result.clearErrorMessage, isFalse);
      });

      test('manual_review command should stay in manual_review', () {
        final result = CommandRetryService.determineRetryAction('manual_review', false);
        
        expect(result.newStatus, CommandStatus.manual_review.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });

      test('manual_review command with error should stay in manual_review and clear error', () {
        final result = CommandRetryService.determineRetryAction('manual_review', true);
        
        expect(result.newStatus, CommandStatus.manual_review.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });

      test('unknown status should not change anything', () {
        final result = CommandRetryService.determineRetryAction('unknown_status', true);
        
        expect(result.newStatus, 'unknown_status');
        expect(result.clearError, isFalse);
        expect(result.clearErrorMessage, isFalse);
      });
    });

    group('canRetryCommand', () {
      test('processing command can always be retried', () {
        expect(CommandRetryService.canRetryCommand('processing', false), isTrue);
        expect(CommandRetryService.canRetryCommand('processing', true), isTrue);
      });

      test('transcribing command can only be retried if failed', () {
        expect(CommandRetryService.canRetryCommand('transcribing', true), isTrue);
        expect(CommandRetryService.canRetryCommand('transcribing', false), isFalse);
      });

      test('manual_review command can always be retried', () {
        expect(CommandRetryService.canRetryCommand('manual_review', false), isTrue);
        expect(CommandRetryService.canRetryCommand('manual_review', true), isTrue);
      });

      test('completed command cannot be retried', () {
        expect(CommandRetryService.canRetryCommand('completed', false), isFalse);
        expect(CommandRetryService.canRetryCommand('completed', true), isFalse);
      });

      test('queued command cannot be retried', () {
        expect(CommandRetryService.canRetryCommand('queued', false), isFalse);
        expect(CommandRetryService.canRetryCommand('queued', true), isFalse);
      });

      test('unknown status cannot be retried', () {
        expect(CommandRetryService.canRetryCommand('unknown_status', false), isFalse);
        expect(CommandRetryService.canRetryCommand('unknown_status', true), isFalse);
      });
    });

    group('getStatusAfterTranscription', () {
      test('transcribing should move to manual_review after transcription', () {
        final result = CommandRetryService.getStatusAfterTranscription('transcribing');
        expect(result, CommandStatus.manual_review.name);
      });

      test('manual_review should stay in manual_review after transcription', () {
        final result = CommandRetryService.getStatusAfterTranscription('manual_review');
        expect(result, CommandStatus.manual_review.name);
      });

      test('other statuses should not change after transcription', () {
        expect(CommandRetryService.getStatusAfterTranscription('processing'), 'processing');
        expect(CommandRetryService.getStatusAfterTranscription('completed'), 'completed');
        expect(CommandRetryService.getStatusAfterTranscription('unknown'), 'unknown');
      });
    });

    group('needsManualReviewAfterTranscription', () {
      test('transcribing commands need manual review', () {
        expect(CommandRetryService.needsManualReviewAfterTranscription('transcribing'), isTrue);
      });

      test('manual_review commands need manual review', () {
        expect(CommandRetryService.needsManualReviewAfterTranscription('manual_review'), isTrue);
      });

      test('other statuses do not need manual review', () {
        expect(CommandRetryService.needsManualReviewAfterTranscription('processing'), isFalse);
        expect(CommandRetryService.needsManualReviewAfterTranscription('completed'), isFalse);
        expect(CommandRetryService.needsManualReviewAfterTranscription('queued'), isFalse);
        expect(CommandRetryService.needsManualReviewAfterTranscription('unknown'), isFalse);
      });
    });

    group('Error Recovery Flow Integration', () {
      test('Complete error recovery flow: error → transcribing → manual_review', () {
        // Step 1: Failed transcribing command
        final failedResult = CommandRetryService.determineRetryAction('transcribing', true);
        expect(failedResult.newStatus, CommandStatus.transcribing.name);
        expect(failedResult.clearError, isTrue);
        expect(failedResult.clearErrorMessage, isTrue);

        // Step 2: After successful transcription
        final afterTranscription = CommandRetryService.getStatusAfterTranscription('transcribing');
        expect(afterTranscription, CommandStatus.manual_review.name);

        // Step 3: Manual review retry
        final manualReviewResult = CommandRetryService.determineRetryAction('manual_review', false);
        expect(manualReviewResult.newStatus, CommandStatus.manual_review.name);
        expect(manualReviewResult.clearError, isTrue);
        expect(manualReviewResult.clearErrorMessage, isTrue);
      });

      test('Processing command retry flow', () {
        final result = CommandRetryService.determineRetryAction('processing', false);
        expect(result.newStatus, CommandStatus.queued.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });

      test('Manual review retry keeps state', () {
        final result = CommandRetryService.determineRetryAction('manual_review', false);
        expect(result.newStatus, CommandStatus.manual_review.name);
        expect(result.clearError, isTrue);
        expect(result.clearErrorMessage, isTrue);
      });
    });

    group('RetryResult equality and toString', () {
      test('RetryResult equality works correctly', () {
        final result1 = RetryResult(
          newStatus: 'transcribing',
          clearError: true,
          clearErrorMessage: false,
        );
        
        final result2 = RetryResult(
          newStatus: 'transcribing',
          clearError: true,
          clearErrorMessage: false,
        );
        
        final result3 = RetryResult(
          newStatus: 'manual_review',
          clearError: true,
          clearErrorMessage: false,
        );

        expect(result1, equals(result2));
        expect(result1, isNot(equals(result3)));
      });

      test('RetryResult toString works correctly', () {
        final result = RetryResult(
          newStatus: 'transcribing',
          clearError: true,
          clearErrorMessage: false,
        );
        
        expect(result.toString(), contains('transcribing'));
        expect(result.toString(), contains('true'));
        expect(result.toString(), contains('false'));
      });
    });
  });
}
