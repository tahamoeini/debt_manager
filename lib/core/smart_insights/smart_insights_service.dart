import '../notifications/notification_service.dart';
import '../settings/settings_repository.dart';
import 'package:debt_manager/core/insights/smart_insights_service.dart'
  as insights_engine;

// Lightweight orchestrator that runs the insights detection engine and
// converts findings into scheduled suggestion notifications. The heavy
// detection work runs in isolates inside `core/insights/smart_insights_service.dart`.
class SmartInsightsService {
  static final SmartInsightsService instance = SmartInsightsService._internal();
  SmartInsightsService._internal();
  factory SmartInsightsService() => instance;

  final NotificationService _notifier = NotificationService();

  // Run insights analysis once and optionally schedule suggestion notifications.
  Future<void> runInsights({bool notify = true}) async {
    final settings = SettingsRepository();
    await settings.init();
    if (!settings.smartInsightsEnabled) return;

    try {
      // Detect subscriptions and bill changes (runs in isolates internally)
        final subs = await insights_engine.SmartInsightsService.instance
          .detectSubscriptions();
        final bills = await insights_engine.SmartInsightsService.instance
          .detectBillChanges();
        final anomalies =
          await insights_engine.SmartInsightsService.instance.detectAnomalies();

      if (!notify) return;

      var nid = 10000;
      for (final s in subs) {
          final scheduled = DateTime.now().add(const Duration(seconds: 2));
        await _notifier.scheduleSmartSuggestion(
          notificationId: nid++,
          scheduledTime: scheduled,
          title: 'Subscription detected',
          body: insights_engine.SmartInsightsService()
            .generateSuggestionMessage(s),
        );
      }

      for (final b in bills) {
          final scheduled = DateTime.now().add(const Duration(seconds: 3));
        await _notifier.scheduleSmartSuggestion(
          notificationId: nid++,
          scheduledTime: scheduled,
          title: 'Bill change detected',
          body: insights_engine.SmartInsightsService()
            .generateBillChangeMessage(b),
        );
      }

      for (final a in anomalies) {
        final scheduled = DateTime.now().add(const Duration(seconds: 4));
        await _notifier.scheduleSmartSuggestion(
          notificationId: nid++,
          scheduledTime: scheduled,
          title: 'Unusual spending detected',
          body: a['description'] as String? ?? 'Anomaly detected',
        );
      }
    } catch (_) {}
  }
}
