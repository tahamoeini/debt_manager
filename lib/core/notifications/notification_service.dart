import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:flutter_native_timezone/flutter_native_timezone.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const String _channelId = 'installments_channel';
  static const String _channelName = 'Installment Reminders';
  static const String _channelDescription = 'Reminders for loan installments';

  /// Initialize the notification plugin (Android & iOS) and request permissions.
  Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    final iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {
        // App can handle notification taps here if needed.
      },
    );

    // Create Android notification channel (required for Android 8+).
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
    );

    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);

    // Request iOS and macOS permissions explicitly as a best practice.
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);

    // Initialize timezone data for zoned scheduling
    try {
      tzdata.initializeTimeZones();
      final String localTimeZone = await FlutterNativeTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimeZone));
    } catch (_) {
      // If timezone initialization fails, fallback to UTC (not ideal but prevents crash).
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  /// Schedule a notification for an installment reminder.
  /// Uses the regular schedule API; times are interpreted in the device's local timezone.
  Future<void> scheduleInstallmentReminder({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = DarwinNotificationDetails();

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Use zonedSchedule for reliable scheduling across timezones and DST
    final tzScheduled = tz.TZDateTime.from(scheduledTime, tz.local);

    await _plugin.zonedSchedule(
      notificationId,
      title,
      body,
      tzScheduled,
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null,
    );
  }

  /// Cancel a scheduled notification by id.
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
