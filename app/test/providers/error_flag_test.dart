import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../../lib/providers/tasks_provider.dart';

void main() {
  group('TasksProvider Error Flag Tests', () {
    late ProviderContainer container;
    late TasksNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(tasksProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    test('clearError: true should set error to null', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Test error message',
        isConnected: false,
      );

      // Use copyWith with clearError: true
      final newState = notifier.state.copyWith(
        clearError: true,
        isLoading: true,
      );

      expect(newState.error, isNull);
      expect(newState.isLoading, isTrue);
    });

    test('clearError: false should preserve existing error', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Test error message',
        isConnected: false,
      );

      // Use copyWith with clearError: false (default)
      final newState = notifier.state.copyWith(
        isLoading: true,
      );

      expect(newState.error, equals('Test error message'));
      expect(newState.isLoading, isTrue);
    });

    test('clearError: false with new error should set new error', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Old error message',
        isConnected: false,
      );

      // Use copyWith with new error and clearError: false
      final newState = notifier.state.copyWith(
        error: 'New error message',
        clearError: false,
      );

      expect(newState.error, equals('New error message'));
    });

    test('clearError: true with new error should ignore new error', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Old error message',
        isConnected: false,
      );

      // Use copyWith with new error but clearError: true
      final newState = notifier.state.copyWith(
        error: 'New error message',
        clearError: true,
      );

      expect(newState.error, isNull);
    });

    test('clearError: true should work with other state changes', () {
      // Set initial state with error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        error: 'Test error message',
        isConnected: false,
      );

      // Use copyWith with multiple changes including clearError: true
      final newState = notifier.state.copyWith(
        tasks: [google_tasks.Task()..id = 'test-task'],
        isLoading: true,
        isConnected: true,
        clearError: true,
      );

      expect(newState.error, isNull);
      expect(newState.tasks.length, equals(1));
      expect(newState.isLoading, isTrue);
      expect(newState.isConnected, isTrue);
    });

    test('error flag behavior in state transitions', () {
      // Start with no error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        isConnected: true,
      );

      // Set error
      notifier.state = notifier.state.copyWith(
        error: 'Connection failed',
        isConnected: false,
      );
      expect(notifier.state.error, equals('Connection failed'));

      // Clear error with successful operation
      notifier.state = notifier.state.copyWith(
        tasks: [google_tasks.Task()..id = 'task-1'],
        isConnected: true,
        clearError: true,
      );
      expect(notifier.state.error, isNull);
      expect(notifier.state.isConnected, isTrue);
    });

    test('error flag with null initial error', () {
      // Start with null error
      notifier.state = TasksState(
        tasks: [],
        lastUpdated: DateTime.now(),
        isConnected: true,
      );

      // clearError: true should keep error as null
      final newState = notifier.state.copyWith(
        clearError: true,
        isLoading: true,
      );

      expect(newState.error, isNull);
      expect(newState.isLoading, isTrue);
    });
  });
}
