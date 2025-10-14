import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as tasks;
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:googleapis/gmail/v1.dart' as gmail;
import '../utils/logger.dart';
import 'integrations/integration_manager.dart';
import 'integrations/google_integration_provider.dart';
import 'google_tasks_service.dart';
import 'connectors/connector_manager.dart';

/// Integration Service
/// Provides a unified interface for the AI agent to execute actions
/// on USER's Google services (Tasks, Calendar, Gmail)
class IntegrationService {
  final IntegrationManager _integrationManager;
  final ConnectorManager _connectorManager;
  GoogleTasksService? _tasksService;

  IntegrationService(this._integrationManager, this._connectorManager) {
    // Initialize tasks service if Google Tasks is connected
    if (_integrationManager.isServiceConnected('google', 'tasks')) {
      final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
      if (googleProvider?.authClient != null) {
        _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
      }
    }
  }

  /// Check if user is authenticated with Google services
  bool get isAuthenticated => _integrationManager.isProviderAuthenticated('google');

  /// Get user information
  String? get userEmail => _integrationManager.getProvider('google')?.state.userEmail;
  String? get userName => _integrationManager.getProvider('google')?.state.userName;
  
  /// Check if specific services are connected
  bool get isTasksConnected => _integrationManager.isServiceConnected('google', 'tasks');
  bool get isCalendarConnected => _integrationManager.isServiceConnected('google', 'calendar');
  bool get isGmailConnected => _integrationManager.isServiceConnected('google', 'gmail');
  
  /// Get list of connected services
  Set<String> get connectedServices => _integrationManager.getConnectedServices('google').map((s) => s.id).toSet();
  
  /// Check if a specific service is connected
  bool isServiceConnected(String service) => _integrationManager.isServiceConnected('google', service);
  
