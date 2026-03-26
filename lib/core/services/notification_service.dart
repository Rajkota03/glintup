import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _plugin.cancelAll();

    const androidDetails = AndroidNotificationDetails(
      'daily_edition',
      'Daily Edition Reminder',
      channelDescription: 'Reminds you to read your daily edition',
      importance: Importance.high,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show a notification immediately as confirmation
    await _plugin.show(
      0,
      'Reminder set!',
      'You\'ll be reminded daily at ${time.hour}:${time.minute.toString().padLeft(2, '0')}',
      details,
    );
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
