// Notification service: wrapper over local notifications for installment reminders.
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../db/database_helper.dart';
import '../settings/settings_repository.dart';
import '../utils/jalali_utils.dart';
import 'notification_ids.dart';

/// Abstract plugin interface for testing.
abstract class NotificationPlugin {
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
  });
  Future<void> cancel(int id);
  Future<void> cancelAll();
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
  );
}

/// Real plugin adapter.
class RealNotificationPlugin implements NotificationPlugin {
  final FlutterLocalNotificationsPlugin _plugin;
  RealNotificationPlugin(this._plugin);

  /// Provides access to the underlying plugin for initialization purposes.
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  @override
  Future<void> zonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
  }) =>
      _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
      );

  @override
  Future<void> cancel(int id) => _plugin.cancel(id);

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> show(
    int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
  ) =>
      _plugin.show(id, title, body, notificationDetails);
}

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal()
      : _plugin = RealNotificationPlugin(
          FlutterLocalNotificationsPlugin(),
        );

  /// Constructor for testing with mock plugin.
  NotificationService.withPlugin(this._plugin);

  factory NotificationService() => instance;

  final NotificationPlugin _plugin;

  static const String _channelId = 'installments_channel';
  static const String _channelName = 'Installment Reminders';
  static const String _channelDescription = 'Reminders for loan installments';

  /// Initialize timezone data and notification channels.
  /// Must be called before scheduling any notifications.
  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('NotificationService.init: skipping initialization on web');
      return;
    }

    // Initialize timezone database
    tzdata.initializeTimeZones();
    try {
      // Set local timezone to UTC for consistent behavior across platforms
      tz.setLocalLocation(tz.getLocation('UTC'));
    } catch (_) {
      // Fallback to first available timezone
      try {
        final availableNames = tz.timeZoneDatabase.locations.keys.first;
        tz.setLocalLocation(tz.getLocation(availableNames));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    // Initialize plugin only if using real plugin
    if (_plugin is RealNotificationPlugin) {
      final realPlugin = (_plugin as RealNotificationPlugin).plugin;

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const settings =
          InitializationSettings(android: androidInit, iOS: iosInit);

      await realPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: (response) {},
      );

      const channel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.defaultImportance,
      );

      await realPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      await realPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      await realPlugin
          .resolvePlatformSpecificImplementation<
              MacOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
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

  /// Schedule a notification for an installment.
  /// Uses deterministic IDs based on installmentId and offsetDays.
  Future<void> scheduleInstallmentReminder({
    required int installmentId,
    required DateTime scheduledTime,
    required String title,
    required String body,
    int offsetDays = 0,
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

    // Generate deterministic notification ID
    final notificationId = offsetDays > 0
        ? NotificationIds.forInstallmentOffset(installmentId, offsetDays)
        : NotificationIds.forInstallmentDueDate(installmentId);

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
      debugPrint(
        'Scheduled notification $notificationId for installment $installmentId at $scheduledTime (offset: $offsetDays days)',
      );
    } catch (e) {
      debugPrint('Failed to schedule notification: $e');
      // Don't throw; notification scheduling is non-critical
    }
  }

  /// Cancel all notifications for a specific installment.
  /// This includes all offset-based reminders and due-date reminder.
  Future<void> cancelInstallmentNotifications(
    int installmentId,
    int maxOffsetDays,
  ) async {
    if (kIsWeb) {
      debugPrint('cancelInstallmentNotifications: skipping on web');
      return;
    }

    final ids = NotificationIds.allForInstallment(installmentId, maxOffsetDays);
    for (final id in ids) {
      try {
        await _plugin.cancel(id);
        debugPrint('Cancelled notification $id for installment $installmentId');
      } catch (e) {
        debugPrint('Failed to cancel notification $id: $e');
      }
    }
  }

  /// Reschedule notifications for an installment.
  /// Cancels existing notifications and schedules new ones.
  Future<void> rescheduleInstallmentNotifications({
    required int installmentId,
    required DateTime dueDate,
    required String title,
    required String body,
    required int offsetDays,
  }) async {
    // Cancel existing notifications using a fixed max offset so that any
    // previously scheduled reminders with larger offsets are also removed.
    const int kMaxInstallmentNotificationOffsetDays = 30;
    await cancelInstallmentNotifications(
      installmentId,
      kMaxInstallmentNotificationOffsetDays,
    );

    // Schedule offset reminder if offsetDays > 0
    if (offsetDays > 0) {
      final offsetScheduledTime = dueDate.subtract(Duration(days: offsetDays));
      final offsetScheduledTimeNormalized = DateTime(
        offsetScheduledTime.year,
        offsetScheduledTime.month,
        offsetScheduledTime.day,
        9, // 9 AM
      );

      if (offsetScheduledTimeNormalized.isAfter(DateTime.now())) {
        await scheduleInstallmentReminder(
          installmentId: installmentId,
          scheduledTime: offsetScheduledTimeNormalized,
          title: title,
          body: body,
          offsetDays: offsetDays,
        );
      }
    }

    // Schedule due-date reminder
    final dueDateScheduledTime = DateTime(
      dueDate.year,
      dueDate.month,
      dueDate.day,
      9, // 9 AM
    );

    if (dueDateScheduledTime.isAfter(DateTime.now())) {
      await scheduleInstallmentReminder(
        installmentId: installmentId,
        scheduledTime: dueDateScheduledTime,
        title: title,
        body: body,
        offsetDays: 0,
      );
    }
  }

  Future<void> scheduleBudgetAlert({
    required int budgetId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    final notificationId = NotificationIds.forBudgetAlert(budgetId);
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
      debugPrint('Failed to schedule budget alert: $e');
    }
  }

  Future<void> scheduleMonthEndSummary({
    required String period,
    required DateTime monthDate,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    final notificationId = NotificationIds.forMonthlySummary(period);
    final lastDay = DateTime(monthDate.year, monthDate.month + 1, 0);
    final scheduled = DateTime(lastDay.year, lastDay.month, lastDay.day, 18, 0);

    try {
      final tz.TZDateTime tzTime = tz.TZDateTime.from(scheduled, tz.local);
      await _plugin.zonedSchedule(
        notificationId,
        title,
        body,
        tzTime,
        _defaultDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      debugPrint('Failed to schedule month-end summary: $e');
    }
  }

  Future<void> scheduleSmartSuggestion({
    required int suggestionId,
    required DateTime scheduledTime,
    required String title,
    required String body,
  }) async {
    if (kIsWeb) return;

    final notificationId = NotificationIds.forSmartSuggestion(suggestionId);
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
      debugPrint('Failed to schedule smart suggestion: $e');
    }
  }

  Future<void> cancelNotification(int notificationId) async {
    if (kIsWeb) {
      debugPrint('cancelNotification: skipping on web');
      return;
    }
    await _plugin.cancel(notificationId);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) {
      debugPrint('cancelAll: skipping on web');
      return;
    }
    await _plugin.cancelAll();
  }

  // Backwards-compatible alias used in some screens
  Future<void> cancelAllNotifications() async => cancelAll();

  /// Rebuild all scheduled notifications from database state.
  /// Cancels all existing notifications and reschedules based on current installments.
  Future<void> rebuildScheduledNotifications() async {
    final settings = SettingsRepository();
    final notificationsEnabled = await settings.getNotificationsEnabled();
    final billRemindersEnabled = await settings.getBillRemindersEnabled();
    if (!notificationsEnabled || !billRemindersEnabled) return;

    if (kIsWeb) {
      debugPrint('rebuildScheduledNotifications: skipping on web');
      return;
    }

    final now = DateTime.now();
    final to = now.add(const Duration(days: 365));

    final db = DatabaseHelper.instance;
    final installments = await db.getUpcomingInstallments(now, to);

    // Cancel all existing notifications
    await cancelAll();

    // Get offset setting
    final offsetDays = await settings.getReminderOffsetDays();

    // Schedule notifications for each installment
    for (final inst in installments) {
      if (inst.id == null) continue;

      final jal = parseJalali(inst.dueDateJalali);
      final due = jalaliToDateTime(jal);

      const title = 'Installment due';
      final body =
          'An installment of ${inst.amount} is due on ${inst.dueDateJalali}.';

      // Schedule using new reschedule method which handles both offset and due-date
      await rescheduleInstallmentNotifications(
        installmentId: inst.id!,
        dueDate: due,
        title: title,
        body: body,
        offsetDays: offsetDays,
      );
    }

    debugPrint('Rebuilt ${installments.length} installment notifications');
  }
}
