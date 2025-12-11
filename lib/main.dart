
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

<<<<<<< HEAD
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
=======
  // Initialize settings and services before starting the UI.
  final settings = SettingsRepository();
  await settings.init();

>>>>>>> f389166 (Add settings screen, calendar picker, and enhance onboarding; implement user preferences for reminders, alerts, and language)
  await NotificationService().init();
  await SmartNotificationService().init();

  // Rebuild scheduled notifications from DB (if enabled)
  await NotificationService().rebuildScheduledNotifications();

<<<<<<< HEAD
  // Run Smart Insights once on app launch
  try {
    final smartEnabled = await settings.getSmartSuggestionsEnabled();
    if (smartEnabled) await SmartInsightsService().runInsights(notify: false);
  } catch (_) {}

  runApp(const ProviderScope(child: DebtManagerApp()));
}
=======
  // Run baseline smart insights once on app launch (no immediate notifications).
  if (settings.smartInsightsEnabled) {
    await SmartInsightsService().runInsights(notify: false);
  }

  runApp(DebtManagerApp(
    initialLocaleCode: settings.languageCode,
    showOnboarding: !settings.onboardingComplete,
  ));
>>>>>>> f389166 (Add settings screen, calendar picker, and enhance onboarding; implement user preferences for reminders, alerts, and language)
}
