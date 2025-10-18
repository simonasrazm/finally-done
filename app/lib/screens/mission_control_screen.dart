import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../core/commands/queue_service.dart';
import '../core/audio/speech_service.dart';
import '../core/commands/command_retry_service.dart';
import '../core/audio/audio_playback_service.dart';
import '../utils/photo_service.dart';
import '../core/commands/command_action_service.dart';
import '../core/commands/command_ui_service.dart';
import '../core/audio/transcription_dialog_service.dart';
import '../models/queued_command.dart';
import '../utils/sentry_performance.dart';
import '../utils/status_helper.dart';
import '../widgets/photo_gallery_dialog.dart';
import '../widgets/command_status_badge.dart';
import '../widgets/command_action_buttons.dart';
import '../widgets/photo_attachments.dart';
import '../widgets/expandable_error_message.dart';
import '../widgets/common_ui_components.dart';
import '../generated/app_localizations.dart';

class MissionControlScreen extends ConsumerStatefulWidget {
  const MissionControlScreen({super.key});

  @override
  ConsumerState<MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends ConsumerState<MissionControlScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Tab indices for better readability
  static const int _processingTabIndex = 0;
  static const int _completedTabIndex = 1;
  static const int _reviewTabIndex = 2;
  
  // Track which commands are currently being retried
  final Set<String> _retryingCommands = <String>{};
  
