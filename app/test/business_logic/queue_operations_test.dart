import 'package:flutter_test/flutter_test.dart';
import 'package:finally_done/models/queued_command.dart';

void main() {
  group('Queue Operations Business Logic', () {
    test('Command prioritization - voice vs text', () {
      final voiceCommand = QueuedCommandRealm(
        'voice-1',
        'Recording...',
        CommandStatus.recorded.name,
        DateTime.now().subtract(Duration(minutes: 5)),
        audioPath: 'audio1.m4a',
      );
      
      final textCommand = QueuedCommandRealm(
        'text-1',
        'Buy milk',
        CommandStatus.queued.name,
        DateTime.now().subtract(Duration(minutes: 3)),
      );
      
      // Voice commands should be prioritized over text commands
      expect(_getCommandPriority(voiceCommand), greaterThan(_getCommandPriority(textCommand)));
    });
    
    test('Command prioritization - by timestamp', () {
      final olderCommand = QueuedCommandRealm(
        'cmd-1',
        'Older command',
        CommandStatus.queued.name,
        DateTime.now().subtract(Duration(hours: 1)),
      );
      
      final newerCommand = QueuedCommandRealm(
        'cmd-2',
        'Newer command',
        CommandStatus.queued.name,
        DateTime.now().subtract(Duration(minutes: 30)),
      );
      
      // Newer commands should be prioritized
      expect(_getCommandPriority(newerCommand), greaterThan(_getCommandPriority(olderCommand)));
    });
    
    test('Command filtering - by status', () {
      final commands = [
        QueuedCommandRealm('1', 'Text 1', CommandStatus.queued.name, DateTime.now()),
        QueuedCommandRealm('2', 'Voice 1', CommandStatus.recorded.name, DateTime.now()),
        QueuedCommandRealm('3', 'Text 2', CommandStatus.processing.name, DateTime.now()),
        QueuedCommandRealm('4', 'Voice 2', CommandStatus.transcribing.name, DateTime.now()),
        QueuedCommandRealm('5', 'Text 3', CommandStatus.completed.name, DateTime.now()),
      ];
      
      final queuedCommands = _filterCommandsByStatus(commands, CommandStatus.queued);
      expect(queuedCommands.length, 1);
      expect(queuedCommands.first.id, '1');
      
      final processingCommands = _filterCommandsByStatus(commands, CommandStatus.processing);
      expect(processingCommands.length, 1);
      expect(processingCommands.first.id, '3');
    });
    
    test('Command sorting - by priority and timestamp', () {
      final now = DateTime.now();
      final commands = [
        QueuedCommandRealm('1', 'Old text', CommandStatus.queued.name, 
          now.subtract(Duration(minutes: 120))), // 2 hours ago
        QueuedCommandRealm('2', 'New voice', CommandStatus.recorded.name, 
          now.subtract(Duration(minutes: 5)), audioPath: 'audio2.m4a'),
        QueuedCommandRealm('3', 'New text', CommandStatus.queued.name, 
          now.subtract(Duration(minutes: 10))),
        QueuedCommandRealm('4', 'Old voice', CommandStatus.recorded.name, 
          now.subtract(Duration(minutes: 60)), audioPath: 'audio4.m4a'), // 1 hour ago
      ];
      
      final sortedCommands = _sortCommandsByPriority(commands);
      
      // Voice commands should come first, then by timestamp
      expect(sortedCommands[0].id, '2'); // New voice (5 min ago)
      expect(sortedCommands[1].id, '4'); // Old voice (60 min ago)
      expect(sortedCommands[2].id, '3'); // New text (10 min ago)
      expect(sortedCommands[3].id, '1'); // Old text (120 min ago)
    });
    
    test('Command cleanup - remove old completed commands', () {
      final commands = [
        QueuedCommandRealm('1', 'Recent completed', CommandStatus.completed.name, 
          DateTime.now().subtract(Duration(days: 1))),
        QueuedCommandRealm('2', 'Old completed', CommandStatus.completed.name, 
          DateTime.now().subtract(Duration(days: 30))),
        QueuedCommandRealm('3', 'Very old completed', CommandStatus.completed.name, 
          DateTime.now().subtract(Duration(days: 90))),
        QueuedCommandRealm('4', 'Active command', CommandStatus.queued.name, 
          DateTime.now().subtract(Duration(days: 1))),
      ];
      
      final cleanedCommands = _cleanupOldCommands(commands, maxAgeDays: 30);
      
      // Should keep recent completed, active commands, but remove old completed
      expect(cleanedCommands.length, 2);
      expect(cleanedCommands.any((c) => c.id == '1'), isTrue); // Recent completed
      expect(cleanedCommands.any((c) => c.id == '4'), isTrue); // Active
      expect(cleanedCommands.any((c) => c.id == '2'), isFalse); // Old completed
      expect(cleanedCommands.any((c) => c.id == '3'), isFalse); // Very old completed
    });
    
    test('Command deduplication - remove duplicate commands', () {
      final commands = [
        QueuedCommandRealm('1', 'Buy milk', CommandStatus.queued.name, 
          DateTime.now().subtract(Duration(minutes: 10))),
        QueuedCommandRealm('2', 'Buy milk', CommandStatus.queued.name, 
          DateTime.now().subtract(Duration(minutes: 5))),
        QueuedCommandRealm('3', 'Call doctor', CommandStatus.queued.name, 
          DateTime.now().subtract(Duration(minutes: 3))),
        QueuedCommandRealm('4', 'Buy milk', CommandStatus.completed.name, 
          DateTime.now().subtract(Duration(minutes: 1))),
      ];
      
      final deduplicatedCommands = _deduplicateCommands(commands);
      
      // Should keep only the most recent duplicate
      expect(deduplicatedCommands.length, 3);
      expect(deduplicatedCommands.any((c) => c.id == '2'), isTrue); // Most recent "Buy milk"
      expect(deduplicatedCommands.any((c) => c.id == '1'), isFalse); // Older duplicate
      expect(deduplicatedCommands.any((c) => c.id == '3'), isTrue); // Different command
      expect(deduplicatedCommands.any((c) => c.id == '4'), isTrue); // Completed (different status)
    });
  });
}

