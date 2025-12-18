// Notification service: wrapper over local notifications for installment reminders.
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../settings/settings_repository.dart';
import '../utils/jalali_utils.dart';
import 'notification_ids.dart';

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
    tzdata.initializeTimeZones();
    try {
      // Try to determine the local IANA timezone. When the flutter_native_timezone
      // plugin is unavailable (CI or removed), fall back to system timezone name
      // and ultimately UTC if not resolvable.
      final String sysTz = DateTime.now().timeZoneName;
      try {
        tz.setLocalLocation(tz.getLocation(sysTz));
      } catch (_) {
        // Not an IANA name; fallback to UTC
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(android: androidInit, iOS: iosInit);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (response) {},
    );

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
  }

  NotificationDetails get _defaultDetails {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: ios);
  }

  Future<void> scheduleInstallmentReminder({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    final settingsRepo = SettingsRepository();
    final notificationsEnabled = await settingsRepo.getNotificationsEnabled();
    final billRemindersEnabled = await settingsRepo.getBillRemindersEnabled();

    if (!notificationsEnabled || !billRemindersEnabled) {
      debugPrint(
        'scheduleInstallmentReminder: notifications disabled in settings',
      );
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      try {
        final dyn = _plugin as dynamic;
        await dyn.schedule(
          notificationId,
          title,
          body,
          scheduledTime,
          _defaultDetails,
        );
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
    await scheduleInstallmentReminder(
      notificationId: notificationId,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  Future<void> scheduleMonthEndSummary({
    required int notificationId,
    required DateTime monthDate,
    required String title,
    required String body,
  }) async {
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final scheduled = DateTime(lastDay.year, lastDay.month, lastDay.day, 18, 0);
    await scheduleInstallmentReminder(
      notificationId: notificationId,
      scheduledTime: scheduled,
      title: title,
      body: body,
    );
  }

  Future<void> scheduleSmartSuggestion({
    required int notificationId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    await scheduleInstallmentReminder(
      notificationId: notificationId,
      scheduledTime: scheduledTime,
      title: title,
      body: body,
    );
  }

  Future<void> cancelNotification(int notificationId) async {
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // Backwards-compatible alias used in some screens
  Future<void> cancelAllNotifications() async => cancelAll();

  Future<void> rebuildScheduledNotifications() async {
    final settings = SettingsRepository();
    final notificationsEnabled = await settings.getNotificationsEnabled();
    final billRemindersEnabled = await settings.getBillRemindersEnabled();
    if (!notificationsEnabled || !billRemindersEnabled) return;

    final now = DateTime.now();
    final to = now.add(const Duration(days: 365));

    final db = DatabaseHelper.instance;
    final installments = await db.getUpcomingInstallments(now, to);

    await cancelAll();

    for (final inst in installments) {
      if (inst.id == null) continue;

      final jal = parseJalali(inst.dueDateJalali);
      final due = jalaliToDateTime(jal);

      final offset = await settings.getReminderOffsetDays();
      var scheduled = due.subtract(Duration(days: offset));
      scheduled = DateTime(scheduled.year, scheduled.month, scheduled.day, 9);

      const title = 'Installment due';
      final body =
          'An installment of ${inst.amount} is due on ${inst.dueDateJalali}.';

      final nid = NotificationIds.forInstallment(inst.id!);
      await scheduleInstallmentReminder(
        notificationId: nid,
        scheduledTime: scheduled,
        title: title,
        body: body,
      );
    }
  }
}