  // Auto-pass toggle for review tab
  bool _autoPassAudioToQueue = false;
  
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
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: _buildTabBarView(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: _buildAppBarTitle(context),
      backgroundColor: AppColors.getBackgroundColor(context),
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48.0),
        child: _buildTabBar(context),
      ),
    );
  }

  Widget _buildAppBarTitle(BuildContext context) {
    return Text(
      AppLocalizations.of(context)!.missionControl,
      style: AppTypography.title1.copyWith(
        color: AppColors.getTextPrimaryColor(context),
        fontWeight: AppTypography.weightSemiBold,
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: [
        _buildProcessingTab(),
        _buildCompletedTab(),
        _buildReviewTabWithBadge(),
      ],
    );
  }

  Widget _buildProcessingTab() {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings_outlined, size: DesignTokens.iconSm),
          Text(AppLocalizations.of(context)!.processing, style: AppTypography.caption2),
        ],
      ),
    );
  }

  Widget _buildCompletedTab() {
    return Tab(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: DesignTokens.iconSm),
          Text(AppLocalizations.of(context)!.completed, style: AppTypography.caption2),
        ],
      ),
    );
  }

  Widget _buildReviewTabWithBadge() {
    return Tab(
      child: Consumer(
        builder: (context, ref, child) {
          final reviewCommands = ref.watch(reviewCommandsProvider);
          return Stack(
            children: [
              _buildReviewTabContent(),
              if (reviewCommands.isNotEmpty) _buildReviewBadge(reviewCommands.length),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewTabContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.rate_review_outlined, size: DesignTokens.iconSm),
        Text(AppLocalizations.of(context)!.review, style: AppTypography.caption2),
      ],
    );
  }

  Widget _buildReviewBadge(int count) {
    return Positioned(
      top: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: DesignTokens.spacing1,
          vertical: DesignTokens.spacing0,
        ),
        decoration: const BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.all(Radius.circular(DesignTokens.radiusMd)),
        ),
        child: Text(
          '$count',
          style: AppTypography.caption2.copyWith(
            color: AppColors.textPrimary,
            fontWeight: AppTypography.weightBold,
          ),
        ),
      ),
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildProcessingTabContent(),
        _buildExecutedTab(),
        _buildReviewTab(),
      ],
    );
  }
  
  Widget _buildProcessingTabContent() {
    final processingCommands = ref.watch(processingCommandsProvider);
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        _buildProcessingHeader(processingCommands.length),
        SizedBox(height: DesignTokens.sectionSpacing),
        _buildProcessingContent(processingCommands),
      ],
    );
  }

  Widget _buildProcessingHeader(int commandCount) {
    return CommonUIComponents.buildSectionHeader(
      context: context,
      icon: Icons.settings_outlined,
      title: AppLocalizations.of(context)!.processingItems(commandCount),
    );
  }

  Widget _buildProcessingContent(List<dynamic> processingCommands) {
    return CommonUIComponents.buildCommandList(
      commands: processingCommands,
      itemBuilder: (command) => _buildQueuedCommandCard(command),
      emptyState: _buildProcessingEmptyState(),
    );
  }

  Widget _buildProcessingEmptyState() {
    return CommonUIComponents.buildEmptyState(
      context: context,
      icon: Icons.inbox_outlined,
      title: 'No items in queue',
      subtitle: AppLocalizations.of(context)!.completedCommandsWillAppearHere,
    );
  }
  
  Widget _buildQueuedCommandCard(QueuedCommandRealm command) {
    final props = CommandUIService.extractCommandProperties(command);
    
    if (!props.isValid) {
      return _buildInvalidCommandCard();
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing3),
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      decoration: _buildCommandCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCommandHeader(props, command),
          _buildErrorMessageIfNeeded(command, props),
          _buildCommandFooter(props, command),
          _buildPhotoAttachments(props),
        ],
      ),
    );
  }

  Widget _buildInvalidCommandCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: DesignTokens.spacing3),
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      decoration: BoxDecoration(
        color: AppColors.getSecondaryBackgroundColor(context),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
        border: Border.all(
          color: AppColors.error.withOpacity(DesignTokens.opacity30),
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

  BoxDecoration _buildCommandCardDecoration() {
    return BoxDecoration(
      color: AppColors.getSecondaryBackgroundColor(context),
      borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      border: Border.all(
        color: AppColors.separator.withOpacity(DesignTokens.opacity30),
      ),
    );
  }

  Widget _buildCommandHeader(CommandProperties props, QueuedCommandRealm command) {
    return Row(
      children: [
        Icon(
          props.audioPath != null ? Icons.mic : Icons.text_fields,
          size: DesignTokens.iconSm,
          color: AppColors.getTextSecondaryColor(context),
        ),
        const SizedBox(width: DesignTokens.spacing2),
        Expanded(
          child: Text(
            props.transcription?.isNotEmpty == true ? props.transcription! : props.text,
            style: AppTypography.body.copyWith(
              color: AppColors.getTextPrimaryColor(context),
            ),
          ),
        ),
        CommandStatusBadge(
          command: command,
          commandStatus: props.status,
        ),
      ],
    );
  }

  Widget _buildErrorMessageIfNeeded(QueuedCommandRealm command, CommandProperties props) {
    if (command.failed) {
      return Column(
        children: [
          const SizedBox(height: DesignTokens.spacing2),
          ExpandableErrorMessage(
            errorMessage: command.errorMessage?.isNotEmpty == true 
                ? command.errorMessage! 
                : AppLocalizations.of(context)!.transcriptionRetryFailed,
            expandedErrorMessages: _expandedErrorMessages,
          ),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCommandFooter(CommandProperties props, QueuedCommandRealm command) {
    return Column(
      children: [
        const SizedBox(height: DesignTokens.spacing2),
        Row(
          children: [
            _buildTimestampText(props),
            const SizedBox(width: DesignTokens.componentPadding),
            _buildActionButtons(props, command),
            const Spacer(),
            _buildDeleteButton(command),
          ],
        ),
      ],
    );
  }

  Widget _buildTimestampText(CommandProperties props) {
    return Text(
      AppLocalizations.of(context)!.scheduledTime(StatusHelper.formatTime(props.createdAt)),
      style: AppTypography.footnote.copyWith(
        color: AppColors.getTextTertiaryColor(context),
      ),
    );
  }

  Widget _buildActionButtons(CommandProperties props, QueuedCommandRealm command) {
    return CommandActionButtons(
      command: command,
      commandStatus: props.status,
      commandText: props.text,
      transcription: props.transcription,
      audioPath: props.audioPath,
      retryingCommands: _retryingCommands,
      onRetry: () => _retryCommand(command.id, props.status),
      onEdit: () => _editTranscription(command.id, props.transcription ?? props.text),
    );
  }

  Widget _buildDeleteButton(QueuedCommandRealm command) {
    return GestureDetector(
      onTap: () => CommandActionService.deleteCommand(command.id, ref, context),
      child: Container(
        padding: EdgeInsets.all(DesignTokens.spacing1),
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(DesignTokens.opacity10),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        child: Icon(
          Icons.delete_outline,
          size: DesignTokens.iconSm,
          color: AppColors.error,
        ),
      ),
    );
  }

  Widget _buildPhotoAttachments(CommandProperties props) {
    return PhotoAttachments(
      photoPaths: props.photoPaths,
      onPhotoTap: () {}, // Not used in this context
    );
  }
  

  void _showPhotoPreview(String photoPath, List<String> allPhotoPaths) {
    final initialIndex = allPhotoPaths.indexOf(photoPath);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PhotoGalleryDialog(
          allPhotoPaths: allPhotoPaths,
          initialIndex: initialIndex,
        );
      },
    );
  }



  void _editTranscription(String id, String currentTranscription) {
    final currentTabIndex = _tabController?.index ?? _processingTabIndex;
    final isReviewTab = currentTabIndex == _reviewTabIndex;
    
    TranscriptionDialogService.showEditDialog(
      context: context,
      id: id,
      currentTranscription: currentTranscription,
      isReviewTab: isReviewTab,
      ref: ref,
    );
  }


  void _retryCommand(String id, String commandStatus) async {
    // Add to retrying set and update UI
    setState(() {
      _retryingCommands.add(id);
    });
    
    try {
      // Get the command to retry
      final allCommands = ref.read(queueProvider);
      final command = allCommands.firstWhere((cmd) => cmd.id == id);
      
      // Use the command action service
      await CommandActionService.retryCommand(id, commandStatus, command.failed, ref, context);
      
    } catch (e) {
      // Error handling is done in the service
    } finally {
      // Always remove from retrying set and update UI
      setState(() {
        _retryingCommands.remove(id);
      });
    }
  }



  

  // Track expanded state for each error message
  final Map<String, bool> _expandedErrorMessages = {};

  
  Widget _buildExecutedTab() {
    final completedCommands = ref.watch(completedCommandsProvider);
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        CommonUIComponents.buildCommandList(
          commands: completedCommands,
          itemBuilder: (command) => _buildQueuedCommandCard(command),
          emptyState: _buildCompletedEmptyState(),
        ),
      ],
    );
  }

  Widget _buildCompletedEmptyState() {
    return CommonUIComponents.buildEmptyState(
      context: context,
      icon: Icons.check_circle_outline,
      title: AppLocalizations.of(context)!.noCompletedCommandsYet,
      subtitle: AppLocalizations.of(context)!.completedCommandsWillAppearHere,
    );
  }
  
  Widget _buildReviewTab() {
    final reviewCommands = ref.watch(reviewCommandsProvider);
    
    return ListView(
      padding: EdgeInsets.all(DesignTokens.componentPadding),
      children: [
        _buildAutoPassToggle(),
        const SizedBox(height: DesignTokens.componentPadding),
        _buildReviewContent(reviewCommands),
      ],
    );
  }

  Widget _buildAutoPassToggle() {
    return CommonUIComponents.buildToggleSwitch(
      context: context,
      title: 'Auto-pass audio to queue',
      subtitle: '',
      value: _autoPassAudioToQueue,
      onChanged: (value) {
        setState(() {
          _autoPassAudioToQueue = value;
        });
      },
      icon: Icons.auto_awesome,
    );
  }

  Widget _buildReviewContent(List<dynamic> reviewCommands) {
    return CommonUIComponents.buildCommandList(
      commands: reviewCommands,
      itemBuilder: (command) => _buildQueuedCommandCard(command),
      emptyState: _buildReviewEmptyState(),
    );
  }

  Widget _buildReviewEmptyState() {
    return CommonUIComponents.buildEmptyState(
      context: context,
      icon: Icons.rate_review_outlined,
      title: 'No commands need review',
      subtitle: 'Failed commands, manual review items, and items needing action will appear here',
    );
  }
  
  
}

