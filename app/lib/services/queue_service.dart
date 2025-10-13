import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/queued_command.dart';
import 'realm_service.dart';
import '../utils/logger.dart';

/// Queue state notifier for managing commands with Realm persistence
class QueueNotifier extends StateNotifier<List<QueuedCommandRealm>> {
  late final RealmService _realmService;

  QueueNotifier() : super([]) {
    _realmService = RealmService();
    _loadCommandsFromRealmSync();
  }
  
  void _loadCommandsFromRealmSync() {
    try {
      final commands = _realmService.getAllCommands();
      state = commands;
    } catch (e) {
      state = [];
    }
  }

  Future<void> _loadCommandsFromRealm() async {
    try {
      final commands = _realmService.getAllCommands();
      
      // Debug: Show all commands and their audio paths
      for (var cmd in commands) {
      }
      
      // Clean up commands with missing audio files BEFORE setting state
      final cleanedCommands = await _cleanupMissingAudioFiles(commands);
      state = cleanedCommands;
      
    } catch (e) {
      state = [];
    }
  }
  

  Future<List<QueuedCommandRealm>> _cleanupMissingAudioFiles(List<QueuedCommandRealm> commands) async {
    final commandsToUpdate = <QueuedCommandRealm>[];
    final cleanedCommands = <QueuedCommandRealm>[];
    
    for (final command in commands) {
      try {
        // Safely access command properties
        final audioPath = command.audioPath;
        final text = command.text;
        
        if (audioPath != null && audioPath.isNotEmpty) {
          // Check if it's a full path (old format) or just filename (new format)
          final isFullPath = audioPath.contains('/');
        String fullPath;
        
        if (isFullPath) {
          // Old format - try to move file to new location
          final fileName = audioPath.split('/').last;
          final directory = await getApplicationDocumentsDirectory();
          final audioDir = Directory('${directory.path}/audio');
          
          // Ensure audio directory exists
          if (!await audioDir.exists()) {
            await audioDir.create(recursive: true);
          }
          
          final oldFile = File(audioPath);
          final newFullPath = '${audioDir.path}/$fileName';
          final newFile = File(newFullPath);
          
          if (await oldFile.exists()) {
            try {
              // Move the file to the new location
              await oldFile.copy(newFullPath);
              await oldFile.delete(); // Remove old file
              
              // Update database to new format (filename only)
              final migratedCommand = command.copyWithRealm(audioPath: fileName);
              commandsToUpdate.add(migratedCommand);
              cleanedCommands.add(migratedCommand);
            } catch (e) {
              // If move fails, clean up
              final cleanedCommand = command.copyWithRealm(audioPath: null);
              commandsToUpdate.add(cleanedCommand);
              cleanedCommands.add(cleanedCommand);
            }
          } else if (await newFile.exists()) {
            // File already exists in new location, just update database
            final migratedCommand = command.copyWithRealm(audioPath: fileName);
            commandsToUpdate.add(migratedCommand);
            cleanedCommands.add(migratedCommand);
          } else {
            // File doesn't exist anywhere, clean up
            final cleanedCommand = command.copyWithRealm(audioPath: null);
            commandsToUpdate.add(cleanedCommand);
            cleanedCommands.add(cleanedCommand);
          }
        } else {
          // New format - construct full path
          final directory = await getApplicationDocumentsDirectory();
          fullPath = '${directory.path}/audio/$audioPath';
          
          final file = File(fullPath);
          final exists = file.existsSync();
          if (exists) {
            final size = file.lengthSync();
            cleanedCommands.add(command); // Keep command with valid audio
          } else {
            // Create a new command without audioPath
            final cleanedCommand = command.copyWithRealm(audioPath: null);
            commandsToUpdate.add(cleanedCommand);
            cleanedCommands.add(cleanedCommand);
          }
        }
      } else {
        cleanedCommands.add(command); // Keep command without audio path
      }
      } catch (e, stackTrace) {
        Logger.error('Error processing command during migration',
          tag: 'QUEUE_MIGRATION',
          error: e,
          stackTrace: stackTrace
        );
        // Skip this command and continue with others
      }
    }
    
    // Update commands in Realm
    for (final command in commandsToUpdate) {
      try {
        _realmService.updateCommandAudioPath(command.id, null);
      } catch (e, stackTrace) {
        Logger.error('Failed to update command audio path during migration',
          tag: 'QUEUE_MIGRATION',
          error: e,
          stackTrace: stackTrace
        );
        // Continue with other commands
      }
    }
    
    if (commandsToUpdate.isNotEmpty) {
    }
    
    return cleanedCommands;
  }

  List<QueuedCommandRealm> get queuedCommands {
    for (var cmd in state) {
    }
    
    // Show ALL commands for now (no filtering)
    return state..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first
  }

