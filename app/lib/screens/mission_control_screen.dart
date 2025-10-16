import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/queue_service.dart';
import '../services/speech_service.dart';
import '../models/queued_command.dart';
import '../utils/logger.dart';
import '../utils/sentry_performance.dart';
import '../utils/thumbnail_service.dart';
import '../generated/app_localizations.dart';

class MissionControlScreen extends ConsumerStatefulWidget {
  const MissionControlScreen({super.key});

  @override
  ConsumerState<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends ConsumerState<MissionControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Track which commands are currently being retried
  final Set<String> _retryingCommands = <String>{};
  
  @override
  void initState() {
    super.initState();
    
    // Track screen load performance
    sentryPerformance.monitorTransaction(
      PerformanceTransactions.screenMissionControl,
      PerformanceOps.screenLoad,
      () async {
    _tabController = TabController(length: 3, vsync: this);
      },
      data: {
        'screen': 'mission_control',
        'has_tab_controller': true,
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.missionControl,
          style: AppTypography.title1.copyWith(
            color: AppColors.getTextPrimaryColor(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_outlined, size: 16),
                  Text(AppLocalizations.of(context)!.processing, style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  Text(AppLocalizations.of(context)!.completed, style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Consumer(
                builder: (context, ref, child) {
                  final failedCommands = ref.watch(failedCommandsProvider);
                  return Stack(
                    children: [
                      Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                          Icon(Icons.rate_review_outlined, size: 16),
                          Text(AppLocalizations.of(context)!.review, style: TextStyle(fontSize: 10)),
                        ],
                      ),
                      if (failedCommands.isNotEmpty)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: DesignTokens.spacing1,
                              vertical: DesignTokens.spacing0,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Text(
                              '${failedCommands.length}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProcessingTab(),
          _buildExecutedTab(),
          _buildReviewTab(),
        ],
      ),
    );
  }
  
  Widget _buildProcessingTab() {
    final allCommands = ref.watch(queuedCommandsProvider);
    // Show all commands except failed ones (they go to Review tab)
    final processingCommands = allCommands.where((cmd) => !cmd.failed).toList();
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        // Header
        Container(
          padding: EdgeInsets.all(DesignTokens.componentPadding),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(context),
            borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
          ),
          child: Row(
            children: [
              Icon(
                Icons.settings_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: DesignTokens.spacing3),
              Text(
                AppLocalizations.of(context)!.processingItems(processingCommands.length),
                style: AppTypography.headline.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
        
        SizedBox(height: DesignTokens.sectionSpacing),
        
        // Commands list or empty state
        if (processingCommands.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                const SizedBox(height: DesignTokens.componentPadding),
                Text(
                  'No items in queue',
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing2),
                Text(
                  AppLocalizations.of(context)!.completedCommandsWillAppearHere,
            style: AppTypography.footnote.copyWith(
              color: AppColors.getTextTertiaryColor(context),
            ),
          ),
              ],
        ),
          )
        else
          ...processingCommands.map((command) => _buildQueuedCommandCard(command)),
      ],
    );
  }
  
  Widget _buildQueuedCommandCard(QueuedCommandRealm command) {
    // Safely get command properties to avoid Realm invalidation errors
    String commandText;
    String commandStatus;
    String? audioPath;
    String? transcription;
    DateTime createdAt;
    List<String> photoPaths;
    
    try {
      commandText = command.text;
      commandStatus = command.status;
      audioPath = command.audioPath;
      transcription = command.transcription;
      createdAt = command.createdAt;
      photoPaths = List<String>.from(command.photoPaths);
    } catch (e) {
      Logger.warning('Error accessing command properties in UI: $e', tag: 'UI');
      // Return a placeholder card for invalid commands
      return Container(
        margin: const EdgeInsets.only(bottom: DesignTokens.spacing3),
        padding: EdgeInsets.all(DesignTokens.componentPadding),
        decoration: BoxDecoration(
          color: AppColors.getSecondaryBackgroundColor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withOpacity(0.3),
          ),
        ),
        child: Text(
          AppLocalizations.of(context)!.invalidCommandDeleted,
          style: AppTypography.body.copyWith(
            color: AppColors.error,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing3),
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.separator.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                audioPath != null ? Icons.mic : Icons.text_fields,
                size: 16,
                color: AppColors.getTextSecondaryColor(context),
              ),
              const SizedBox(width: DesignTokens.spacing2),
              Expanded(
                child: Text(
                  transcription?.isNotEmpty == true ? transcription! : commandText,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: DesignTokens.spacing2,
                      vertical: DesignTokens.spacing1,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(commandStatus).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                    ),
                    child: Text(
                      _getStatusText(commandStatus),
                      style: AppTypography.caption1.copyWith(
                        color: _getStatusColor(commandStatus),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  
                  // Failed flag indicator (only show if failed)
                  if (command.failed) ...[
                    const SizedBox(width: DesignTokens.spacing1),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing1,
                        vertical: DesignTokens.spacing0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      ),
                      child: Text(
                        'FAILED',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                  
                  // Action needed flag indicator (only show if action needed)
                  if (command.actionNeeded) ...[
                    const SizedBox(width: DesignTokens.spacing1),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing1,
                        vertical: DesignTokens.spacing0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                      ),
                      child: Text(
                        'ACTION NEEDED',
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          // Error message display (show user-friendly message based on status)
          if (command.failed && commandStatus == 'transcribing') ...[
            const SizedBox(height: DesignTokens.spacing2),
            _buildExpandableErrorMessage(AppLocalizations.of(context)!.transcriptionRetryFailed),
          ],
          
          const SizedBox(height: DesignTokens.spacing2),
        Row(
          children: [
            Text(
              AppLocalizations.of(context)!.scheduledTime(_formatTime(createdAt)),
              style: AppTypography.footnote.copyWith(
                color: AppColors.getTextTertiaryColor(context),
              ),
            ),
            
            // Action buttons (grouped on the left)
            const SizedBox(width: DesignTokens.componentPadding),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Play button (for audio commands)
                if (audioPath != null && audioPath.isNotEmpty) ...[
                  GestureDetector(
                    onTap: () {
                      if (audioPath != null) {
                        _playAudio(audioPath);
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: DesignTokens.spacing2,
                        vertical: DesignTokens.spacing1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
      children: [
                          Icon(
                            Icons.play_arrow,
                            size: 14,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: DesignTokens.spacing1),
                          Text(
                            AppLocalizations.of(context)!.play,
                            style: AppTypography.caption1.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing2),
                ],
                
                // Retry button (only for transcribing + failed commands)
                if (command.failed && commandStatus == 'transcribing') ...[
                  GestureDetector(
                    onTap: _retryingCommands.contains(command.id) 
                        ? null 
                        : () => _retryTranscription(command.id),
                    child: Container(
                      padding: EdgeInsets.all(DesignTokens.spacing1),
                      decoration: BoxDecoration(
                        color: _retryingCommands.contains(command.id)
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: _retryingCommands.contains(command.id)
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                              ),
                            )
                          : Icon(
                              Icons.refresh_outlined,
                              size: 16,
                              color: AppColors.success,
                            ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing2),
                ],
                
                // Edit button (tab-specific logic)
                if (_shouldShowEditButton(command, commandStatus)) ...[
                  GestureDetector(
                    onTap: () => _editTranscription(command.id, transcription ?? commandText),
                    child: Container(
                      padding: EdgeInsets.all(DesignTokens.spacing1),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: DesignTokens.spacing2),
                ],
              ],
            ),
            
            // Spacer to push delete button to the right
            const Spacer(),
            
            // Delete button (positioned on the far right)
            GestureDetector(
              onTap: () => _deleteCommand(command.id),
              child: Container(
                padding: EdgeInsets.all(DesignTokens.spacing1),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 16,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ),
          
          // Photo attachments
          if (photoPaths.isNotEmpty) ...[
            const SizedBox(height: DesignTokens.spacing3),
            Text(
              AppLocalizations.of(context)!.photosCount(photoPaths.length),
              style: AppTypography.footnote.copyWith(
                color: AppColors.getTextSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: DesignTokens.spacing2),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photoPaths.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: DesignTokens.spacing2),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                      child: FutureBuilder<String?>(
                        future: _getThumbnailPath(photoPaths[index]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return GestureDetector(
                              onTap: () async => _showPhotoPreview(await _getPhotoPath(photoPaths[index]), photoPaths),
                              child: Image.file(
                                File(snapshot.data!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  );
                                },
                              ),
                            );
                          } else {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const CircularProgressIndicator(),
                            );
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _playAudio(String audioPath) async {
    try {
      // Convert filename to full path
      final fullPath = await _getFullAudioPath(audioPath);
      
      // Check if file exists first
      final file = File(fullPath);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio file not found'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Playing audio...'),
          duration: Duration(seconds: 1),
        ),
      );
      
      // Play the audio file
      await _audioPlayer.play(DeviceFileSource(fullPath));
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio playback started'),
          duration: Duration(seconds: 1),
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing audio: $e'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<String> _getFullAudioPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/audio/$fileName';
  }

  Future<String> _getPhotoPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/photos/$fileName';
  }

  Future<String?> _getThumbnailPath(String fileName) async {
    final photoPath = await _getPhotoPath(fileName);
    return await ThumbnailService.getThumbnailPath(photoPath);
  }

  void _showPhotoPreview(String photoPath, List<String> allPhotoPaths) {
    final initialIndex = allPhotoPaths.indexOf(photoPath);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _PhotoGalleryDialog(
          allPhotoPaths: allPhotoPaths,
          initialIndex: initialIndex,
        );
      },
    );
  }

  void _deleteCommand(String commandId) async {
    try {
      // Get command data from current state before deletion
      final allCommands = ref.read(queueProvider);
      final command = allCommands.firstWhere((cmd) => cmd.id == commandId);
      
      // Store command data before deletion to avoid Realm invalidation issues
      final audioPath = command.audioPath;
      final photoPaths = List<String>.from(command.photoPaths);
      
      Logger.info('Deleting command: $commandId', tag: 'DELETE');
      
      // Remove from queue first (this deletes from Realm)
      ref.read(queueProvider.notifier).removeCommand(commandId);
      
      // Delete associated media files after Realm deletion
      if (audioPath != null && audioPath.isNotEmpty) {
        final fullAudioPath = await _getFullAudioPath(audioPath);
        final audioFile = File(fullAudioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
          Logger.debug('Removed audio file: $fullAudioPath', tag: 'DELETE');
        }
      }
      
      // Delete associated photo files and thumbnails
      for (final photoPath in photoPaths) {
        final fullPhotoPath = await _getPhotoPath(photoPath);
        final photoFile = File(fullPhotoPath);
        if (await photoFile.exists()) {
          await photoFile.delete();
          Logger.debug('Removed photo file: $fullPhotoPath', tag: 'DELETE');
        }
        
        // Also delete thumbnail
        await ThumbnailService.deleteThumbnail(fullPhotoPath);
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      
      Logger.info('Successfully deleted command: $commandId', tag: 'DELETE');
    } catch (e, stackTrace) {
      Logger.error('Failed to delete command: $commandId', 
        tag: 'DELETE', 
        error: e, 
        stackTrace: stackTrace
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting command: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  bool _shouldShowEditButton(QueuedCommandRealm command, String commandStatus) {
    // Get current tab index
    final currentTabIndex = _tabController?.index ?? 0;
    
    // If command is failed or actionNeeded, it should always have edit button (Review tab logic)
    if (command.failed || command.actionNeeded) {
      return true;
    }
    
    // For other commands, check tab context
    switch (currentTabIndex) {
      case 0: // Processing tab
        // Only show edit button for queued commands
        return commandStatus == 'queued';
      case 1: // Completed tab
        // No edit button for completed commands
        return false;
      case 2: // Review tab
        // This should not happen since failed/actionNeeded is handled above
        return false;
      default:
        return false;
    }
  }

  void _editTranscription(String id, String currentTranscription) {
    // Get current tab index to determine behavior
    final currentTabIndex = _tabController?.index ?? 0;
    final isReviewTab = currentTabIndex == 2;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final controller = TextEditingController(text: currentTranscription);
        
        return AlertDialog(
          title: Text('Edit Transcription'),
          content: TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Enter transcription text...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newTranscription = controller.text.trim();
                if (newTranscription.isNotEmpty && newTranscription != currentTranscription) {
                  // Update transcription
                  ref.read(queueProvider.notifier).updateCommandTranscription(id, newTranscription);
                  
                  if (isReviewTab) {
                    // Review tab: Save and Execute functionality
                    // Clear failed flag and error message
                    ref.read(queueProvider.notifier).updateCommandFailed(id, false);
                    ref.read(queueProvider.notifier).updateCommandErrorMessage(id, null);
                    
                    // Move to queued status for processing
                    ref.read(queueProvider.notifier).updateCommandStatus(id, CommandStatus.queued);
                    
                    // Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transcription updated and queued for processing'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  } else {
                    // Processing tab: Just save
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Transcription updated successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
                Navigator.of(context).pop();
              },
              child: Text(isReviewTab 
                ? AppLocalizations.of(context)!.saveAndExecute 
                : 'Save'),
            ),
          ],
        );
      },
    );
  }

  void _retryTranscription(String id) async {
    // Add to retrying set and update UI
    setState(() {
      _retryingCommands.add(id);
    });
    
    try {
      // Get the command to retry
      final allCommands = ref.read(queueProvider);
      final command = allCommands.firstWhere((cmd) => cmd.id == id);
      
      if (command.audioPath == null || command.audioPath!.isEmpty) {
        throw Exception('No audio file found for this command');
      }
      
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Retrying transcription...'),
          duration: Duration(seconds: 2),
        ),
      );
      
      // Get full audio path
      final fullAudioPath = await _getFullAudioPath(command.audioPath!);
      
      // Process the specific audio file with Gemini (same as after recording)
      final speechService = ref.read(speechServiceProvider);
      String transcription = await speechService.processAudioFile(fullAudioPath);
      
      // Update transcription and status
      ref.read(queueProvider.notifier).updateCommandTranscription(id, transcription);
      ref.read(queueProvider.notifier).updateCommandStatus(id, CommandStatus.queued);
      
      // Clear failed flag and error message on success
      ref.read(queueProvider.notifier).updateCommandFailed(id, false);
      ref.read(queueProvider.notifier).updateCommandErrorMessage(id, null);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Transcription retry completed!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      // Store technical error for backend analysis, but show user-friendly message in UI
      ref.read(queueProvider.notifier).updateCommandErrorMessage(id, e.toString());
      ref.read(queueProvider.notifier).updateCommandFailed(id, true);
      
      // Show user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.transcriptionRetryFailed),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 3),
        ),
      );
      
    } finally {
      // Always remove from retrying set and update UI
      setState(() {
        _retryingCommands.remove(id);
      });
    }
  }



  
  Widget _buildExpandableErrorMessage(String errorMessage) {
    return StatefulBuilder(
      builder: (context, setState) {
        const int maxLength = 100;
        final bool isLong = errorMessage.length > maxLength;
        final bool isExpanded = _expandedErrorMessages[errorMessage] ?? false;
        
        return Container(
          padding: EdgeInsets.all(DesignTokens.spacing2),
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.1),
            borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 16,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: DesignTokens.spacing2),
                  Expanded(
                    child: Text(
                      isLong && !isExpanded 
                        ? '${errorMessage.substring(0, maxLength)}...'
                        : errorMessage,
                      style: AppTypography.caption1.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              if (isLong) ...[
                const SizedBox(height: DesignTokens.spacing1),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _expandedErrorMessages[errorMessage] = !isExpanded;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: AppColors.error.withOpacity(0.7),
                      ),
                      const SizedBox(width: DesignTokens.spacing1),
                      Text(
                        isExpanded ? AppLocalizations.of(context)!.showLess : AppLocalizations.of(context)!.showMore,
                        style: AppTypography.caption1.copyWith(
                          color: AppColors.error.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // Track expanded state for each error message
  final Map<String, bool> _expandedErrorMessages = {};

  Color _getStatusColor(String status) {
    switch (status) {
      case 'queued':
        return AppColors.primary;
      case 'recorded':
        return AppColors.warning;
      case 'transcribing':
        return AppColors.warning;
      case 'processing':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'queued':
        return AppLocalizations.of(context)!.queued;
      case 'recorded':
        return AppLocalizations.of(context)!.recorded;
      case 'transcribing':
        return AppLocalizations.of(context)!.transcribing;
      case 'processing':
        return AppLocalizations.of(context)!.processingTab;
      case 'completed':
        return AppLocalizations.of(context)!.done;
      case 'failed':
        return AppLocalizations.of(context)!.failed;
      default:
        return AppLocalizations.of(context)!.unknown;
    }
  }
  
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
  
  Widget _buildExecutedTab() {
    final completedCommands = ref.watch(completedCommandsProvider);
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        if (completedCommands.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                const SizedBox(height: DesignTokens.componentPadding),
                Text(
                  AppLocalizations.of(context)!.noCompletedCommandsYet,
                  style: AppTypography.headline.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing2),
                Text(
                  AppLocalizations.of(context)!.completedCommandsWillAppearHere,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
              ],
            ),
          )
        else
          ...completedCommands.map((command) => _buildQueuedCommandCard(command)),
      ],
    );
  }
  
  Widget _buildReviewTab() {
    final reviewCommands = ref.watch(reviewCommandsProvider);
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        if (reviewCommands.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                const SizedBox(height: DesignTokens.componentPadding),
                Text(
                  'No commands need review',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: DesignTokens.spacing2),
                Text(
                  'Failed commands and items needing action will appear here',
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
              ],
            ),
          )
        else
          ...reviewCommands.map((command) => _buildQueuedCommandCard(command)),
      ],
    );
  }
  
  
  Widget _buildCommandCard({
    required String transcription,
    required List<Widget> entities,
    required List<String> actions,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: DesignTokens.componentPadding,
        vertical: DesignTokens.spacing2,
      ),
      child: Padding(
        padding: EdgeInsets.all(DesignTokens.componentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transcription
            Text(
              transcription,
              style: AppTypography.body,
            ),
            const SizedBox(height: DesignTokens.spacing3),
            
            // Entities
            ...entities,
            
            const SizedBox(height: DesignTokens.componentPadding),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: actions.map((action) {
                Color buttonColor;
                if (action == 'Execute') {
                  buttonColor = AppColors.success;
                } else if (action == 'Retry') {
                  buttonColor = AppColors.primary;
                } else if (action == 'Cancel' || action == 'Ignore') {
                  buttonColor = AppColors.error;
                } else {
                  buttonColor = AppColors.primary;
                }
                
                return OutlinedButton(
                  onPressed: () {
                    // TODO: Handle action
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: buttonColor,
                    side: BorderSide(color: buttonColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                    ),
                  ),
                  child: Text(action),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildEntityCard({
    required String type,
    required String content,
    required String target,
    required double confidence,
    required String reasoning,
    required String status,
  }) {
    Color statusColor;
    IconData statusIcon;
    
    switch (status) {
      case 'review_needed':
        statusColor = AppColors.warning;
        statusIcon = Icons.warning_outlined;
        break;
      case 'failed':
        statusColor = AppColors.error;
        statusIcon = Icons.error_outline;
        break;
      case 'executed':
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle_outline;
        break;
      default:
        statusColor = AppColors.primary;
        statusIcon = Icons.info_outline;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing2),
      padding: EdgeInsets.all(DesignTokens.spacing3),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16),
              const SizedBox(width: DesignTokens.spacing2),
              Text(
                '$type → $target',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: DesignTokens.spacing1 + DesignTokens.spacing1,
                  vertical: DesignTokens.spacing0 + DesignTokens.spacing0,
                ),
                decoration: BoxDecoration(
                  color: confidence > 0.7 ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
                ),
                child: Text(
                  '${(confidence * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: DesignTokens.spacing1),
          Text(
            content,
            style: AppTypography.callout,
          ),
          const SizedBox(height: DesignTokens.spacing1),
          Text(
            reasoning,
            style: AppTypography.caption1.copyWith(
              color: AppColors.getTextTertiaryColor(context),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoGalleryDialog extends StatefulWidget {
  final List<String> allPhotoPaths;
  final int initialIndex;

  const _PhotoGalleryDialog({
    required this.allPhotoPaths,
    required this.initialIndex,
  });

  @override
  State<_PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<_PhotoGalleryDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<String> _getPhotoPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/photos/$fileName';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: MediaQuery.of(context).size.width * 0.95,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Photo ${_currentIndex + 1} of ${widget.allPhotoPaths.length}'),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: widget.allPhotoPaths.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  return FutureBuilder<String>(
                    future: _getPhotoPath(widget.allPhotoPaths[index]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return InteractiveViewer(
                          child: Image.file(
                            File(snapshot.data!),
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Text('Failed to load image'),
                              );
                            },
                          ),
                        );
                      } else {
                        return const Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                    },
                  );
                },
              ),
            ),
            // Photo indicators
            if (widget.allPhotoPaths.length > 1)
              Container(
                padding: EdgeInsets.all(DesignTokens.componentPadding),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.allPhotoPaths.length,
                    (index) => Container(
                      margin: EdgeInsets.symmetric(horizontal: DesignTokens.spacing1),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex 
                            ? AppColors.primary 
                            : AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
