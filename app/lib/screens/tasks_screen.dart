import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/integration_service.dart';
import '../generated/app_localizations.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToSettings;
  
  const TasksScreen({super.key, this.onNavigateToSettings});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  bool _isLoading = false;
  Map<String, dynamic>? _tasksData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final integrationService = ref.read(integrationServiceProvider);
      
      if (!integrationService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Not connected to Google. Please connect in Settings.';
          _isLoading = false;
        });
        return;
      }

      final result = await integrationService.listTasks();
      
      setState(() {
        _tasksData = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading tasks: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _completeTask(String taskId) async {
    try {
      final integrationService = ref.read(integrationServiceProvider);
      final result = await integrationService.completeTask(taskId);
      
      if (result['success'] == true) {
        // Reload tasks to show updated status
        await _loadTasks();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.taskCompleted)),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.errorGeneric(result['message']))),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocalizations.of(context)!.errorCompletingTask(e.toString()))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.googleTasks),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final isAuthenticated = ref.watch(isIntegrationAuthenticatedProvider);
          
          if (!isAuthenticated) {
            return _buildNotConnectedView();
          }
          
          if (_isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: DesignTokens.componentPadding),
                  Text(AppLocalizations.of(context)!.loadingTasks),
                ],
              ),
            );
          }
          
          if (_errorMessage != null) {
            return _buildErrorView();
          }
          
          if (_tasksData == null || (_tasksData!['tasks'] as List).isEmpty) {
            return _buildEmptyView();
          }
          
          return _buildTasksList();
        },
      ),
    );
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
              size: 64,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(height: DesignTokens.componentPadding),
            Text(
              'Not Connected to Google',
              style: AppTypography.largeTitle.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              'Connect to Google in Settings to view your tasks',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Settings tab using the callback
                widget.onNavigateToSettings?.call();
              },
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.goToSettings),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.sectionSpacing + DesignTokens.spacing2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: DesignTokens.componentPadding),
            Text(
              'Error Loading Tasks',
              style: AppTypography.largeTitle.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              _errorMessage ?? 'Unknown error occurred',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.tryAgain),
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
              size: 64,
              color: AppColors.getTextSecondaryColor(context),
            ),
            const SizedBox(height: DesignTokens.componentPadding),
            Text(
              'No Tasks Found',
              style: AppTypography.largeTitle.copyWith(
                color: AppColors.getTextPrimaryColor(context),
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Text(
              'Your Google Tasks list is empty. Create some tasks in Google Tasks or try voice commands!',
              style: AppTypography.body.copyWith(
                color: AppColors.getTextSecondaryColor(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.sectionSpacing),
            ElevatedButton.icon(
              onPressed: _loadTasks,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)!.refresh),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList() {
    final tasks = _tasksData!['tasks'] as List;
    
    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: EdgeInsets.all(DesignTokens.componentPadding),
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          final isCompleted = task['status'] == 'completed';
          
          return Card(
            margin: const EdgeInsets.only(bottom: DesignTokens.spacing2),
            child: ListTile(
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                color: isCompleted ? Colors.green : AppColors.getTextSecondaryColor(context),
              ),
              title: Text(
                task['title'] ?? 'Untitled Task',
                style: AppTypography.body.copyWith(
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                  color: isCompleted 
                    ? AppColors.getTextSecondaryColor(context)
                    : AppColors.getTextPrimaryColor(context),
                ),
              ),
              subtitle: task['notes'] != null && task['notes'].isNotEmpty
                ? Text(
                    task['notes'],
                    style: AppTypography.body.copyWith(
                      fontSize: 12,
                      color: AppColors.getTextSecondaryColor(context),
                    ),
                  )
                : null,
              trailing: !isCompleted
                ? IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _completeTask(task['id']),
                    tooltip: 'Complete task',
                  )
                : null,
              onTap: !isCompleted
                ? () => _completeTask(task['id'])
                : null,
            ),
          );
        },
      ),
    );
  }
}
