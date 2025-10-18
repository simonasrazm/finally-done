import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:finally_done/design_system/colors.dart';
import 'package:finally_done/design_system/tokens.dart';

/// Dialog widget for displaying photo gallery
class PhotoGalleryDialog extends StatefulWidget {
  final List<String> allPhotoPaths;
  final int initialIndex;

  const PhotoGalleryDialog({
    super.key,
    required this.allPhotoPaths,
    required this.initialIndex,
  });

  @override
  State<PhotoGalleryDialog> createState() => _PhotoGalleryDialogState();
}

class _PhotoGalleryDialogState extends State<PhotoGalleryDialog> {
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
                      width: DesignTokens.spacing2,
                      height: DesignTokens.spacing2,
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
