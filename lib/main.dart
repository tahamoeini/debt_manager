import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/db/database_helper.dart';
import 'core/notifications/notification_service.dart';
import 'core/notifications/smart_notification_service.dart';
import 'core/settings/settings_repository.dart';
import 'core/smart_insights/smart_insights_service.dart';
import 'core/debug/debug_logger.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handlers for easier debugging in debug builds.
  final logger = DebugLogger();
  FlutterError.onError = (details) {
    logger.error(details.exceptionAsString(), details.stack);
    // Still forward to Flutter's default handler in debug.
    FlutterError.presentError(details);
  };

  // Capture any uncaught errors in zones.
  runZonedGuarded(() async {

  await DatabaseHelper.instance.refreshOverdueInstallments(DateTime.now());

  final settings = SettingsRepository();
  // Warm up settings getters for downstream callers.
  try {
    await settings.getBiometricEnabled();
  } catch (_) {}

  await NotificationService().init();
  await SmartNotificationService().init();
  await NotificationService().rebuildScheduledNotifications();

  try {
    final smartEnabled = await settings.getSmartSuggestionsEnabled();
    if (smartEnabled) await SmartInsightsService().runInsights(notify: false);
  } catch (_) {}

    runApp(const ProviderScope(child: DebtManagerApp()));
  }, (error, stack) {
    logger.error(error, stack);
  });
}
