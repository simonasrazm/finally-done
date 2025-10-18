import 'package:flutter/material.dart';
import '../../design_system/tokens.dart';

/// Manager for task animation states and transitions
class TaskAnimationManager extends ChangeNotifier {
  final Set<String> _completingTasks = <String>{};
  final Set<String> _uncompletingTasks = <String>{};
  final Set<String> _removingTasks = <String>{};
  final Set<String> _addingTasks = <String>{};

  // Getters for animation states
  Set<String> get completingTasks => _completingTasks;
  Set<String> get uncompletingTasks => _uncompletingTasks;
  Set<String> get removingTasks => _removingTasks;
  Set<String> get addingTasks => _addingTasks;

  /// Start completing animation for a task
  void startCompleting(String taskId) {
    if (_completingTasks.add(taskId)) {
      notifyListeners();
    }
  }

  /// Stop completing animation for a task
  void stopCompleting(String taskId) {
    if (_completingTasks.remove(taskId)) {
      notifyListeners();
    }
  }

  /// Start uncompleting animation for a task
  void startUncompleting(String taskId) {
    if (_uncompletingTasks.add(taskId)) {
      notifyListeners();
    }
  }

  /// Stop uncompleting animation for a task
  void stopUncompleting(String taskId) {
    if (_uncompletingTasks.remove(taskId)) {
      notifyListeners();
    }
  }

  /// Start removing animation for a task
  void startRemoving(String taskId) {
    if (_removingTasks.add(taskId)) {
      notifyListeners();
    }
  }

  /// Stop removing animation for a task
  void stopRemoving(String taskId) {
    if (_removingTasks.remove(taskId)) {
      notifyListeners();
    }
  }

  /// Start adding animation for a task
  void startAdding(String taskId) {
    if (_addingTasks.add(taskId)) {
      notifyListeners();
    }
  }

  /// Stop adding animation for a task
  void stopAdding(String taskId) {
    if (_addingTasks.remove(taskId)) {
      notifyListeners();
    }
  }

  /// Check if a task is currently animating
  bool isAnimating(String taskId) {
    return _completingTasks.contains(taskId) ||
           _uncompletingTasks.contains(taskId) ||
           _removingTasks.contains(taskId) ||
           _addingTasks.contains(taskId);
  }

  /// Check if a task is completing
  bool isCompleting(String taskId) => _completingTasks.contains(taskId);

  /// Check if a task is uncompleting
  bool isUncompleting(String taskId) => _uncompletingTasks.contains(taskId);

  /// Check if a task is being removed
  bool isRemoving(String taskId) => _removingTasks.contains(taskId);

  /// Check if a task is being added
  bool isAdding(String taskId) => _addingTasks.contains(taskId);

  /// Get animation duration for smooth transitions
  Duration get animationDuration => Duration(milliseconds: DesignTokens.animationSmooth);

  /// Get normal animation duration
  Duration get normalAnimationDuration => Duration(milliseconds: DesignTokens.animationNormal);
}
