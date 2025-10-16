import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

/// Service for creating and managing image thumbnails
class ThumbnailService {
  static const int thumbnailSize = 160; // 80px * 2 for retina displays
  static const int thumbnailQuality = 60; // Lower quality for thumbnails
  
  /// Create a thumbnail for an image file
  static Future<String?> createThumbnail(String imagePath) async {
    try {
      // Read the original image
      final originalFile = File(imagePath);
      if (!await originalFile.exists()) {
        print('🖼️ THUMBNAIL: Original image not found: $imagePath');
        return null;
      }
      
      final originalBytes = await originalFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);
      
      if (originalImage == null) {
        print('🖼️ THUMBNAIL: Failed to decode image: $imagePath');
        return null;
      }
      
      // Create thumbnail
      final thumbnail = img.copyResize(
        originalImage,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.linear,
      );
      
      // Encode as JPEG with lower quality
      final thumbnailBytes = img.encodeJpg(thumbnail, quality: thumbnailQuality);
      
      // Save thumbnail
      final directory = await getApplicationDocumentsDirectory();
      final thumbnailsDir = Directory('${directory.path}/thumbnails');
      if (!await thumbnailsDir.exists()) {
        await thumbnailsDir.create(recursive: true);
      }
      
      final fileName = originalFile.path.split('/').last;
      final thumbnailPath = '${thumbnailsDir.path}/thumb_$fileName';
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(thumbnailBytes);
      
      print('🖼️ THUMBNAIL: Created thumbnail: $thumbnailPath');
      return thumbnailPath;
      
    } catch (e) {
      print('🖼️ THUMBNAIL: Error creating thumbnail: $e');
      return null;
    }
  }
  
  /// Get thumbnail path for an image, create if doesn't exist
  static Future<String?> getThumbnailPath(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = imagePath.split('/').last;
      final thumbnailPath = '${directory.path}/thumbnails/thumb_$fileName';
      final thumbnailFile = File(thumbnailPath);
      
      if (await thumbnailFile.exists()) {
        return thumbnailPath;
      }
      
      // Create thumbnail if it doesn't exist
      return await createThumbnail(imagePath);
      
    } catch (e) {
      print('🖼️ THUMBNAIL: Error getting thumbnail path: $e');
      return null;
    }
  }
  
  /// Delete thumbnail when original image is deleted
  static Future<void> deleteThumbnail(String imagePath) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final fileName = imagePath.split('/').last;
      final thumbnailPath = '${directory.path}/thumbnails/thumb_$fileName';
      final thumbnailFile = File(thumbnailPath);
      
      if (await thumbnailFile.exists()) {
        await thumbnailFile.delete();
        print('🖼️ THUMBNAIL: Deleted thumbnail: $thumbnailPath');
      }
    } catch (e) {
      print('🖼️ THUMBNAIL: Error deleting thumbnail: $e');
    }
  }
}
