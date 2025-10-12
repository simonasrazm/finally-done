import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../services/queue_service.dart';
import '../models/queued_command.dart';

class MissionControlScreen extends ConsumerStatefulWidget {
  const MissionControlScreen({super.key});

  @override
  ConsumerState<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends ConsumerState<MissionControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Mission Control'),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_outlined, size: 16),
                  Text('Queued', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 16),
                  Text('Done', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
            Tab(
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rate_review_outlined, size: 16),
                      Text('Review', style: TextStyle(fontSize: 10)),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: const BoxDecoration(
                        color: AppColors.warning,
                        borderRadius: BorderRadius.all(Radius.circular(8)),
                      ),
                      child: const Text(
                        '3',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQueuedTab(),
          _buildExecutedTab(),
          _buildReviewTab(),
        ],
      ),
    );
  }
  
  Widget _buildQueuedTab() {
    final queuedCommands = ref.watch(queuedCommandsProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.getSecondaryBackgroundColor(context),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.queue_outlined,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'QUEUED (${queuedCommands.length} items)',
                style: AppTypography.headline.copyWith(
                  color: AppColors.getTextPrimaryColor(context),
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Commands list or empty state
        if (queuedCommands.isEmpty)
          Center(
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 64,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No items in queue',
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Scheduled commands will appear here',
                  style: AppTypography.footnote.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
              ],
            ),
          )
        else
          ...queuedCommands.map((command) => _buildQueuedCommandCard(command)),
      ],
    );
  }
  
  Widget _buildQueuedCommandCard(QueuedCommandRealm command) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
                command.audioPath != null ? Icons.mic : Icons.text_fields,
                size: 16,
                color: AppColors.getTextSecondaryColor(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  command.transcription?.isNotEmpty == true ? command.transcription! : command.text,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextPrimaryColor(context),
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(command.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(command.status),
                      style: AppTypography.caption1.copyWith(
                        color: _getStatusColor(command.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => _deleteCommand(command),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'Scheduled: ${_formatTime(command.createdAt)}',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.getTextTertiaryColor(context),
                ),
              ),
              if (command.audioPath != null && command.audioPath!.isNotEmpty) ...[
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    final audioPath = command.audioPath;
                    if (audioPath != null) {
                      _playAudio(audioPath);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_arrow,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Play',
                          style: AppTypography.caption1.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          
          // Photo attachments
          if (command.photoPaths.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Photos (${command.photoPaths.length})',
              style: AppTypography.footnote.copyWith(
                color: AppColors.getTextSecondaryColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: command.photoPaths.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FutureBuilder<String>(
                        future: _getPhotoPath(command.photoPaths[index]),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return GestureDetector(
                              onTap: () => _showPhotoPreview(snapshot.data!, command.photoPaths),
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
      print('🎵 PLAY: Input audioPath: "$audioPath"');
      print('🎵 PLAY: Converted to fullPath: "$fullPath"');
      
      // Check if file exists first
      final file = File(fullPath);
      if (!await file.exists()) {
        print('🎵 PLAY: Audio file does not exist: $fullPath');
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
      print('🎵 PLAY ERROR: $e');
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

  void _deleteCommand(QueuedCommandRealm command) async {
    try {
      // Store command data before deletion to avoid Realm invalidation issues
      final commandId = command.id;
      final audioPath = command.audioPath;
      final photoPaths = List<String>.from(command.photoPaths);
      
      // Remove from queue first (this deletes from Realm)
      ref.read(queueProvider.notifier).removeCommand(commandId);
      
      // Delete associated media files after Realm deletion
      if (audioPath != null && audioPath.isNotEmpty) {
        final fullAudioPath = await _getFullAudioPath(audioPath);
        final audioFile = File(fullAudioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
          print('🗑️ DELETE: Removed audio file: $fullAudioPath');
        }
      }
      
      // Delete associated photo files
      for (final photoPath in photoPaths) {
        final fullPhotoPath = await _getPhotoPath(photoPath);
        final photoFile = File(fullPhotoPath);
        if (await photoFile.exists()) {
          await photoFile.delete();
          print('🗑️ DELETE: Removed photo file: $fullPhotoPath');
        }
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Command deleted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      print('🗑️ DELETE: Error deleting command: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting command: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  
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
        return 'QUEUED';
      case 'recorded':
        return 'RECORDED';
      case 'transcribing':
        return 'TRANSCRIBING';
      case 'processing':
        return 'PROCESSING';
      case 'completed':
        return 'DONE';
      case 'failed':
        return 'FAILED';
      default:
        return 'UNKNOWN';
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
      padding: const EdgeInsets.all(16),
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
                const SizedBox(height: 16),
                Text(
                  'No completed commands yet',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Completed commands will appear here',
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
    final failedCommands = ref.watch(failedCommandsProvider);
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (failedCommands.isEmpty)
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.rate_review_outlined,
                  size: 64,
                  color: AppColors.getTextTertiaryColor(context),
                ),
                const SizedBox(height: 16),
                Text(
                  'No commands need review',
                  style: AppTypography.headline.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Failed commands will appear here for review',
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextTertiaryColor(context),
                  ),
                ),
              ],
            ),
          )
        else
          ...failedCommands.map((command) => _buildQueuedCommandCard(command)),
      ],
    );
  }
  
  
  Widget _buildCommandCard({
    required String transcription,
    required List<Widget> entities,
    required List<String> actions,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Transcription
            Text(
              transcription,
              style: AppTypography.body,
            ),
            const SizedBox(height: 12),
            
            // Entities
            ...entities,
            
            const SizedBox(height: 16),
            
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
                      borderRadius: BorderRadius.circular(8),
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(8),
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
              const SizedBox(width: 8),
              Text(
                '$type → $target',
                style: AppTypography.footnote.copyWith(
                  color: AppColors.getTextSecondaryColor(context),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: confidence > 0.7 ? AppColors.success : AppColors.warning,
                  borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 4),
          Text(
            content,
            style: AppTypography.callout,
          ),
          const SizedBox(height: 4),
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
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.allPhotoPaths.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
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
