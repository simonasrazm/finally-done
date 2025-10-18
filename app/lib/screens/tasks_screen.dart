import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../providers/tasks_provider.dart';
import '../infrastructure/external_apis/integration_service.dart';
import '../core/tasks/task_animation_service.dart';
import '../core/tasks/task_operations_service.dart';
import '../utils/sentry_performance.dart';
import '../generated/app_localizations.dart';
import '../widgets/task_list_selector_widget.dart';
import '../widgets/task_input_widget.dart';
import '../widgets/task_list_widgets.dart';
import '../widgets/task_empty_state_widgets.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const TasksScreen({super.key, this.onNavigateToSettings});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> with WidgetsBindingObserver {
  String? _selectedTaskListId;
  final TextEditingController _newTaskController = TextEditingController();
  bool _showCompleted = false;
  DateTime? _lastAppResumeCall;
  
  // Animation manager for managing task animations
  final TaskAnimationManager _animationService = TaskAnimationManager();
  
  // AnimatedList key for smooth transitions
  final GlobalKey<AnimatedListState> _animatedListKey = GlobalKey<AnimatedListState>();

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
    await TaskInteractionService.createTask(
      _newTaskController.text,
      ref,
      context,
      _newTaskController,
    );
  }

  Future<void> _toggleTaskStatus(String taskId) async {
    await TaskInteractionService.toggleTaskStatus(
      taskId,
      ref,
      context,
      _animationService,
      _showCompleted,
    );
    setState(() {}); // Trigger UI update
  }

  Future<void> _completeTask(String taskId) async {
    await TaskInteractionService.completeTask(
      taskId,
      ref,
      context,
      _animationService,
      _showCompleted,
    );
    setState(() {}); // Trigger UI update
  }

  Future<void> _uncompleteTask(String taskId) async {
    await TaskInteractionService.uncompleteTask(
      taskId,
      ref,
      context,
      _animationService,
      _showCompleted,
    );
    setState(() {}); // Trigger UI update
  }

  Future<void> _deleteTask(String taskId) async {
    await TaskInteractionService.deleteTask(taskId, ref, context);
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
        title: Text(
          AppLocalizations.of(context)!.googleTasks,
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
              setState(() {
                _showCompleted = !_showCompleted;
              });
            },
            tooltip: _showCompleted 
                ? AppLocalizations.of(context)!.hideCompleted
                : AppLocalizations.of(context)!.showCompleted,
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.getTextPrimaryColor(context)),
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

  Widget _buildTasksContent(IntegrationService integrationService, TasksState tasksState) {
    if (!integrationService.isAuthenticated) {
      return NotConnectedView(onNavigateToSettings: widget.onNavigateToSettings);
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
    final tasksToShow = _showCompleted ? tasksState.tasks : tasksState.incompleteTasks;
    
    // Use a stable key to prevent unnecessary rebuilds
    final listKey = ValueKey('tasks_list_${_showCompleted ? 'all' : 'incomplete'}_${tasksToShow.length}');
    
    return RefreshIndicator(
      key: listKey,
      onRefresh: () => ref.read(tasksProvider.notifier).refreshTasks(),
      child: AnimatedTaskListWidget(
        tasks: tasksToShow,
        showCompleted: _showCompleted,
        animationService: _animationService,
        animatedListKey: _animatedListKey,
        onTaskTap: _toggleTaskStatus,
        onCheckboxChanged: _toggleTaskStatus,
        onDelete: _deleteTask,
        onEdit: _editTask,
      ),
    );
  }


  void _editTask(google_tasks.Task task) {
    // TODO: Implement task editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit task: ${task.title}')),
    );
  }
}