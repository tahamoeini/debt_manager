import '../db/database_helper.dart';
import '../notifications/notification_service.dart';
import '../settings/settings_repository.dart';
import '../../features/loans/models/installment.dart';
// removed unused import

class SmartInsightsService {
  static final SmartInsightsService instance = SmartInsightsService._internal();
  SmartInsightsService._internal();
  factory SmartInsightsService() => instance;

  final DatabaseHelper _db = DatabaseHelper();
  final NotificationService _notifier = NotificationService();

  // Run insights analysis once and optionally schedule suggestion notifications.
  Future<void> runInsights({bool notify = true}) async {
    final settings = SettingsRepository();
    await settings.init();
    if (!settings.smartInsightsEnabled) return;

    final now = DateTime.now();
    final to = now.add(const Duration(days: 60));
    final upcoming = await _db.getUpcomingInstallments(now, to);

    // Simple heuristic: if many installments fall on the same date, suggest consolidation.
    final byDate = <String, List<Installment>>{};
    for (final i in upcoming) {
      final key = i.dueDateJalali;
      byDate.putIfAbsent(key, () => []).add(i);
    }

    for (final entry in byDate.entries) {
      if (entry.value.length >= 3 && notify) {
        // create a suggestion notification
        final scheduled = DateTime.now().add(const Duration(seconds: 5));
        await _notifier.scheduleSmartSuggestion(
          notificationId: 9000 + scheduled.millisecondsSinceEpoch % 1000,
          scheduledTime: scheduled,
          title: 'Smart suggestion',
          body:
              'You have ${entry.value.length} payments on ${entry.key}. Consider consolidating subscriptions.',
        );
      }
    }
  }
}
