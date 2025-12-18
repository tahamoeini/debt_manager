import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/notifications/smart_notification_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:debt_manager/core/security/security_service.dart';

// Auth notifier used by GoRouter as a refreshable ChangeNotifier.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._settings);

  final SettingsRepository _settings;
  bool _unlocked = false;

  bool get unlocked => _unlocked;

  Future<void> tryUnlock() async {
    final enabled = await _settings.getBiometricEnabled();
    if (!enabled) {
      _unlocked = true;
      notifyListeners();
      return;
    }
    final avail = await SecurityService.instance.isBiometricAvailable();
    if (!avail) {
      _unlocked = true;
      notifyListeners();
      return;
    }
    final ok = await SecurityService.instance.authenticate();
    _unlocked = ok;
    notifyListeners();
  }

  void lock() {
    _unlocked = false;
    notifyListeners();
  }

  /// Mark app as unlocked (used after successful PIN/biometric via UI).
  void unlock() {
    _unlocked = true;
    notifyListeners();
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  return AuthNotifier(ref.read(settingsRepositoryProvider));
});

// Provides the shared DatabaseHelper singleton.
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// Provides the SmartNotificationService singleton.
final smartNotificationServiceProvider = Provider<SmartNotificationService>((
  ref,
) {
  return SmartNotificationService.instance;
});

// Provides SettingsRepository singleton.
final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository();
});

// Simple refresh trigger used across the app to request reloads.
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

// Simple in-memory cache for report computations. Keys are arbitrary strings
// (e.g. 'spendingByCategory:2025-12'). Consumers should invalidate when
// underlying data changes (e.g. when loans/installments are modified).
final reportsCacheProvider =
    StateProvider<Map<String, dynamic>>((ref) => {});

/// Cache helper extension for type-safe access to reportsCacheProvider.
extension ReportsCacheHelper on StateController<Map<String, dynamic>> {
  T? get<T>(String key) {
    final v = state[key];
    if (v is T) return v;
    return null;
  }

  void put(String key, dynamic value) {
    state = {...state, key: value};
  }

  void invalidate(String key) {
    final copy = {...state};
    copy.remove(key);
    state = copy;
  }

  void clear() {
    state = {};
  }
}
