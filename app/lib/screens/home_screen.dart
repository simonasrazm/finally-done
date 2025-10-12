import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

import '../design_system/colors.dart';
import '../design_system/typography.dart';
import '../services/speech_service.dart';
import '../services/nlp_service.dart';
import '../services/queue_service.dart';
import '../models/queued_command.dart';
import '../utils/logger.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isRecording = false;
  String _transcription = '';
  String _status = 'Ready to record';
  final TextEditingController _textController = TextEditingController();
  final List<String> _selectedPhotos = [];
  final ImagePicker _imagePicker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    
    // Pulse animation for recording button
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    // Scale animation for button press
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    _textController.dispose();
    super.dispose();
  }
  
  Widget _buildInputButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
      ),
    );
  }
  
  Future<void> _startRecording() async {
    if (_isRecording) return;
    
    setState(() {
      _isRecording = true;
      _status = 'Recording...';
      _transcription = '';
    });
    
    // Start pulse animation
    _pulseController.repeat(reverse: true);
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    try {
      final speechService = ref.read(speechServiceProvider);
      final enginePreference = ref.read(speechEngineProvider);
      
      if (enginePreference == 'gemini') {
        // For Gemini, start recording and wait for user to stop
        String result = await speechService.recognizeSpeech(
          enginePreference: enginePreference,
        );
        
        if (result == 'RECORDING_IN_PROGRESS') {
          // Don't change status, keep "Recording..." message
          // Don't process yet, wait for user to tap again
          return;
        }
      } else {
        // For iOS, use the old method
        String result = await speechService.recognizeSpeech(
          enginePreference: enginePreference,
        );
        
        setState(() {
          _transcription = result;
          _status = 'Processing...';
        });
        
        await _processCommand(result);
      }
      
    } catch (e, stackTrace) {
      // Log and send to Sentry
      Logger.handleException(e, stackTrace, tag: 'RECORDING', context: 'Voice recording failed');
      
      setState(() {
        _status = 'Error: ${e.toString()}';
        _isRecording = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  Future<void> _scheduleCommand(String text) async {
    if (text.trim().isEmpty) return;
    
    try {
      // Create command and add to queue
      final queueNotifier = ref.read(queueProvider.notifier);
      final command = QueuedCommandRealm(
        DateTime.now().millisecondsSinceEpoch.toString(),
        text.trim(),
        CommandStatus.queued.name,
        DateTime.now(),
        photoPaths: _selectedPhotos,
      );
      
      queueNotifier.addCommand(command);
      
      setState(() {
        _textController.clear();
        _transcription = '';
        _selectedPhotos.clear(); // Clear photos after scheduling
      });
      
      // Success haptic
      HapticFeedback.heavyImpact();
      
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _processCommand(String transcription) async {
    try {
      final nlpService = ref.read(nlpServiceProvider);
      final parsedCommand = await nlpService.parseCommand(transcription);
      
      setState(() {
        _status = 'Ready to record';
        _isRecording = false;
      });
      
      _pulseController.stop();
      _pulseController.reset();
      
      // Success haptic
      HapticFeedback.heavyImpact();
      
      // TODO: Execute commands if high confidence
      
    } catch (e) {
      setState(() {
        _status = 'Processing failed: ${e.toString()}';
        _isRecording = false;
      });
      _pulseController.stop();
      _pulseController.reset();
    }
  }
  
  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    
    setState(() {
      _isRecording = false;
      _status = 'Ready to record';
    });
    
    _pulseController.stop();
    _pulseController.reset();
    
    try {
      final speechService = ref.read(speechServiceProvider);
      final enginePreference = ref.read(speechEngineProvider);
      
      if (enginePreference == 'gemini') {
        // Stop recording and get audio path immediately
        String? audioPath = await speechService.stopRecording();
        
        if (audioPath != null && audioPath.isNotEmpty) {
          // Store the audio path in the speech service
          speechService.setCurrentAudioPath(audioPath);
          
          // Extract just the filename for storage
          final fileName = audioPath.split('/').last;
          await _scheduleVoiceCommand('Recording...', fileName);
          
          // Start background processing
          _processAudioInBackground(audioPath);
        }
      }
      
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    }
  }
  
  Future<void> _processAudioInBackground(String audioPath) async {
    try {
      final speechService = ref.read(speechServiceProvider);
      
      // Find the command by filename
      final queueNotifier = ref.read(queueProvider.notifier);
      final commands = ref.read(queueProvider);
      final fileName = audioPath.split('/').last;
      final command = commands.firstWhere(
        (cmd) => cmd.audioPath == fileName,
        orElse: () => throw Exception('Command not found'),
      );
      
      // Process audio in background
      String transcription = await speechService.processRecordedAudio();
      
      // Update with transcription and final status
      queueNotifier.updateCommandTranscription(command.id, transcription);
      queueNotifier.updateCommandStatus(command.id, CommandStatus.queued);
      
    } catch (e) {
      print('🎤 BACKGROUND: Error processing audio - $e');
      // Update status to failed
      final queueNotifier = ref.read(queueProvider.notifier);
      final commands = ref.read(queueProvider);
      final command = commands.firstWhere(
        (cmd) => cmd.audioPath == audioPath,
        orElse: () => throw Exception('Command not found'),
      );
      queueNotifier.updateCommandStatus(command.id, CommandStatus.failed);
    }
  }
  
  Future<void> _scheduleVoiceCommand(String transcription, String? audioPath) async {
    try {
      // Create command and add to queue
      final queueNotifier = ref.read(queueProvider.notifier);
      final command = QueuedCommandRealm(
        DateTime.now().millisecondsSinceEpoch.toString(),
        transcription,
        CommandStatus.recorded.name,
        DateTime.now(),
        audioPath: audioPath,
        photoPaths: _selectedPhotos,
      );
      
      queueNotifier.addCommand(command);
      
      setState(() {
        _transcription = '';
        _selectedPhotos.clear(); // Clear photos after scheduling
      });
      
      // Success haptic
      HapticFeedback.heavyImpact();
      
    } catch (e) {
      setState(() {
        _status = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80, // Compress to reduce file size
      );
      
      if (photo != null) {
        // Save to Photos app (user's main photo library)
        await photo.saveTo(photo.path); // This saves to Photos
        
        // Also save local copy to app's Documents directory
        final directory = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${directory.path}/photos');
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        
        final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final localPath = '${photosDir.path}/$fileName';
        await photo.saveTo(localPath);
        
        setState(() {
          _selectedPhotos.add(fileName); // Store just filename for local reference
        });
        
        print('📸 PHOTO: Saved to Photos and local copy as $fileName');
      }
    } catch (e) {
      print('📸 PHOTO: Error taking photo: $e');
      setState(() {
        _status = 'Error taking photo: ${e.toString()}';
      });
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final List<XFile> photos = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (photos.isNotEmpty) {
        final directory = await getApplicationDocumentsDirectory();
        final photosDir = Directory('${directory.path}/photos');
        if (!await photosDir.exists()) {
          await photosDir.create(recursive: true);
        }
        
        for (final photo in photos) {
          // Photos from gallery are already in Photos app, just create local copies
          final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}_${photos.indexOf(photo)}.jpg';
          final localPath = '${photosDir.path}/$fileName';
          await photo.saveTo(localPath);
          
          setState(() {
            _selectedPhotos.add(fileName);
          });
        }
        
        print('📸 PHOTO: Selected ${photos.length} photos from gallery and created local copies');
      }
    } catch (e) {
      print('📸 PHOTO: Error picking photos: $e');
      setState(() {
        _status = 'Error picking photos: ${e.toString()}';
      });
    }
  }


  Future<String> _getPhotoPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/photos/$fileName';
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finally Done'),
        backgroundColor: AppColors.getBackgroundColor(context),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Status text
              Text(
                _status,
                style: AppTypography.headline.copyWith(
                  color: _isRecording ? AppColors.error : AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              // Photo preview
              if (_selectedPhotos.isNotEmpty) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'Photos (${_selectedPhotos.length})',
                      style: AppTypography.headline.copyWith(
                        color: AppColors.getTextPrimaryColor(context),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedPhotos.clear();
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.clear,
                              size: 16,
                              color: AppColors.error,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Clear',
                              style: AppTypography.caption1.copyWith(
                                color: AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: FutureBuilder<String>(
                            future: _getPhotoPath(_selectedPhotos[index]),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.file(
                                  File(snapshot.data!),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image_not_supported),
                                    );
                                  },
                                );
                              } else {
                                return Container(
                                  width: 100,
                                  height: 100,
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
              
              const SizedBox(height: 40),
              
              // Main recording area with three buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Camera button on the left
                  _buildInputButton(
                    icon: Icons.camera_alt_outlined,
                    onTap: () => _takePhoto(),
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Main recording button
                  AnimatedBuilder(
                    animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _isRecording ? _pulseAnimation.value : _scaleAnimation.value,
                        child: GestureDetector(
                          onTapDown: (_) => _scaleController.forward(),
                          onTapUp: (_) {
                            _scaleController.reverse();
                            if (_isRecording) {
                              _stopRecording();
                            } else {
                              _startRecording();
                            }
                          },
                          onTapCancel: () => _scaleController.reverse(),
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: _isRecording
                                    ? [AppColors.error, AppColors.warning]
                                    : [AppColors.primary, AppColors.primaryDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _isRecording ? Icons.stop : Icons.mic,
                              size: 80,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(width: 20),
                  
                  // Photos button on the right
                  _buildInputButton(
                    icon: Icons.photo_library_outlined,
                    onTap: () => _pickFromGallery(),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Text input alternative
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.getSecondaryBackgroundColor(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.separator.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: const InputDecoration(
                          hintText: 'Or type your command...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: AppTypography.body,
                        onSubmitted: (text) {
                          if (text.isNotEmpty) {
                            _scheduleCommand(text);
                          }
                        },
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (_textController.text.isNotEmpty) {
                          _scheduleCommand(_textController.text);
                        }
                      },
                      icon: const Icon(Icons.send),
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Transcription result
              if (_transcription.isNotEmpty)
                Container(
                  width: double.infinity,
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
                      Text(
                        'Transcription:',
                        style: AppTypography.footnote.copyWith(
                          color: AppColors.getTextSecondaryColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _transcription,
                        style: AppTypography.body,
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}