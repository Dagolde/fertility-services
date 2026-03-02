import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ImageCacheService {
  static const String _cacheKey = 'profile_images';
  static final CacheManager _cacheManager = DefaultCacheManager();

  /// Cache a profile image URL
  static Future<void> cacheProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isNotEmpty) {
        await _cacheManager.downloadFile(imageUrl);
        debugPrint('✅ Cached profile image: $imageUrl');
      }
    } catch (e) {
      debugPrint('❌ Failed to cache profile image: $e');
    }
  }

  /// Get cached profile image file
  static Future<File?> getCachedProfileImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return null;
      
      final file = await _cacheManager.getSingleFile(imageUrl);
      return file.existsSync() ? file : null;
    } catch (e) {
      debugPrint('❌ Failed to get cached profile image: $e');
      return null;
    }
  }

  /// Clear all cached profile images
  static Future<void> clearCache() async {
    try {
      await _cacheManager.emptyCache();
      debugPrint('✅ Cleared profile image cache');
    } catch (e) {
      debugPrint('❌ Failed to clear cache: $e');
    }
  }

  /// Remove specific image from cache
  static Future<void> removeFromCache(String imageUrl) async {
    try {
      await _cacheManager.removeFile(imageUrl);
      debugPrint('✅ Removed from cache: $imageUrl');
    } catch (e) {
      debugPrint('❌ Failed to remove from cache: $e');
    }
  }
}
