import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:finally_done/utils/thumbnail_service.dart';

/// Service for handling photo file operations
class PhotoService {
  /// Get full photo path from filename
  static Future<String> getPhotoPath(String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/photos/$fileName';
  }

  /// Get thumbnail path for a photo
  static Future<String?> getThumbnailPath(String fileName) async {
    final photoPath = await getPhotoPath(fileName);
    return await ThumbnailService.getThumbnailPath(photoPath);
  }

  /// Delete photo file and its thumbnail
  static Future<void> deletePhoto(String fileName) async {
    final fullPhotoPath = await getPhotoPath(fileName);
    final photoFile = File(fullPhotoPath);
    
    if (await photoFile.exists()) {
      await photoFile.delete();
    }
    
    // Also delete thumbnail
    await ThumbnailService.deleteThumbnail(fullPhotoPath);
  }

  /// Delete multiple photos
  static Future<void> deletePhotos(List<String> fileNames) async {
    for (final fileName in fileNames) {
      await deletePhoto(fileName);
    }
  }
}
