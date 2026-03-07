import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:developer' as developer;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
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

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        developer.log('Notification clicked: ${details.payload}',
            name: 'NotificationService');
      },
    );

    // Request Android 13+ permissions
    final androidImplementation =
        _notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    developer.log('Notification service initialized',
        name: 'NotificationService');
  }

  Future<void> showHeadsUpNotification({
    required String title,
    required String body,
    String? payload,
    int repeatCount = 3,
  }) async {
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'high_importance_channel_v2', // id
        'High Importance Notifications', // title
        channelDescription: 'This channel is used for important notifications.',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        playSound: true,
        enableLights: true,
        channelShowBadge: true,
        // Using high/max importance enables heads-up (top popup) on Android
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

      for (int i = 0; i < repeatCount; i++) {
        await _notificationsPlugin.show(
          // Use a consistent ID for the pulse but unique enough to trigger sound
          (DateTime.now().millisecondsSinceEpoch ~/ 1000) + i,
          title,
          body,
          platformDetails,
          payload: payload,
        );
        if (i < repeatCount - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      developer.log(
          'Heads-up notification pulse triggered ($repeatCount times): $title',
          name: 'NotificationService');
    } catch (e) {
      developer.log('Error showing notification: $e',
          name: 'NotificationService');
    }
  }
}
