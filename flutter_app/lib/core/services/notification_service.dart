import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../config/app_config.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  static Future<void> init() async {
    // Initialize timezone
    tz.initializeTimeZones();

    // Initialize local notifications
    await _initLocalNotifications();

    // Initialize Firebase messaging
    await _initFirebaseMessaging();

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
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

  static Future<void> _initFirebaseMessaging() async {
    // Request permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('User granted provisional permission');
    } else {
      debugPrint('User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await StorageService.setSecureString('fcm_token', token);
      debugPrint('FCM Token: $token');
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((String token) {
      StorageService.setSecureString('fcm_token', token);
      debugPrint('FCM Token refreshed: $token');
    });

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Received foreground message: ${message.messageId}');

    // Show local notification when app is in foreground
    await showNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'New Message',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.messageId}');
    // Handle navigation based on message data
    _navigateBasedOnNotification(message.data);
  }

  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    // Handle local notification tap
    if (response.payload != null) {
      // Parse payload and navigate accordingly
      _navigateBasedOnPayload(response.payload!);
    }
  }

  static void _navigateBasedOnNotification(Map<String, dynamic> data) {
    // Implement navigation logic based on notification data
    final type = data['type'];
    final id = data['id'];

    switch (type) {
      case 'appointment':
        // Navigate to appointment details
        break;
      case 'message':
        // Navigate to chat
        break;
      case 'payment':
        // Navigate to payment screen
        break;
      default:
        // Navigate to home
        break;
    }
  }

  static void _navigateBasedOnPayload(String payload) {
    // Parse payload and navigate
    try {
      // Implement payload parsing and navigation
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
    DateTime? scheduledDate,
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

    if (scheduledDate != null) {
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformDetails,
        payload: payload,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } else {
      await _localNotifications.show(
        id,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    }
  }

  // Schedule appointment reminder
  static Future<void> scheduleAppointmentReminder({
    required int appointmentId,
    required String title,
    required String body,
    required DateTime appointmentDate,
  }) async {
    // Schedule 24 hours before
    final reminderDate = appointmentDate.subtract(const Duration(hours: 24));
    if (reminderDate.isAfter(DateTime.now())) {
      await showNotification(
        id: appointmentId * 1000, // Unique ID for 24h reminder
        title: 'Appointment Reminder',
        body: 'You have an appointment tomorrow: $title',
        payload: 'appointment:$appointmentId',
        scheduledDate: reminderDate,
      );
    }

    // Schedule 1 hour before
    final hourReminderDate = appointmentDate.subtract(const Duration(hours: 1));
    if (hourReminderDate.isAfter(DateTime.now())) {
      await showNotification(
        id: appointmentId * 1000 + 1, // Unique ID for 1h reminder
        title: 'Appointment Starting Soon',
        body: 'Your appointment starts in 1 hour: $title',
        payload: 'appointment:$appointmentId',
        scheduledDate: hourReminderDate,
      );
    }
  }

  // Cancel notification
  static Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Cancel all notifications
  static Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Get pending notifications
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }

  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Get FCM token
  static Future<String?> getFCMToken() async {
    return await StorageService.getSecureString('fcm_token');
  }

  // Update FCM token on server
  static Future<void> updateFCMTokenOnServer() async {
    final token = await getFCMToken();
    if (token != null) {
      // Send token to your backend server
      // Implement API call to update token
    }
  }

  // Handle notification permissions
  static Future<bool> requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final settings = await _firebaseMessaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
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

// Background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  
  // Handle background message
  await NotificationService.showNotification(
    id: message.hashCode,
    title: message.notification?.title ?? 'New Message',
    body: message.notification?.body ?? '',
    payload: message.data.toString(),
  );
}