  /// Connect to specific Google service
  Future<bool> connectToService(String service) async {
    try {
      // For now, just return true if authenticated
      // This will be updated to use the new integration system
      final success = _integrationManager.isProviderAuthenticated('google');
      
      if (success && service == 'tasks') {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
      }
      
      return success;
    } catch (e, stackTrace) {
      Logger.error('Failed to connect to service $service', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Authenticate user with Google
  Future<bool> authenticate() async {
    try {
      Logger.info('Starting USER authentication for integrations', tag: 'INTEGRATION');

      final success = await _integrationManager.authenticateProvider('google');
      if (success) {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
        Logger.info('USER authenticated successfully for integrations', tag: 'INTEGRATION');
      }
      return success;
    } catch (e, stackTrace) {
      Logger.error('USER authentication failed for integrations', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      Logger.info('Signing out USER from integrations', tag: 'INTEGRATION');
      await _integrationManager.signOutProvider('google');
      _tasksService = null;
      Logger.info('USER signed out from integrations', tag: 'INTEGRATION');
    } catch (e, stackTrace) {
      Logger.error('USER sign out failed for integrations', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
    }
  }

  // ===== TASK MANAGEMENT =====

  /// Create a new task
  Future<Map<String, dynamic>> createTask(String title, {String? notes, DateTime? due}) async {
    try {
      // Ensure we have valid authentication before making API calls
      if (!_integrationManager.isProviderAuthenticated('google')) {
        throw Exception('Google authentication expired. Please re-connect in Settings.');
      }

      if (_tasksService == null) {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
      }

      Logger.info('Creating task: $title', tag: 'INTEGRATION');
      
      // Get default task list
      final defaultList = await _tasksService!.getDefaultTaskList();
      if (defaultList == null) {
        throw Exception('No default task list found');
      }

      final task = await _tasksService!.createTask(
        defaultList.id!,
        title,
        notes: notes,
        due: due,
      );

      Logger.info('Successfully created task: ${task.id}', tag: 'INTEGRATION');
      
      return {
        'success': true,
        'taskId': task.id,
        'title': task.title,
        'status': task.status,
        'message': 'Task created successfully',
      };
    } catch (e, stackTrace) {
      Logger.error('Failed to create task: $title', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to create task',
      };
    }
  }

  /// Complete a task
  Future<Map<String, dynamic>> completeTask(String taskId) async {
    try {
      // Ensure we have valid authentication before making API calls
      if (!_integrationManager.isProviderAuthenticated('google')) {
        throw Exception('Google authentication expired. Please re-connect in Settings.');
      }

      if (_tasksService == null) {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
      }

      Logger.info('Completing task: $taskId', tag: 'INTEGRATION');
      
      // Get default task list
      final defaultList = await _tasksService!.getDefaultTaskList();
      if (defaultList == null) {
        throw Exception('No default task list found');
      }

      await _tasksService!.completeTask(defaultList.id!, taskId);

      Logger.info('Successfully completed task: $taskId', tag: 'INTEGRATION');
      
      return {
        'success': true,
        'taskId': taskId,
        'message': 'Task completed successfully',
      };
    } catch (e, stackTrace) {
      Logger.error('Failed to complete task: $taskId', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to complete task',
      };
    }
  }

  /// List user's tasks
  Future<Map<String, dynamic>> listTasks() async {
    try {
      // Ensure we have valid authentication before making API calls
      if (!_integrationManager.isProviderAuthenticated('google')) {
        throw Exception('Google authentication expired. Please re-connect in Settings.');
      }

      if (_tasksService == null) {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
      }

      Logger.info('Listing user tasks', tag: 'INTEGRATION');
      
      // Get default task list
      final defaultList = await _tasksService!.getDefaultTaskList();
      if (defaultList == null) {
        throw Exception('No default task list found');
      }

      final taskList = await _tasksService!.getTasks(defaultList.id!);
      final tasks = taskList.map((task) => {
        'id': task.id,
        'title': task.title,
        'status': task.status,
        'notes': task.notes,
        'due': task.due,
        'completed': task.completed,
      }).toList();

      Logger.info('Retrieved ${tasks.length} tasks', tag: 'INTEGRATION');
      
      return {
        'success': true,
        'tasks': tasks,
        'message': 'Tasks retrieved successfully',
      };
    } catch (e, stackTrace) {
      Logger.error('Failed to list tasks', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to list tasks',
      };
    }
  }

  /// Search tasks
  Future<Map<String, dynamic>> searchTasks(String query) async {
    try {
      // Ensure we have valid authentication before making API calls
      if (!_integrationManager.isProviderAuthenticated('google')) {
        throw Exception('Google authentication expired. Please re-connect in Settings.');
      }

      if (_tasksService == null) {
        final googleProvider = _integrationManager.getProvider('google') as GoogleIntegrationProvider?;
        if (googleProvider?.authClient != null) {
          _tasksService = GoogleTasksService(_integrationManager, _connectorManager, googleProvider!.authClient!);
        }
      }

      Logger.info('Searching tasks with query: $query', tag: 'INTEGRATION');
      
      // Get default task list
      final defaultList = await _tasksService!.getDefaultTaskList();
      if (defaultList == null) {
        throw Exception('No default task list found');
      }

      final taskList = await _tasksService!.searchTasks(defaultList.id!, query);
      final tasks = taskList.map((task) => {
        'id': task.id,
        'title': task.title,
        'status': task.status,
        'notes': task.notes,
        'due': task.due,
        'completed': task.completed,
      }).toList();

      Logger.info('Found ${tasks.length} matching tasks', tag: 'INTEGRATION');
      
      return {
        'success': true,
        'tasks': tasks,
        'query': query,
        'message': 'Search completed successfully',
      };
    } catch (e, stackTrace) {
      Logger.error('Failed to search tasks with query: $query', 
        tag: 'INTEGRATION', 
        error: e, 
        stackTrace: stackTrace
      );
      return {
        'success': false,
        'error': e.toString(),
        'message': 'Failed to search tasks',
      };
    }
  }

  // ===== CALENDAR INTEGRATION (TODO) =====
  // Future<Map<String, dynamic>> createEvent(...) async { ... }
  // Future<Map<String, dynamic>> listEvents(...) async { ... }

  // ===== EMAIL INTEGRATION (TODO) =====
  // Future<Map<String, dynamic>> sendEmail(...) async { ... }
  // Future<Map<String, dynamic>> listEmails(...) async { ... }
}

/// Provider for Integration Service
final integrationServiceProvider = Provider<IntegrationService>((ref) {
  final integrationManager = ref.watch(integrationManagerProvider.notifier);
  final connectorManager = ref.watch(connectorManagerProvider.notifier);
  return IntegrationService(integrationManager, connectorManager);
});

/// Provider for authentication status
final isIntegrationAuthenticatedProvider = Provider<bool>((ref) {
  final integrationManager = ref.watch(integrationManagerProvider.notifier);
  return integrationManager.isProviderAuthenticated('google');
});
