import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/notifications/smart_notification_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';

/// Provides the shared DatabaseHelper singleton.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Provides the SmartNotificationService singleton.
final smartNotificationServiceProvider = Provider<SmartNotificationService>((ref) {
  return SmartNotificationService.instance;
});

/// Provides SettingsRepository singleton.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

/// Simple refresh trigger used across the app to request reloads.
final refreshTriggerProvider = StateProvider<int>((ref) => 0);
