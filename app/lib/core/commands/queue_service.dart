import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/queued_command.dart';
import '../../infrastructure/storage/realm_service.dart';

/// Queue state notifier for managing commands with Realm persistence
class QueueNotifier extends StateNotifier<List<QueuedCommandRealm>> {

  QueueNotifier() : super([]) {
    _realmService = RealmService();
    _loadCommandsFromRealmSync();
  }
  late final RealmService _realmService;
  
  void _loadCommandsFromRealmSync() {
    try {
      final commands = _realmService.getAllCommands();
      state = commands;
    } on Exception {
      state = [];
    }
  }
  

  List<QueuedCommandRealm> get queuedCommands {
    // Show ALL commands for now (no filtering)
    return state..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  List<QueuedCommandRealm> get processingCommands =>
      state.where((cmd) => !cmd.failed && !cmd.actionNeeded && 
          cmd.status != CommandStatus.completed.name && 
          cmd.status != CommandStatus.manual_review.name).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  List<QueuedCommandRealm> get completedCommands => 
      state.where((cmd) => cmd.status == CommandStatus.completed.name).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  List<QueuedCommandRealm> get failedCommands => 
      state.where((cmd) => cmd.failed).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  List<QueuedCommandRealm> get reviewCommands => 
      state.where((cmd) => cmd.failed || cmd.actionNeeded || cmd.status == CommandStatus.manual_review.name).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  void addCommand(QueuedCommandRealm command) {
    try {
      
      // Save to Realm
      _realmService.addCommand(command);
      
      // Update state
      state = [...state, command];
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandStatus(String id, CommandStatus status) {
    try {
      // Update in Realm
      _realmService.updateCommandStatus(id, status);
      
      // Update state
      state = state.map((cmd) {
        if (cmd.id == id) {
          return cmd.copyWithRealm(status: status.name);
        }
        return cmd;
      }).toList();
      
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandTranscription(String id, String transcription) {
    try {
      // Update in Realm
      _realmService.updateCommandTranscription(id, transcription);
      
      // Update state
      state = state.map((cmd) {
        if (cmd.id == id) {
          return cmd.copyWithRealm(transcription: transcription);
        }
        return cmd;
      }).toList();
      
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandFailed(String id, bool failed) {
    try {
      // Update in Realm
      _realmService.updateCommandFailed(id, failed);
      
      // Update state
      state = state.map((cmd) {
        if (cmd.id == id) {
          return cmd.copyWithRealm(failed: failed);
        }
        return cmd;
      }).toList();
      
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandErrorMessage(String id, String? errorMessage) {
    try {
      // Update in Realm
      _realmService.updateCommandErrorMessage(id, errorMessage);
      
      // Update state
      state = state.map((cmd) {
        if (cmd.id == id) {
          return cmd.copyWithRealm(errorMessage: errorMessage);
        }
        return cmd;
      }).toList();
      
    } catch (e) {
      rethrow;
    }
  }

  void updateCommandActionNeeded(String id, bool actionNeeded) {
    try {
      // Update in Realm
      _realmService.updateCommandActionNeeded(id, actionNeeded);
      
      // Update state
      state = state.map((cmd) {
        if (cmd.id == id) {
          return cmd.copyWithRealm(actionNeeded: actionNeeded);
        }
        return cmd;
      }).toList();
      
    } catch (e) {
      rethrow;
    }
  }

  void retryCommand(String id) {
    try {
      final command = state.firstWhere((cmd) => cmd.id == id);
      
      // Only retry transcribing or recorded commands
      if ((command.status == 'transcribing' || command.status == 'recorded') && command.failed) {
        // Clear failed flag and error message, keep status as transcribing
        updateCommandFailed(id, false);
        updateCommandErrorMessage(id, null);
        // Move to transcribing status for retry
        updateCommandStatus(id, CommandStatus.transcribing);
      } else {
        // For other cases, determine new status based on command type
        CommandStatus newStatus;
        if (command.audioPath != null) {
          // Audio command - move to manual review first
          newStatus = CommandStatus.manual_review;
        } else {
          // Text command - move to queued
          newStatus = CommandStatus.queued;
        }
        
        // Update status and clear failed flag
        updateCommandStatus(id, newStatus);
        updateCommandFailed(id, false);
        updateCommandErrorMessage(id, null);
      }
      
    } catch (e) {
      rethrow;
    }
  }

  void removeCommand(String id) {
    try {
      
      // Store command data before any Realm operations to avoid invalidation
      final commandsToKeep = <QueuedCommandRealm>[];
      for (final cmd in state) {
        try {
          final cmdId = cmd.id;
          if (cmdId != id) {
            commandsToKeep.add(cmd);
          }
        } on Exception {
          // Skip invalid commands silently - they're corrupted data
        }
      }
      
      // Remove from Realm
      _realmService.removeCommand(id);
      
      // Update state with pre-filtered commands
      state = commandsToKeep;
      
    } catch (e) {
      // Let the exception bubble up - UI will handle it
      rethrow;
    }
  }


  @override
  void dispose() {
    _realmService.close();
    super.dispose();
  }
}

final queueProvider = StateNotifierProvider<QueueNotifier, List<QueuedCommandRealm>>((ref) => QueueNotifier());

final queuedCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  final commands = ref.watch(queueProvider);
  
  // Apply filtering and sorting to the watched commands
  final sortedCommands = commands
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  
  // Limit to 30 most recent items for performance
  return sortedCommands.take(30).toList();
});

final processingCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  final commands = ref.watch(queueProvider);
  final filtered = commands
    .where((cmd) => !cmd.failed && !cmd.actionNeeded && 
        cmd.status != CommandStatus.completed.name && 
        cmd.status != CommandStatus.manual_review.name)
    .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered.take(30).toList();
});

final reviewCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  final commands = ref.watch(queueProvider);
  final filtered = commands
    .where((cmd) {
      final isFailed = cmd.failed;
      final isActionNeeded = cmd.actionNeeded;
      final isManualReview = cmd.status == CommandStatus.manual_review.name;
      return isFailed || isActionNeeded || isManualReview;
    })
    .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  
  return filtered;
});

final completedCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  final commands = ref.watch(queueProvider);
  final filtered = commands
    .where((cmd) => cmd.status == CommandStatus.completed.name)
    .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered.take(30).toList();
});

final failedCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  final commands = ref.watch(queueProvider);
  final filtered = commands
    .where((cmd) => cmd.failed)
    .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return filtered.take(30).toList();
});
