import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class NotificationRepository {
  static const String _basePath = '/notifications';

  Future<List<dynamic>> getNotifications({int skip = 0, int limit = 50}) async {
    try {
      debugPrint('🔍 NotificationRepository.getNotifications() called');
      
      final response = await ApiService.get(
        _basePath,
        queryParameters: {'skip': skip, 'limit': limit},
      );

      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getNotifications error: $e');
      rethrow;
    }
  }

  Future<int> getUnreadCount() async {
    try {
      debugPrint('🔍 NotificationRepository.getUnreadCount() called');
      
      final response = await ApiService.get('$_basePath/unread-count');

      if (response.statusCode == 200) {
        return response.data['unread_count'] ?? 0;
      } else {
        throw Exception('Failed to load unread count: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getUnreadCount error: $e');
      rethrow;
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      debugPrint('🔍 NotificationRepository.markAsRead($notificationId) called');
      
      final response = await ApiService.put('$_basePath/$notificationId/read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ markAsRead error: $e');
      rethrow;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      debugPrint('🔍 NotificationRepository.markAllAsRead() called');
      
      final response = await ApiService.put('$_basePath/mark-all-read');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ markAllAsRead error: $e');
      rethrow;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      debugPrint('🔍 NotificationRepository.deleteNotification($notificationId) called');
      
      final response = await ApiService.delete('$_basePath/$notificationId');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ deleteNotification error: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getPreferences() async {
    try {
      debugPrint('🔍 NotificationRepository.getPreferences() called');
      
      final response = await ApiService.get('$_basePath/preferences');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load preferences: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ getPreferences error: $e');
      rethrow;
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      debugPrint('🔍 NotificationRepository.updatePreferences() called');
      
      final response = await ApiService.put(
        '$_basePath/preferences',
        data: preferences,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('❌ updatePreferences error: $e');
      rethrow;
    }
  }
}
