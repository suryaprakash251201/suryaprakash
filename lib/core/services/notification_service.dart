import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (reminder.dateTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'suryaprakash_reminders',
      'Reminders channel',
      channelDescription: 'Channel for reminder notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    // For MVP, show notification immediately. Production would use zonedSchedule.
    await _plugin.show(
      id: reminder.id.hashCode,
      title: reminder.title,
      body: reminder.description ?? 'Reminder',
      notificationDetails: details,
    );
  }

  Future<void> cancelReminder(int notificationId) async {
    await _plugin.cancel(id: notificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
