import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../providers/tasks_provider.dart';
import '../infrastructure/external_apis/integration_service.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../utils/sentry_performance.dart';
import '../generated/app_localizations.dart';
import '../widgets/task_list_selector_widget.dart';
import '../widgets/task_input_widget.dart';
import '../widgets/task_item_widget.dart';
import '../widgets/task_empty_state_widgets.dart';
import '../widgets/animated_title_widget.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSettings;

  const TasksScreen({super.key, this.onNavigateToSettings});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with WidgetsBindingObserver {
  String? _selectedTaskListId;
  final TextEditingController _newTaskController = TextEditingController();
  bool _showCompleted = false;
  DateTime? _lastAppResumeCall;

  // Dual AnimatedList keys for each mode (market standard)
  final GlobalKey<AnimatedListState> _incompleteListKey =
      GlobalKey<AnimatedListState>();
  final GlobalKey<AnimatedListState> _allItemsListKey =
      GlobalKey<AnimatedListState>();

  // Local lists for each mode
  List<google_tasks.Task> _incompleteTasks = [];
  List<google_tasks.Task> _allTasks = [];

  // Track tasks being updated for immediate visual feedback - SEPARATE for each list
  Set<String> _incompleteTasksUpdating = {};
  Set<String> _allTasksUpdating = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Track screen load performance
    sentryPerformance.monitorTransaction(
      PerformanceTransactions.screenTasks,
      PerformanceOps.screenLoad,
      () async {
        await _initializeTaskList();
      },
      data: {
        'screen': 'tasks',
        'has_task_initialization': true,
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // When user returns to the app, refresh tasks and check connectivity
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();

      // Debounce multiple rapid app resume calls (within 1 second)
      if (_lastAppResumeCall != null &&
          now.difference(_lastAppResumeCall!).inMilliseconds < 1000) {
        return;
      }

      _lastAppResumeCall = now;

      // Only call refreshTasks - it handles both task fetching and connectivity
      ref.read(tasksProvider.notifier).refreshTasks();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _newTaskController.dispose();
    super.dispose();
  }

  Future<void> _initializeTaskList() async {
    final integrationService = ref.read(integrationServiceProvider);

    if (!integrationService.isAuthenticated) {
      return;
    }

    // Wait for the tasks service to be available
    await Future.delayed(Duration(milliseconds: DesignTokens.delayShort));

    final defaultTaskList = await ref.read(defaultTaskListProvider.future);
    if (defaultTaskList != null && mounted) {
      setState(() {
        _selectedTaskListId = defaultTaskList.id;
      });
      ref.read(tasksProvider.notifier).setTaskList(defaultTaskList.id!);
    }
  }

  Future<void> _createTask() async {
    try {
      await ref.read(tasksProvider.notifier).createTask(
            _newTaskController.text,
            taskListId: _selectedTaskListId,
          );

      _newTaskController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added')),
      );
    } catch (e, stackTrace) {
      print('Error adding task: $e');
      Sentry.captureException(e, stackTrace: stackTrace);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add task'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    if (!_showCompleted) {
      await _toggleIncompleteTaskStatus(taskId);
    } else {
      await _toggleAllItemsTaskStatus(taskId);
    }
  }

  Future<void> _toggleIncompleteTaskStatus(String taskId) async {
    final tasksState = ref.read(tasksProvider);
    final task = tasksState.tasks.firstWhere((t) => t.id == taskId);
    final isCompleted = task.status == 'completed';

    // Only handle completing tasks in incomplete mode
    if (!isCompleted) {
      // Show checked state immediately
      _incompleteTasksUpdating.add(taskId);
      if (mounted) setState(() {});

      try {
        final success =
            await ref.read(tasksProvider.notifier).completeTask(taskId);

        // Clear loading state after API call completes
        _incompleteTasksUpdating.remove(taskId);
        if (mounted) setState(() {});

        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.taskCompleted),
              duration: Duration(milliseconds: DesignTokens.delaySnackbarQuick),
            ),
          );

          // Remove task with animation
          _removeTaskFromIncompleteList(taskId);
        } else {
          _showTaskError('complete');
        }
      } catch (e, stackTrace) {
        print('Error completing task: $e');
        Sentry.captureException(e, stackTrace: stackTrace);

        // Revert visual state on error
        _incompleteTasksUpdating.remove(taskId);
        if (mounted) setState(() {});

        _showTaskError('complete');
      }
    }
  }

  Future<void> _toggleAllItemsTaskStatus(String taskId) async {
    final tasksState = ref.read(tasksProvider);
    final task = tasksState.tasks.firstWhere((t) => t.id == taskId);
    final isCompleted = task.status == 'completed';

    // Show loading state immediately
    _allTasksUpdating.add(taskId);
    if (mounted) setState(() {});

    try {
      bool success;
      if (isCompleted) {
        success = await ref.read(tasksProvider.notifier).uncompleteTask(taskId);
      } else {
        success = await ref.read(tasksProvider.notifier).completeTask(taskId);
      }

      // Clear loading state after delay (or immediately on failure)
      _allTasksUpdating.remove(taskId);
      if (mounted) setState(() {});

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(!isCompleted
                ? AppLocalizations.of(context)!.taskCompleted
                : AppLocalizations.of(context)!.taskUncompleted),
            duration: Duration(milliseconds: DesignTokens.delaySnackbarQuick),
          ),
        );

        // Update task in all items list
        _updateTaskInAllItemsList(taskId);
      } else {
        _showTaskError(isCompleted ? 'uncomplete' : 'complete');
      }
    } catch (e, stackTrace) {
      print('Error toggling all items task status: $e');
      Sentry.captureException(e, stackTrace: stackTrace);

      // Revert visual state on error
      _allTasksUpdating.remove(taskId);
      if (mounted) setState(() {});

      _showTaskError(isCompleted ? 'uncomplete' : 'complete');
    }
  }

  void _showTaskError(String action) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to $action task'),
        backgroundColor: AppColors.error,
        duration: Duration(milliseconds: DesignTokens.delaySnackbarQuick),
      ),
    );
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await ref.read(tasksProvider.notifier).deleteTask(taskId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.taskDeleted)),
      );

      // Remove from AnimatedList with animation
      if (!_showCompleted) {
        _removeTaskFromIncompleteList(taskId);
      } else {
        // For all items mode, just trigger rebuild
        setState(() {});
      }
    } catch (e, stackTrace) {
      print('Error deleting task: $e');
      Sentry.captureException(e, stackTrace: stackTrace);

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete task'),
          backgroundColor: AppColors.error,
          duration: Duration(milliseconds: DesignTokens.delaySnackbarQuick),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final integrationService = ref.watch(integrationServiceProvider);
    final tasksState = ref.watch(tasksProvider);
    // Only watch taskListsProvider when we need to show the task list selector
    final taskListsAsync = ref.watch(taskListsProvider);

    return Scaffold(
      backgroundColor: AppColors.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: DesignTokens.elevation0,
        title: AnimatedTitleWidget(
          text: AppLocalizations.of(context)!.tasks,
          style: AppTypography.title1.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showCompleted ? Icons.visibility : Icons.visibility_off,
              color: AppColors.getTextPrimaryColor(context),
            ),
            onPressed: () {
              // Clear any loading states when switching lists
              _incompleteTasksUpdating.clear();
              _allTasksUpdating.clear();
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: _showCompleted
                ? AppLocalizations.of(context)!.hideCompleted
                : AppLocalizations.of(context)!.showCompleted,
          ),
          IconButton(
            icon: Icon(Icons.refresh,
                color: AppColors.getTextPrimaryColor(context)),
            onPressed: () {
              ref.read(tasksProvider.notifier).refreshTasks();
            },
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Task List Selector
          if (taskListsAsync.hasValue && taskListsAsync.value!.isNotEmpty)
            TaskListSelectorWidget(
              selectedTaskListId: _selectedTaskListId,
              taskLists: taskListsAsync.value!,
              onTaskListChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedTaskListId = newValue;
                  });
                  ref.read(tasksProvider.notifier).setTaskList(newValue);
                }
              },
            ),

          // Add Task Input
          if (integrationService.isAuthenticated && _selectedTaskListId != null)
            TaskInputWidget(
              controller: _newTaskController,
              onCreateTask: _createTask,
            ),

          // Tasks List
          Expanded(
            child: _buildTasksContent(integrationService, tasksState),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksContent(
      IntegrationService integrationService, TasksState tasksState) {
    if (!integrationService.isAuthenticated) {
      return NotConnectedView(
          onNavigateToSettings: widget.onNavigateToSettings);
    }

    if (tasksState.isLoading) {
      return const LoadingView();
    }

    if (tasksState.error != null) {
      return ErrorView(
        error: tasksState.error!,
        onRetry: () => ref.read(tasksProvider.notifier).retryTasks(),
      );
    }

    if (tasksState.tasks.isEmpty) {
      return const EmptyView();
    }

    return _buildTasksList(tasksState);
  }

  Widget _buildTasksList(TasksState tasksState) {
    // Update local lists from provider data
    _incompleteTasks = tasksState.incompleteTasks;
    _allTasks = tasksState.tasks;

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).refreshTasks(),
      child: _showCompleted ? _buildAllItemsList() : _buildIncompleteList(),
    );
  }

  Widget _buildIncompleteList() {
    return AnimatedList(
      key: _incompleteListKey,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      initialItemCount: _incompleteTasks.length,
      itemBuilder: (context, index, animation) {
        if (index >= _incompleteTasks.length) return const SizedBox.shrink();

        final task = _incompleteTasks[index];
        final hasAdditionalContent =
            task.notes?.isNotEmpty == true || task.due != null;

        return FadeTransition(
          opacity: animation,
          child: Column(
            key: ValueKey('task_item_${task.id}'),
            children: [
              TaskItemWidget(
                task: task,
                isCompleted: false, // Incomplete tasks are never completed
                showCompleted: false,
                isLoading: _incompleteTasksUpdating.contains(task.id),
                onTap: () => _toggleTaskStatus(task.id!),
                onCheckboxChanged: () => _toggleTaskStatus(task.id!),
                onDelete: () => _deleteTask(task.id!),
                onEdit: () => _editTask(task),
              ),
              if (index < _incompleteTasks.length - 1)
                Divider(
                  height: hasAdditionalContent
                      ? DesignTokens.spacing1
                      : DesignTokens.spacing0,
                  thickness: 0.5,
                  color: AppColors.separatorOpaque
                      .withValues(alpha: DesignTokens.opacity20),
                  indent: DesignTokens.spacing8,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAllItemsList() {
    return AnimatedList(
      key: _allItemsListKey,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      initialItemCount: _allTasks.length,
      itemBuilder: (context, index, animation) {
        if (index >= _allTasks.length) return const SizedBox.shrink();

        final task = _allTasks[index];
        final isCompleted = task.status == 'completed';
        final hasAdditionalContent =
            task.notes?.isNotEmpty == true || task.due != null;

        return FadeTransition(
          opacity: animation,
          child: Column(
            key: ValueKey('task_item_${task.id}'),
            children: [
              TaskItemWidget(
                task: task,
                isCompleted: isCompleted,
                showCompleted: true,
                isLoading: _allTasksUpdating.contains(task.id),
                onTap: () => _toggleTaskStatus(task.id!),
                onCheckboxChanged: () => _toggleTaskStatus(task.id!),
                onDelete: () => _deleteTask(task.id!),
                onEdit: () => _editTask(task),
              ),
              if (index < _allTasks.length - 1)
                Divider(
                  height: hasAdditionalContent
                      ? DesignTokens.spacing1
                      : DesignTokens.spacing0,
                  thickness: 0.5,
                  color: AppColors.separatorOpaque
                      .withValues(alpha: DesignTokens.opacity20),
                  indent: DesignTokens.spacing8,
                ),
            ],
          ),
        );
      },
    );
  }

  void _removeTaskFromIncompleteList(String taskId) {
    final taskIndex = _incompleteTasks.indexWhere((t) => t.id == taskId);

    if (taskIndex != -1) {
      final task = _incompleteTasks.removeAt(taskIndex);

      // Also update the all tasks list to keep it in sync
      final allTasksIndex = _allTasks.indexWhere((t) => t.id == taskId);
      if (allTasksIndex != -1) {
        final updatedTask = google_tasks.Task(
          id: _allTasks[allTasksIndex].id,
          title: _allTasks[allTasksIndex].title,
          notes: _allTasks[allTasksIndex].notes,
          status: 'completed', // Mark as completed
          due: _allTasks[allTasksIndex].due,
          completed: _allTasks[allTasksIndex].completed,
          deleted: _allTasks[allTasksIndex].deleted,
          hidden: _allTasks[allTasksIndex].hidden,
          links: _allTasks[allTasksIndex].links,
          parent: _allTasks[allTasksIndex].parent,
          position: _allTasks[allTasksIndex].position,
          selfLink: _allTasks[allTasksIndex].selfLink,
          updated: _allTasks[allTasksIndex].updated,
        );
        _allTasks[allTasksIndex] = updatedTask;
      }

      _incompleteListKey.currentState?.removeItem(
        taskIndex,
        (context, animation) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1.0, 0.0), // Start from right
            end: Offset.zero, // End at normal position
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: _buildTaskItemWidget(task),
          ),
        ),
        duration: Duration(
            milliseconds: DesignTokens.animationNormal), // Quicker slide-out
      );

      // Loading state will be cleared when API call completes
    }
  }

  void _addTaskToIncompleteList(String taskId) {
    final tasksState = ref.read(tasksProvider);
    final task = tasksState.tasks.firstWhere((t) => t.id == taskId);

    _incompleteTasks.add(task);

    // Also update the all tasks list to keep it in sync
    final allTasksIndex = _allTasks.indexWhere((t) => t.id == taskId);
    if (allTasksIndex != -1) {
      final updatedTask = google_tasks.Task(
        id: _allTasks[allTasksIndex].id,
        title: _allTasks[allTasksIndex].title,
        notes: _allTasks[allTasksIndex].notes,
        status: 'needsAction', // Mark as incomplete
        due: _allTasks[allTasksIndex].due,
        completed: _allTasks[allTasksIndex].completed,
        deleted: _allTasks[allTasksIndex].deleted,
        hidden: _allTasks[allTasksIndex].hidden,
        links: _allTasks[allTasksIndex].links,
        parent: _allTasks[allTasksIndex].parent,
        position: _allTasks[allTasksIndex].position,
        selfLink: _allTasks[allTasksIndex].selfLink,
        updated: _allTasks[allTasksIndex].updated,
      );
      _allTasks[allTasksIndex] = updatedTask;
    }

    _incompleteListKey.currentState?.insertItem(
      _incompleteTasks.length - 1,
      duration: Duration(milliseconds: DesignTokens.animationTaskList),
    );
  }

  void _updateTaskInAllItemsList(String taskId) {
    // For all items mode, find and update the task in the list
    final taskIndex = _allTasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      // Update the task in our local list by creating a new task with updated status
      final currentTask = _allTasks[taskIndex];
      final newStatus =
          currentTask.status == 'completed' ? 'needsAction' : 'completed';

      // Create a new task with updated status
      final updatedTask = google_tasks.Task(
        id: currentTask.id,
        title: currentTask.title,
        notes: currentTask.notes,
        status: newStatus,
        due: currentTask.due,
        completed: currentTask.completed,
        deleted: currentTask.deleted,
        hidden: currentTask.hidden,
        links: currentTask.links,
        parent: currentTask.parent,
        position: currentTask.position,
        selfLink: currentTask.selfLink,
        updated: currentTask.updated,
      );

      _allTasks[taskIndex] = updatedTask;

      // Also update the incomplete tasks list to keep it in sync
      if (newStatus == 'needsAction') {
        // Task was uncompleted, add it to incomplete list
        _incompleteTasks.add(updatedTask);
      } else {
        // Task was completed, remove it from incomplete list
        _incompleteTasks.removeWhere((t) => t.id == taskId);
      }

      // Trigger rebuild to show the updated checkbox
      setState(() {});
    }
  }

  Widget _buildTaskItemWidget(google_tasks.Task task) {
    final isCompleted = task.status == 'completed';
    final hasAdditionalContent =
        task.notes?.isNotEmpty == true || task.due != null;

    return Column(
      key: ValueKey('task_item_${task.id}'),
      children: [
        TaskItemWidget(
          task: task,
          isCompleted: isCompleted,
          showCompleted: _showCompleted,
          isLoading: _allTasksUpdating.contains(task.id),
          onTap: () => _toggleTaskStatus(task.id!),
          onCheckboxChanged: () => _toggleTaskStatus(task.id!),
          onDelete: () => _deleteTask(task.id!),
          onEdit: () => _editTask(task),
        ),
        Divider(
          height: hasAdditionalContent
              ? DesignTokens.spacing1
              : DesignTokens.spacing0,
          thickness: 0.5,
          color: AppColors.separatorOpaque
              .withValues(alpha: DesignTokens.opacity20),
          indent: DesignTokens.spacing8,
        ),
      ],
    );
  }

  void _editTask(google_tasks.Task task) {
    // TODO: Implement task editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit task: ${task.title}')),
    );
  }
}
