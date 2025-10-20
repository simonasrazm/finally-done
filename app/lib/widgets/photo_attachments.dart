import 'package:flutter/material.dart';
import 'dart:io';
import '../design_system/tokens.dart';
import '../design_system/typography.dart';
import '../utils/photo_service.dart';
import '../widgets/photo_gallery_dialog.dart';
import '../generated/app_localizations.dart';
import '../design_system/colors.dart';

class PhotoAttachments extends StatelessWidget {

  const PhotoAttachments({
    super.key,
    required this.photoPaths,
    required this.onPhotoTap,
  });
  final List<String> photoPaths;
  final VoidCallback onPhotoTap;

  @override
  Widget build(BuildContext context) {
    if (photoPaths.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: DesignTokens.spacing3),
        Text(
          AppLocalizations.of(context)!.photosCount(photoPaths.length),
          style: AppTypography.caption1.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: DesignTokens.spacing2),
        SizedBox(
          height: DesignTokens.photoPreviewHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: photoPaths.length,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.only(right: DesignTokens.spacing2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                  child: FutureBuilder<String?>(
                    future: PhotoService.getThumbnailPath(photoPaths[index]),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return GestureDetector(
                          onTap: () async {
                            final photoPath = await PhotoService.getPhotoPath(photoPaths[index]);
                            _showPhotoPreview(photoPath, photoPaths, context);
                          },
                          child: Container(
                            width: DesignTokens.photoPreviewWidth,
                            height: DesignTokens.photoPreviewHeight,
                            color: AppColors.getSecondaryBackgroundColor(context),
                            child: Image.file(
                              File(snapshot.data!),
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: DesignTokens.photoPreviewWidth,
                                  height: DesignTokens.photoPreviewHeight,
                                  color: AppColors.separator,
                                  child: const Icon(Icons.image_not_supported),
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        return Container(
                          width: DesignTokens.photoPreviewWidth,
                          height: DesignTokens.photoPreviewHeight,
                          color: AppColors.separator,
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
    );
  }

  void _showPhotoPreview(String photoPath, List<String> allPhotoPaths, BuildContext context) {
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
}
