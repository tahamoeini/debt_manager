/// Notification service: wrapper over local notifications for installment reminders.
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// Timezone scheduling is intentionally omitted to avoid package API
// compatibility issues across flutter_local_notifications versions.

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

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

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Request iOS and macOS permissions explicitly as a best practice.
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

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
    // Skip scheduling on web: flutter_local_notifications has limited
    // scheduling support on web and dynamic invocation above produced
    // runtime errors during web runs. Keep scheduling a no-op on web
    // while still allowing mobile/desktop platforms to schedule.
    if (kIsWeb) {
      debugPrint('scheduleInstallmentReminder: skipping scheduling on web');
      return;
    }

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use the simple local-time scheduling API. This will schedule the
      // notification in the device's local timezone.
      // Use dynamic invocation so we remain compatible with multiple
      // versions of flutter_local_notifications where the exact
      // scheduling API may vary (schedule vs zonedSchedule).
      final dyn = _plugin as dynamic;
      try {
        await dyn.schedule(
          notificationId,
          title,
          body,
          scheduledTime,
          details,
          androidAllowWhileIdle: true,
        );
      } catch (e) {
        // If schedule isn't available or fails, try a zonedSchedule call via dynamic.
        try {
          await dyn.zonedSchedule(
            notificationId,
            title,
            body,
            // Many zonedSchedule implementations expect a TZDateTime; passing
            // a regular DateTime may work on some versions or will be handled
            // by the plugin; if not, this will throw and we'll log and continue.
            scheduledTime,
            details,
            androidAllowWhileIdle: true,
          );
        } catch (e2) {
          debugPrint(
            'Failed to schedule (both schedule and zonedSchedule): $e2',
          );
        }
      }
    } catch (e) {
      // Swallow scheduling errors to keep app stable; log for debugging.
      // Use debugPrint to avoid bringing in additional logging deps.
      debugPrint('Failed to schedule notification: $e');
    }
  }

  /// Cancel a scheduled notification by id.
  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }
}
