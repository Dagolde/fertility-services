import 'package:flutter/foundation.dart';
import '../repositories/notification_repository.dart';

class NotificationProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _preferences = {};

  List<dynamic> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get preferences => _preferences;

  Future<void> loadNotifications({int skip = 0, int limit = 50}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _notifications = await _repository.getNotifications(skip: skip, limit: limit);
      await loadUnreadCount();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await _repository.getUnreadCount();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> markAsRead(int notificationId) async {
    try {
      final success = await _repository.markAsRead(notificationId);
      if (success) {
        // Update local state
        final index = _notifications.indexWhere((n) => n['id'] == notificationId);
        if (index != -1) {
          _notifications[index]['read_at'] = DateTime.now().toIso8601String();
        }
        await loadUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAllAsRead() async {
    try {
      final success = await _repository.markAllAsRead();
      if (success) {
        // Update local state
        for (var notification in _notifications) {
          notification['read_at'] = DateTime.now().toIso8601String();
        }
        _unreadCount = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteNotification(int notificationId) async {
    try {
      final success = await _repository.deleteNotification(notificationId);
      if (success) {
        _notifications.removeWhere((n) => n['id'] == notificationId);
        await loadUnreadCount();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> loadPreferences() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _preferences = await _repository.getPreferences();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updatePreferences(Map<String, dynamic> preferences) async {
    try {
      final success = await _repository.updatePreferences(preferences);
      if (success) {
        _preferences = preferences;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Group notifications by date
  Map<String, List<dynamic>> get groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<dynamic>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (var notification in _notifications) {
      final createdAt = DateTime.parse(notification['created_at']);
      final date = DateTime(createdAt.year, createdAt.month, createdAt.day);

      if (date == today) {
        grouped['Today']!.add(notification);
      } else if (date == yesterday) {
        grouped['Yesterday']!.add(notification);
      } else {
        grouped['Earlier']!.add(notification);
      }
    }

    return grouped;
  }
}
