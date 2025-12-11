// Notification service: wrapper over local notifications for installment reminders.
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
// Timezone scheduling is intentionally omitted to avoid package API
// compatibility issues across flutter_local_notifications versions.
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../settings/settings_repository.dart';
import '../../core/utils/jalali_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();
  factory NotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'installments_channel';
  static const String _channelName = 'Installment Reminders';
  static const String _channelDescription = 'Reminders for loan installments';

  Future<void> init() async {
    // Initialize timezone package
    tzdata.initializeTimeZones();
    try {
      import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
      import 'package:flutter_local_notifications/flutter_local_notifications.dart';
      import 'package:flutter_native_timezone/flutter_native_timezone.dart';
      import 'package:timezone/data/latest_all.dart' as tzdata;
      import 'package:timezone/timezone.dart' as tz;

      import '../db/database_helper.dart';
      import '../settings/settings_repository.dart';
      import '../../core/utils/jalali_utils.dart';

      class NotificationService {
        static final NotificationService instance = NotificationService._internal();
        NotificationService._internal();
        factory NotificationService() => instance;

        final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

        static const String _channelId = 'installments_channel';
        static const String _channelName = 'Installment Reminders';
        static const String _channelDescription = 'Reminders for loan installments';

        Future<void> init() async {
          // Initialize timezone package
          tzdata.initializeTimeZones();
          try {
            final String tzName = await FlutterNativeTimezone.getLocalTimezone();
            tz.setLocalLocation(tz.getLocation(tzName));
          } catch (_) {
            tz.setLocalLocation(tz.getLocation('UTC'));
          }

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
              // handle taps if needed
            },
          );

          const channel = AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: _channelDescription,
            importance: Importance.defaultImportance,
          );

          await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(channel);
          await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
          await _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>()?.requestPermissions(alert: true, badge: true, sound: true);
        }

        NotificationDetails get _defaultDetails {
          final android = AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
          );
          final ios = DarwinNotificationDetails();
          return NotificationDetails(android: android, iOS: ios);
        }

        Future<void> scheduleInstallmentReminder({
          required int notificationId,
          required DateTime scheduledTime,
          required String title,
          required String body,
        }) async {
          // Check if notifications are enabled in settings
          final settings = SettingsRepository();
          final notificationsEnabled = await settings.getNotificationsEnabled();
          final billRemindersEnabled = await settings.getBillRemindersEnabled();

          if (!notificationsEnabled || !billRemindersEnabled) {
            debugPrint('scheduleInstallmentReminder: notifications disabled in settings');
            return;
          }

          if (kIsWeb) {
            debugPrint('scheduleInstallmentReminder: skipping scheduling on web');
            return;
          }

          try {
            final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduledTime, tz.local);
            await _plugin.zonedSchedule(
              notificationId,
              title,
              body,
              tzTime,
              _defaultDetails,
              uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
              androidAllowWhileIdle: true,
              matchDateTimeComponents: null,
            );
          } catch (e) {
            // Fallback: try simple schedule via dynamic invocation for plugin versions without zonedSchedule
            try {
              final dyn = _plugin as dynamic;
              await dyn.schedule(notificationId, title, body, scheduledTime, _defaultDetails, androidAllowWhileIdle: true);
            } catch (e2) {
              debugPrint('Failed to schedule notification: $e2');
            }
          }
        }

        Future<void> scheduleBudgetAlert({
          required int notificationId,
          required DateTime scheduledTime,
          required String title,
          required String body,
        }) async {
          await scheduleInstallmentReminder(notificationId: notificationId, scheduledTime: scheduledTime, title: title, body: body);
        }

        Future<void> scheduleMonthEndSummary({
          required int notificationId,
          required DateTime monthDate,
          required String title,
          required String body,
        }) async {
          // schedule for the last day of the given month at 18:00
          final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
          final scheduled = DateTime(lastDay.year, lastDay.month, lastDay.day, 18, 0);
          await scheduleInstallmentReminder(notificationId: notificationId, scheduledTime: scheduled, title: title, body: body);
        }

        Future<void> scheduleSmartSuggestion({
          required int notificationId,
          required DateTime scheduledTime,
          required String title,
          required String body,
        }) async {
          await scheduleInstallmentReminder(notificationId: notificationId, scheduledTime: scheduledTime, title: title, body: body);
        }

        Future<void> cancelNotification(int notificationId) async {
          await _plugin.cancel(notificationId);
        }

        Future<void> cancelAll() async {
          await _plugin.cancelAll();
        }

        /// Rebuild scheduled notifications from DB (future installments).
        Future<void> rebuildScheduledNotifications() async {
          final settings = SettingsRepository();
          final notificationsEnabled = await settings.getNotificationsEnabled();
          final billRemindersEnabled = await settings.getBillRemindersEnabled();
          if (!notificationsEnabled || !billRemindersEnabled) return;

          final now = DateTime.now();
          final to = now.add(const Duration(days: 365));

          final db = DatabaseHelper.instance;
          final installments = await db.getUpcomingInstallments(now, to);

          // Cancel existing before rebuilding to avoid duplicates.
          await cancelAll();

          for (final inst in installments) {
            if (inst.id == null) continue;

            // parse Jalali date string to DateTime
            final jal = parseJalali(inst.dueDateJalali);
            final due = jalaliToDateTime(jal);

            final offset = await settings.getReminderOffsetDays();
            var scheduled = due.subtract(Duration(days: offset));
            // default time to 09:00 local
            scheduled = DateTime(scheduled.year, scheduled.month, scheduled.day, 9);

            final title = 'Installment due';
            final body = 'An installment of ${inst.amount} is due on ${inst.dueDateJalali}.';

            final nid = inst.id! + 1000; // simple id mapping
            await scheduleInstallmentReminder(notificationId: nid, scheduledTime: scheduled, title: title, body: body);
          }
        }
    // schedule for the last day of the given month at 18:00
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final scheduled = DateTime(lastDay.year, lastDay.month, lastDay.day, 18, 0);
    await scheduleInstallmentReminder(notificationId: notificationId, scheduledTime: scheduled, title: title, body: body);
  }

  Future<void> scheduleSmartSuggestion({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await scheduleInstallmentReminder(notificationId: notificationId, scheduledTime: scheduledTime, title: title, body: body);
>>>>>>> 6b5512b (Implement localization support, onboarding flow, and notification enhancements; refactor app structure for improved settings management)
  }

  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

<<<<<<< HEAD
  /// Cancel all scheduled notifications.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
=======
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Rebuild scheduled notifications from DB (future installments).
  Future<void> rebuildScheduledNotifications() async {
    final settings = SettingsRepository();
    await settings.init();
    if (!settings.remindersEnabled) return;

    final now = DateTime.now();
    final to = now.add(const Duration(days: 365));

    final db = DatabaseHelper();
    final installments = await db.getUpcomingInstallments(now, to);

    // Cancel existing before rebuilding to avoid duplicates.
    await cancelAll();

    for (final inst in installments) {
      if (inst.id == null) continue;

      // parse Jalali date string to DateTime
      final jal = parseJalali(inst.dueDateJalali);
      final due = jalaliToDateTime(jal);

      final offset = settings.reminderOffsetDays;
      var scheduled = due.subtract(Duration(days: offset));
      // default time to 09:00 local
      scheduled = DateTime(scheduled.year, scheduled.month, scheduled.day, 9);

      final title = 'Installment due';
      final body = 'An installment of ${inst.amount} is due on ${inst.dueDateJalali}.';

      final nid = inst.id! + 1000; // simple id mapping
      await scheduleInstallmentReminder(notificationId: nid, scheduledTime: scheduled, title: title, body: body);
    }
  }
>>>>>>> 6b5512b (Implement localization support, onboarding flow, and notification enhancements; refactor app structure for improved settings management)
}