  List<QueuedCommandRealm> get processingCommands =>
      state.where((cmd) => cmd.status == CommandStatus.processing.name).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  List<QueuedCommandRealm> get completedCommands => 
      state.where((cmd) => cmd.status == CommandStatus.completed.name).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Newest first

  List<QueuedCommandRealm> get failedCommands => 
      state.where((cmd) => cmd.status == CommandStatus.failed.name).toList()
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

  void removeCommand(String id) {
    try {
      Logger.info('Removing command from queue: $id', tag: 'QUEUE');
      
      // Store command data before any Realm operations to avoid invalidation
      final commandsToKeep = <QueuedCommandRealm>[];
      for (final cmd in state) {
        try {
          final cmdId = cmd.id;
          if (cmdId != id) {
            commandsToKeep.add(cmd);
          }
        } catch (e) {
          Logger.warning('Skipping invalid command in removeCommand: $e', tag: 'QUEUE');
          // Skip invalid commands
        }
      }
      
      // Remove from Realm
      _realmService.removeCommand(id);
      
      // Update state with pre-filtered commands
      state = commandsToKeep;
      
      Logger.info('Successfully removed command: $id', tag: 'QUEUE');
    } catch (e, stackTrace) {
      Logger.error('Failed to remove command: $id', 
        tag: 'QUEUE', 
        error: e, 
        stackTrace: stackTrace
      );
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
  try {
    final commands = ref.watch(queueProvider);
    // Apply filtering and sorting to the watched commands
    final sortedCommands = commands
      ..sort((a, b) {
        try {
          return b.createdAt.compareTo(a.createdAt); // Newest first
        } catch (e) {
          Logger.warning('Error sorting commands in queuedCommandsProvider: $e', tag: 'PROVIDER');
          return 0;
        }
      });
    
    // Limit to 30 most recent items for performance
    return sortedCommands.take(30).toList();
  } catch (e, stackTrace) {
    Logger.error('Error in queuedCommandsProvider', 
      tag: 'PROVIDER', 
      error: e, 
      stackTrace: stackTrace
    );
    return [];
  }
});

final processingCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  try {
    final commands = ref.watch(queueProvider);
    final filtered = commands
      .where((cmd) {
        try {
          return cmd.status == CommandStatus.processing.name;
        } catch (e) {
          Logger.warning('Skipping invalid command in processingCommandsProvider: $e', tag: 'PROVIDER');
          return false;
        }
      })
      .toList()
      ..sort((a, b) {
        try {
          return b.createdAt.compareTo(a.createdAt);
        } catch (e) {
          Logger.warning('Error sorting commands in processingCommandsProvider: $e', tag: 'PROVIDER');
          return 0;
        }
      });
    return filtered.take(30).toList();
  } catch (e, stackTrace) {
    Logger.error('Error in processingCommandsProvider', 
      tag: 'PROVIDER', 
      error: e, 
      stackTrace: stackTrace
    );
    return [];
  }
});

final completedCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  try {
    final commands = ref.watch(queueProvider);
    final filtered = commands
      .where((cmd) {
        try {
          return cmd.status == CommandStatus.completed.name;
        } catch (e) {
          Logger.warning('Skipping invalid command in completedCommandsProvider: $e', tag: 'PROVIDER');
          return false;
        }
      })
      .toList()
      ..sort((a, b) {
        try {
          return b.createdAt.compareTo(a.createdAt);
        } catch (e) {
          Logger.warning('Error sorting commands in completedCommandsProvider: $e', tag: 'PROVIDER');
          return 0;
        }
      });
    return filtered.take(30).toList();
  } catch (e, stackTrace) {
    Logger.error('Error in completedCommandsProvider', 
      tag: 'PROVIDER', 
      error: e, 
      stackTrace: stackTrace
    );
    return [];
  }
});

final failedCommandsProvider = Provider<List<QueuedCommandRealm>>((ref) {
  try {
    final commands = ref.watch(queueProvider);
    final filtered = commands
      .where((cmd) {
        try {
          return cmd.status == CommandStatus.failed.name;
        } catch (e) {
          // If we can't access the command properties, skip it
          Logger.warning('Skipping invalid command in failedCommandsProvider: $e', tag: 'PROVIDER');
          return false;
        }
      })
      .toList()
      ..sort((a, b) {
        try {
          return b.createdAt.compareTo(a.createdAt);
        } catch (e) {
          Logger.warning('Error sorting commands in failedCommandsProvider: $e', tag: 'PROVIDER');
          return 0;
        }
      });
    return filtered.take(30).toList();
  } catch (e, stackTrace) {
    Logger.error('Error in failedCommandsProvider', 
      tag: 'PROVIDER', 
      error: e, 
      stackTrace: stackTrace
    );
    return [];
  }
});
