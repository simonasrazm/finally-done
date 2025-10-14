import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:googleapis/tasks/v1.dart' as google_tasks;
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../providers/tasks_provider.dart';
import '../services/integration_service.dart';
import '../generated/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const TasksScreen({super.key, this.onNavigateToSettings});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String? _selectedTaskListId;
  final TextEditingController _newTaskController = TextEditingController();
  bool _showCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeTaskList();
  }

  @override
  void dispose() {
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
    await ref.read(tasksProvider.notifier).completeTask(taskId);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
    );
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
              error,
              style: AppTypography.body.copyWith(color: AppColors.getTextSecondaryColor(context)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(tasksProvider.notifier).refreshTasks();
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
    
    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).refreshTasks(),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.componentPadding,
          vertical: DesignTokens.spacing1,
        ),
        itemCount: tasksToShow.length,
        itemBuilder: (context, index) {
          final task = tasksToShow[index];
          final isCompleted = task.status == 'completed';
          final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
          
          return Column(
            children: [
              _buildCompactTaskItem(task, isCompleted),
              if (index < tasksToShow.length - 1)
                Divider(
                  height: hasAdditionalContent ? DesignTokens.spacing1 : DesignTokens.spacing0,
                  thickness: 0.5,
                  color: AppColors.separatorOpaque.withOpacity(DesignTokens.opacity20),
                  indent: DesignTokens.spacing8, // Align with content
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompactTaskItem(google_tasks.Task task, bool isCompleted) {
    // Determine if task has additional content (notes or due date)
    final hasAdditionalContent = task.notes?.isNotEmpty == true || task.due != null;
    
    return InkWell(
      onTap: isCompleted ? null : () => _completeTask(task.id!),
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
              onChanged: isCompleted ? null : (value) => _completeTask(task.id!),
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
      return '${-difference}d overdue';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference <= 7) {
      return '${difference}d';
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