/// Business logic: Calculate command priority for processing
int _getCommandPriority(QueuedCommandRealm command) {
  int priority = 0;
  
  // Voice commands have higher priority
  if (command.audioPath != null && command.audioPath!.isNotEmpty) {
    priority += 1000;
  }
  
  // Newer commands have higher priority (inverse of age in minutes)
  final ageMinutes = DateTime.now().difference(command.createdAt).inMinutes;
  priority += (1000 - ageMinutes).clamp(0, 1000);
  
  return priority;
}

/// Business logic: Filter commands by status
List<QueuedCommandRealm> _filterCommandsByStatus(
  List<QueuedCommandRealm> commands, 
  CommandStatus status
) {
  return commands.where((cmd) => cmd.status == status.name).toList();
}

/// Business logic: Sort commands by priority
List<QueuedCommandRealm> _sortCommandsByPriority(List<QueuedCommandRealm> commands) {
  final sortedCommands = List<QueuedCommandRealm>.from(commands);
  sortedCommands.sort((a, b) => _getCommandPriority(b).compareTo(_getCommandPriority(a)));
  return sortedCommands;
}

/// Business logic: Clean up old completed commands
List<QueuedCommandRealm> _cleanupOldCommands(
  List<QueuedCommandRealm> commands, 
  {required int maxAgeDays}
) {
  final cutoffDate = DateTime.now().subtract(Duration(days: maxAgeDays));
  
  return commands.where((cmd) {
    // Keep non-completed commands
    if (cmd.status != CommandStatus.completed.name) {
      return true;
    }
    
    // Keep recent completed commands
    return cmd.createdAt.isAfter(cutoffDate);
  }).toList();
}

/// Business logic: Remove duplicate commands (keep most recent)
List<QueuedCommandRealm> _deduplicateCommands(List<QueuedCommandRealm> commands) {
  final Map<String, QueuedCommandRealm> uniqueCommands = {};
  
  for (final command in commands) {
    final key = '${command.text}_${command.status}';
    
    if (!uniqueCommands.containsKey(key) || 
        command.createdAt.isAfter(uniqueCommands[key]!.createdAt)) {
      uniqueCommands[key] = command;
    }
  }
  
  return uniqueCommands.values.toList();
}
