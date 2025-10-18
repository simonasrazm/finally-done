import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../design_system/tokens.dart';
import '../services/queue_service.dart';
import '../models/queued_command.dart';
import '../generated/app_localizations.dart';

/// Service for handling transcription editing dialogs
class TranscriptionDialogService {
  // Private constructor to prevent instantiation
  TranscriptionDialogService._();

  /// Shows the transcription edit dialog
  static Future<void> showEditDialog({
    required BuildContext context,
    required String id,
    required String currentTranscription,
    required bool isReviewTab,
    required WidgetRef ref,
  }) {
    return showDialog(
      context: context,
      builder: (BuildContext context) => _TranscriptionEditDialog(
        id: id,
        currentTranscription: currentTranscription,
        isReviewTab: isReviewTab,
        ref: ref,
      ),
    );
  }
}

class _TranscriptionEditDialog extends StatefulWidget {
  final String id;
  final String currentTranscription;
  final bool isReviewTab;
  final WidgetRef ref;

  const _TranscriptionEditDialog({
    required this.id,
    required this.currentTranscription,
    required this.isReviewTab,
    required this.ref,
  });

  @override
  State<_TranscriptionEditDialog> createState() => _TranscriptionEditDialogState();
}

class _TranscriptionEditDialogState extends State<_TranscriptionEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTranscription);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: _buildDialogTitle(),
      content: _buildTextField(),
      actions: _buildActions(context),
    );
  }

  Widget _buildDialogTitle() {
    return const Text('Edit Transcription');
  }

  Widget _buildTextField() {
    return TextField(
      controller: _controller,
      maxLines: DesignTokens.textFieldMaxLines,
      decoration: InputDecoration(
        hintText: 'Enter transcription text...',
        border: const OutlineInputBorder(),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    return [
      _buildCancelButton(context),
      _buildSaveButton(context),
    ];
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Cancel'),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _handleSave(context),
      child: Text(_getSaveButtonText()),
    );
  }

  String _getSaveButtonText() {
    return widget.isReviewTab 
        ? AppLocalizations.of(context)!.saveAndExecute 
        : 'Save';
  }

  void _handleSave(BuildContext context) {
    final newTranscription = _controller.text.trim();
    if (newTranscription.isNotEmpty && newTranscription != widget.currentTranscription) {
      _updateTranscription(newTranscription);
      _showSuccessMessage(context);
    }
    Navigator.of(context).pop();
  }

  void _updateTranscription(String newTranscription) {
    widget.ref.read(queueProvider.notifier).updateCommandTranscription(widget.id, newTranscription);
    
    if (widget.isReviewTab) {
      _handleReviewTabSave();
    }
  }

  void _handleReviewTabSave() {
    // Clear failed flag and error message
    widget.ref.read(queueProvider.notifier).updateCommandFailed(widget.id, false);
    widget.ref.read(queueProvider.notifier).updateCommandErrorMessage(widget.id, null);
    
    // Move to queued status for processing
    widget.ref.read(queueProvider.notifier).updateCommandStatus(widget.id, CommandStatus.queued);
  }

  void _showSuccessMessage(BuildContext context) {
    final message = widget.isReviewTab 
        ? 'Transcription updated and queued for processing'
        : 'Transcription updated successfully';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(milliseconds: DesignTokens.delaySnackbar),
      ),
    );
  }
}
