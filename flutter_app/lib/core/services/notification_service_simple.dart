import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../config/app_config.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    // Initialize local notifications only
    await _initLocalNotifications();
  }

  static Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    if (!kIsWeb) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        AppConfig.notificationChannelId,
        AppConfig.notificationChannelName,
        description: AppConfig.notificationChannelDescription,
        importance: Importance.high,
        playSound: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Handle local notification tap
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      _navigateBasedOnPayload(response.payload!);
    }
  }

  static void _navigateBasedOnPayload(String payload) {
    // Parse payload and navigate
    try {
      // Implement payload parsing and navigation
      debugPrint('Navigating based on payload: $payload');
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  // Show local notification
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      AppConfig.notificationChannelId,
      AppConfig.notificationChannelName,
      channelDescription: AppConfig.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Dummy methods for compatibility
  static Future<void> updateFCMTokenOnServer() async {
    // No-op for now
    debugPrint('FCM token update skipped (Firebase not initialized)');
  }

  static Future<bool> requestPermissions() async {
    // For local notifications, we assume permission is granted
    return true;
  }

  static Future<bool> areNotificationsEnabled() async {
    return true;
  }

  // Show message notification
  static Future<void> showMessageNotification({
    required int messageId,
    required String senderName,
    required String message,
  }) async {
    await showNotification(
      id: messageId,
      title: 'New message from $senderName',
      body: message,
      payload: 'message:$messageId',
    );
  }

  // Show appointment notification
  static Future<void> showAppointmentNotification({
    required int appointmentId,
    required String title,
    required String body,
  }) async {
    await showNotification(
      id: appointmentId,
      title: title,
      body: body,
      payload: 'appointment:$appointmentId',
    );
  }

  // Show payment notification
  static Future<void> showPaymentNotification({
    required int paymentId,
    required String title,
    required String body,
  }) async {
    await showNotification(
      id: paymentId,
      title: title,
      body: body,
      payload: 'payment:$paymentId',
    );
  }
}
