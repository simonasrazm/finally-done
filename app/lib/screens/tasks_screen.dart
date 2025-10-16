import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import 'package:sentry_flutter/sentry_flutter.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../providers/tasks_provider.dart';
import '../services/integration_service.dart';
import '../services/integrations/integration_manager.dart';
import '../utils/sentry_performance.dart';
import '../generated/app_localizations.dart';

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
  
  // Animation state management
  final Set<String> _completingTasks = <String>{};
  final Set<String> _uncompletingTasks = <String>{};
  final Set<String> _removingTasks = <String>{};
  final Set<String> _addingTasks = <String>{};
  
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
    if (_newTaskController.text.trim().isEmpty) return;

    await ref.read(tasksProvider.notifier).createTask(
      _newTaskController.text.trim(),
    );
    
    _newTaskController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.taskCreated)),
    );
  }

  Future<void> _completeTask(String taskId) async {
    // Add to completing set and update UI
    setState(() {
      _completingTasks.add(taskId);
    });
    
    // Monitor task completion performance
    final transaction = Sentry.startTransaction(
      'task.complete',
      'ui.interaction',
      bindToScope: true,
    );
    
    try {
      final success = await ref.read(tasksProvider.notifier).completeTask(taskId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
        );
        
        // Handle animation based on view mode
        if (!_showCompleted) {
          // In "incomplete only" mode: animate task out, then remove with animation
          await Future.delayed(Duration(milliseconds: DesignTokens.animationSmooth)); // Let slide animation complete
          // Remove task with animated list animation
          _removeTaskWithAnimation(taskId);
        } else {
          // In "all items" mode: update state immediately for checkbox animation
          ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'completed');
          await Future.delayed(Duration(milliseconds: DesignTokens.animationNormal)); // Let checkbox animation complete
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete task'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always remove from completing set and update UI
      setState(() {
        _completingTasks.remove(taskId);
      });
      
      // Finish Sentry transaction
      transaction.setData('view_mode', _showCompleted ? 'all_items' : 'incomplete_only');
      transaction.setData('animation_duration', _showCompleted ? 200 : 300);
      transaction.finish(status: const SpanStatus.ok());
    }
  }

  Future<void> _uncompleteTask(String taskId) async {
    // Add to uncompleting set and update UI
    setState(() {
      _uncompletingTasks.add(taskId);
    });
    
    // Monitor task uncompletion performance
    final transaction = Sentry.startTransaction(
      'task.uncomplete',
      'ui.interaction',
      bindToScope: true,
    );
    
    try {
      final success = await ref.read(tasksProvider.notifier).uncompleteTask(taskId);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.taskUncompleted)),
        );
        
        // Handle animation based on view mode
        if (!_showCompleted) {
          // In "incomplete only" mode: animate task in, then add with animation
          await Future.delayed(Duration(milliseconds: DesignTokens.animationSmooth)); // Let slide animation complete
          // Add task with animated list animation
          _addTaskWithAnimation(taskId);
        } else {
          // In "all items" mode: update state immediately for checkbox animation
          ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'needsAction');
          await Future.delayed(Duration(milliseconds: DesignTokens.animationNormal)); // Let checkbox animation complete
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.failedToUncompleteTask),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always remove from uncompleting set and update UI
      setState(() {
        _uncompletingTasks.remove(taskId);
      });
      
      // Finish Sentry transaction
      transaction.setData('view_mode', _showCompleted ? 'all_items' : 'incomplete_only');
      transaction.setData('animation_duration', _showCompleted ? 200 : 300);
      transaction.finish(status: const SpanStatus.ok());
    }
  }

  void _removeTaskWithAnimation(String taskId) async {
    // Add to removing set to trigger height animation
    setState(() {
      _removingTasks.add(taskId);
    });
    
    // Wait for the height collapse animation to complete
    await Future.delayed(Duration(milliseconds: DesignTokens.animationSmooth));
    
    // Update the state to actually remove the task from the list
    ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'completed');
    
    // Remove from removing set
    setState(() {
      _removingTasks.remove(taskId);
    });
  }

  void _addTaskWithAnimation(String taskId) async {
    // Update the state first to add the task back
    ref.read(tasksProvider.notifier).updateTaskStatusLocally(taskId, 'needsAction');
    
    // Add to adding set to trigger fade-in animation
    setState(() {
      _addingTasks.add(taskId);
    });
    
    // Wait for the fade-in animation to complete
    await Future.delayed(Duration(milliseconds: DesignTokens.animationSmooth));
    
    // Remove from adding set
    setState(() {
      _addingTasks.remove(taskId);
    });
  }

  Future<void> _deleteTask(String taskId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteTask),
        content: Text(AppLocalizations.of(context)!.deleteTaskConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(tasksProvider.notifier).deleteTask(taskId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.taskDeleted)),
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
            Container(
              padding: EdgeInsets.all(DesignTokens.componentPadding),
              child: Row(
                children: [
                  Icon(Icons.list, color: AppColors.getTextPrimaryColor(context)),
                  SizedBox(width: DesignTokens.iconSpacing),
                  Expanded(
                    child: DropdownButton<String>(
                      value: _selectedTaskListId,
                      hint: Text(
                        AppLocalizations.of(context)!.selectTaskList,
                        style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
                      ),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTaskListId = newValue;
                          });
                          ref.read(tasksProvider.notifier).setTaskList(newValue);
                        }
                      },
                      items: taskListsAsync.value!.map<DropdownMenuItem<String>>((google_tasks.TaskList list) {
                        return DropdownMenuItem<String>(
                          value: list.id,
                          child: Text(
                            list.title ?? 'Untitled List',
                            style: AppTypography.body.copyWith(color: AppColors.getTextPrimaryColor(context)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

          // Add Task Input
          if (integrationService.isAuthenticated && _selectedTaskListId != null)
            Container(
              padding: EdgeInsets.all(DesignTokens.componentPadding),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newTaskController,
                      style: AppTypography.body.copyWith(color: AppColors.getTextPrimaryColor(context)),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.addNewTask,
                        hintStyle: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          borderSide: BorderSide(color: AppColors.separatorOpaque),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          borderSide: BorderSide(color: AppColors.separatorOpaque),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                          borderSide: BorderSide(color: AppColors.primary, width: DesignTokens.borderWidth2),
                        ),
                        filled: true,
                        fillColor: AppColors.getSecondaryBackgroundColor(context),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: DesignTokens.inputPadding,
                          vertical: DesignTokens.spacing2,
                        ),
                      ),
                      onSubmitted: (_) => _createTask(),
                    ),
                  ),
                  SizedBox(width: DesignTokens.spacing2),
                  ElevatedButton.icon(
                    onPressed: _createTask,
                    icon: const Icon(Icons.add),
                    label: Text(AppLocalizations.of(context)!.add),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.backgroundSecondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.componentPadding,
                        vertical: DesignTokens.spacing2,
                      ),
                    ),
                  ),
                ],
              ),
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
      return _buildNotConnectedView();
    }

    if (tasksState.isLoading) {
      return _buildLoadingView();
    }

    if (tasksState.error != null) {
      return _buildErrorView(tasksState.error!);
    }

    if (tasksState.tasks.isEmpty) {
      return _buildEmptyView();
    }

    return _buildTasksList(tasksState);
  }

  Widget _buildNotConnectedView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.sectionSpacing + DesignTokens.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.cloud_off,
              size: DesignTokens.icon4xl,
              color: AppColors.getTextSecondaryColor(context),
            ),
            SizedBox(height: DesignTokens.sectionSpacing),
            Text(
              AppLocalizations.of(context)!.notConnectedToGoogle,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.connectToGoogleToViewTasks,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: widget.onNavigateToSettings,
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.goToSettings),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundSecondary,
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.componentPadding,
                  vertical: DesignTokens.spacing3,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: AppColors.primary),
          SizedBox(height: DesignTokens.componentPadding),
          Text(
            AppLocalizations.of(context)!.loadingTasks,
            style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(String error) {
    // Log technical error to Sentry and console
    
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.componentPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: DesignTokens.icon4xl,
              color: AppColors.error,
            ),
            SizedBox(height: DesignTokens.componentPadding),
            Text(
              AppLocalizations.of(context)!.errorLoadingTasks,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.errorLoadingTasksDescription,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(tasksProvider.notifier).retryTasks();
              },
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.tryAgain),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.sectionSpacing + DesignTokens.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt_outlined,
              size: DesignTokens.icon4xl,
              color: AppColors.getTextSecondaryColor(context),
            ),
            SizedBox(height: DesignTokens.sectionSpacing),
            Text(
              AppLocalizations.of(context)!.noTasksFound,
              style: AppTypography.title3.copyWith(color: AppColors.getTextPrimaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.spacing2),
            Text(
              AppLocalizations.of(context)!.addYourFirstTask,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(TasksState tasksState) {
    final tasksToShow = _showCompleted ? tasksState.tasks : tasksState.incompleteTasks;
    
    // Use a stable key to prevent unnecessary rebuilds
    final listKey = ValueKey('tasks_list_${_showCompleted ? 'all' : 'incomplete'}_${tasksToShow.length}');
    
    return RefreshIndicator(
      key: listKey,
      onRefresh: () => ref.read(tasksProvider.notifier).refreshTasks(),
      child: _showCompleted 
        ? _buildAnimatedList(tasksToShow) // Use AnimatedList for "all items" view
        : _buildRegularList(tasksToShow), // Use regular ListView for "incomplete only" view
    );
  }

  Widget _buildAnimatedList(List<google_tasks.Task> tasks) {
    return AnimatedList(
      key: _animatedListKey,
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      initialItemCount: tasks.length,
      itemBuilder: (context, index, animation) {
        if (index >= tasks.length) return SizedBox.shrink();
        
        final task = tasks[index];
        final isCompleted = task.status == 'completed';
        final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
        
        return SlideTransition(
          position: animation.drive(
            Tween<Offset>(begin: Offset(1, 0), end: Offset.zero)
                .chain(CurveTween(curve: Curves.easeOutCubic)),
          ),
          child: FadeTransition(
            opacity: animation,
            child: Column(
              key: ValueKey('task_item_${task.id}'),
              children: [
                _buildCompactTaskItem(task, isCompleted),
                if (index < tasks.length - 1)
                  Divider(
                    height: hasAdditionalContent ? DesignTokens.spacing1 : DesignTokens.spacing0,
                    thickness: 0.5,
                    color: AppColors.separatorOpaque.withOpacity(DesignTokens.opacity20),
                    indent: DesignTokens.spacing8, // Align with content
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRegularList(List<google_tasks.Task> tasks) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing1,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final isCompleted = task.status == 'completed';
        final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
        
        return Column(
          key: ValueKey('task_item_${task.id}'),
          children: [
            _buildCompactTaskItem(task, isCompleted),
            if (index < tasks.length - 1)
              Divider(
                height: hasAdditionalContent ? DesignTokens.spacing1 : DesignTokens.spacing0,
                thickness: 0.5,
                color: AppColors.separatorOpaque.withOpacity(DesignTokens.opacity20),
                indent: DesignTokens.spacing8, // Align with content
              ),
          ],
        );
      },
    );
  }

  Widget _buildCompactTaskItem(google_tasks.Task task, bool isCompleted) {
    // Determine if task has additional content (notes or due date)
    final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
    
    // Check if this task is currently being animated
    final isCompleting = _completingTasks.contains(task.id);
    final isUncompleting = _uncompletingTasks.contains(task.id);
    final isRemoving = _removingTasks.contains(task.id);
    final isAdding = _addingTasks.contains(task.id);
    final isAnimating = isCompleting || isUncompleting || isRemoving || isAdding;
    
    return AnimatedOpacity(
      opacity: isAdding ? 0.0 : 1.0, // Fade in when adding
      duration: Duration(milliseconds: DesignTokens.animationSmooth),
      curve: Curves.easeInOutCubic,
      child: AnimatedContainer(
        key: ValueKey('task_container_${task.id}'),
        duration: Duration(milliseconds: DesignTokens.animationSmooth), // Smooth list transitions
        curve: Curves.easeInOutCubic, // Smoother curve
        height: isRemoving ? 0 : null, // Collapse height when removing
        transform: isCompleting && !_showCompleted 
            ? Matrix4.translationValues(MediaQuery.of(context).size.width, 0, 0)
            : isUncompleting && !_showCompleted
                ? Matrix4.translationValues(-MediaQuery.of(context).size.width, 0, 0)
                : Matrix4.identity(),
      child: InkWell(
      onTap: () {
        if (task.id != null && task.id!.isNotEmpty) {
          if (isCompleted) {
            _uncompleteTask(task.id!);
          } else {
            _completeTask(task.id!);
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: Task ID is missing'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing3,
          vertical: hasAdditionalContent ? DesignTokens.spacing2 : DesignTokens.spacing0,
        ),
        child: Row(
          children: [
            // Provider indicator
            _buildProviderIndicator(),
            SizedBox(width: DesignTokens.spacing2),
            
            // Checkbox
            Checkbox(
              value: isCompleted,
              onChanged: (value) {
                if (task.id != null && task.id!.isNotEmpty) {
                  if (isCompleted) {
                    _uncompleteTask(task.id!);
                  } else {
                    _completeTask(task.id!);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: Task ID is missing'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              activeColor: AppColors.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
              ),
            ),
            SizedBox(width: hasAdditionalContent ? DesignTokens.spacing2 : DesignTokens.spacing1),
            
            // Task content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Task title
                  Text(
                    task.title ?? 'Untitled Task',
                    style: AppTypography.body.copyWith(
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      color: isCompleted 
                          ? AppColors.getTextSecondaryColor(context) 
                          : AppColors.getTextPrimaryColor(context),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  // Task metadata row
                  if (hasAdditionalContent)
                    SizedBox(height: DesignTokens.spacing1),
                  if (hasAdditionalContent)
                    Row(
                      children: [
                        // Notes preview
                        if (task.notes?.isNotEmpty == true) ...[
                          Icon(
                            Icons.note_outlined,
                            size: DesignTokens.iconSm,
                            color: AppColors.getTextSecondaryColor(context),
                          ),
                          SizedBox(width: DesignTokens.spacing1),
                          Expanded(
                            child: Text(
                              task.notes!,
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.getTextSecondaryColor(context),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        
                        // Due date
                        if (task.due != null) ...[
                          if (task.notes?.isNotEmpty == true)
                            SizedBox(width: DesignTokens.spacing2),
                          Icon(
                            Icons.schedule_outlined,
                            size: DesignTokens.iconSm,
                            color: _getDueDateColor(task.due!),
                          ),
                          SizedBox(width: DesignTokens.spacing1),
                          Text(
                            _formatDueDate(task.due!),
                            style: AppTypography.caption1.copyWith(
                              color: _getDueDateColor(task.due!),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            
            // Action menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                size: DesignTokens.iconMd,
                color: AppColors.getTextSecondaryColor(context),
              ),
              tooltip: AppLocalizations.of(context)!.moreOptions,
              onSelected: (value) {
                switch (value) {
                  case 'delete':
                    _deleteTask(task.id!);
                    break;
                  case 'edit':
                    _editTask(task);
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppColors.primary, size: DesignTokens.iconSm),
                      SizedBox(width: DesignTokens.iconSpacing),
                      Text(
                        AppLocalizations.of(context)!.edit,
                        style: AppTypography.body.copyWith(
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: AppColors.error, size: DesignTokens.iconSm),
                      SizedBox(width: DesignTokens.iconSpacing),
                      Text(
                        AppLocalizations.of(context)!.delete,
                        style: AppTypography.body.copyWith(
                          color: AppColors.getTextPrimaryColor(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
    ),
  );
  }

  Widget _buildProviderIndicator() {
    return Container(
      width: DesignTokens.spacing1,
      height: DesignTokens.spacing4,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
      ),
    );
  }

  Color _getDueDateColor(String dueDate) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return AppColors.getTextSecondaryColor(context);
    
    final now = DateTime.now();
    final difference = due.difference(now).inDays;
    
    if (difference < 0) {
      return AppColors.error; // Overdue
    } else if (difference == 0) {
      return AppColors.warning; // Due today
    } else if (difference <= 3) {
      return AppColors.warning; // Due soon
    } else {
      return AppColors.getTextSecondaryColor(context); // Normal
    }
  }

  String _formatDueDate(String dueDate) {
    final due = DateTime.tryParse(dueDate);
    if (due == null) return '';
    
    final now = DateTime.now();
    final difference = due.difference(now).inDays;
    
    if (difference < 0) {
      return AppLocalizations.of(context)!.overdue(-difference);
    } else if (difference == 0) {
      return AppLocalizations.of(context)!.today;
    } else if (difference == 1) {
      return AppLocalizations.of(context)!.tomorrow;
    } else if (difference <= 7) {
      return AppLocalizations.of(context)!.daysFromNow(difference);
    } else {
      return '${due.day}/${due.month}';
    }
  }

  void _editTask(google_tasks.Task task) {
    // TODO: Implement task editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit task: ${task.title}')),
    );
  }
}