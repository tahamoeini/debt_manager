import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/db/database_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/smart_notification_service.dart';
import 'core/settings/settings_repository.dart';
import 'core/smart_insights/smart_insights_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Refresh overdue statuses from DB
  await DatabaseHelper.instance.refreshOverdueInstallments(DateTime.now());

  // Initialize settings
  final settings = SettingsRepository();
  // HEAD-style SettingsRepository uses async getters and doesn't expose init(),
  // but some consumers expect an init; attempt to call if present.
  try {
    await settings.getBiometricEnabled();
  } catch (_) {}

  // Initialize notification channels and smart-notifications
  await NotificationService().init();
  await SmartNotificationService().init();

  // Rebuild scheduled notifications after init (e.g., after restore/import)
  await NotificationService().rebuildScheduledNotifications();

  // Run Smart Insights once on app launch
  try {
    final smartEnabled = await settings.getSmartSuggestionsEnabled();
    if (smartEnabled) await SmartInsightsService().runInsights(notify: false);
  } catch (_) {}

  runApp(const ProviderScope(child: DebtManagerApp()));
}
}
