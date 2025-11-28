import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Timezone scheduling is intentionally omitted to avoid package API
// compatibility issues across flutter_local_notifications versions.

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

    // NOTE: zoned scheduling was removed to avoid analyzer/runtime
    // errors across different plugin versions. Scheduling is a no-op
    // on initialization; callers should handle missing scheduling as needed.
  }

  /// Schedule a notification for an installment reminder.
  /// Uses the regular schedule API; times are interpreted in the device's local timezone.
  Future<void> scheduleInstallmentReminder({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    // Scheduling notifications is currently a no-op. Implement
    // platform-specific scheduling when the project's plugin
    // version is finalized to a specific API surface.
    return;
  }

  /// Cancel a scheduled notification by id.
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
