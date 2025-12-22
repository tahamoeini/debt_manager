import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/notifications/smart_notification_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:debt_manager/core/security/security_service.dart';
import 'package:debt_manager/features/accounts/repositories/accounts_repository.dart';
import 'package:debt_manager/features/installments/repositories/installment_payments_repository.dart';
import 'dart:async';

// Auth notifier used by GoRouter as a refreshable ChangeNotifier.
class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._settings);

  final SettingsRepository _settings;
  bool _unlocked = false;
  bool _appLockEnabledCached = false;

  // Auto-lock duration after inactivity when app lock is enabled.
  final Duration _autoLockDuration = const Duration(minutes: 5);
  Timer? _inactivityTimer;

  bool get unlocked => _unlocked;
  bool get appLockEnabled => _appLockEnabledCached;

  // Load persisted app lock state on creation so routing can gate immediately.
  void _init() {
    _settings.getAppLockEnabled().then((enabled) {
      _appLockEnabledCached = enabled;
      if (!enabled) {
        _unlocked = true;
      }
      notifyListeners();
    });
  }

  // Factory helper to ensure initialization when provided.
  factory AuthNotifier.withInit(SettingsRepository settings) {
    final n = AuthNotifier(settings);
    n._init();
    return n;
  }

  Future<void> tryUnlock() async {
    // If app lock is disabled, we're always considered unlocked.
    final appLockEnabled = await _settings.getAppLockEnabled();
    _appLockEnabledCached = appLockEnabled;
    if (!appLockEnabled) {
      _unlocked = true;
      _startInactivityTimer();
      notifyListeners();
      return;
    }

    // App lock is enabled. Decide based on biometric availability/setting.
    final biometricSettingEnabled = await _settings.getBiometricEnabled();
    if (!biometricSettingEnabled) {
      // No biometric required → unlocked (PIN flow is handled by LockScreen when needed).
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
    if (_unlocked) _startInactivityTimer();
    notifyListeners();
  }

  void lock() {
    _unlocked = false;
    _cancelInactivityTimer();
    notifyListeners();
  }

  /// Mark app as unlocked (used after successful PIN/biometric via UI).
  void unlock() {
    _unlocked = true;
    _startInactivityTimer();
    notifyListeners();
  }

  /// Reset the inactivity timer (call on user interaction to keep app unlocked).
  void touch() {
    if (!_appLockEnabledCached) return;
    _startInactivityTimer();
  }

  /// Set the app lock enabled flag and persist via SettingsRepository.
  Future<void> setAppLockEnabled(bool enabled) async {
    await _settings.setAppLockEnabled(enabled);
    _appLockEnabledCached = enabled;
    if (!enabled) {
      // If disabling app lock, ensure app is unlocked.
      _unlocked = true;
      _cancelInactivityTimer();
    } else {
      // If enabling, lock immediately.
      _unlocked = false;
    }
    notifyListeners();
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    if (!_appLockEnabledCached) return;
    _inactivityTimer = Timer(_autoLockDuration, () {
      lock();
    });
  }

  void _cancelInactivityTimer() {
    try {
      _inactivityTimer?.cancel();
    } catch (_) {}
    _inactivityTimer = null;
  }
}

final authNotifierProvider = Provider<AuthNotifier>((ref) {
  final settings = ref.read(settingsRepositoryProvider);
  return AuthNotifier.withInit(settings);
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
  final settings = SettingsRepository();
  // Note: init() is called asynchronously in app startup before this provider is accessed
  return settings;
});

/// Provides the accounts repository instance
final accountsRepositoryProvider = Provider<AccountsRepository>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return AccountsRepository(dbHelper);
});

/// Provides the installment payments repository instance
final installmentPaymentsRepositoryProvider = Provider<InstallmentPaymentsRepository>((ref) {
  final dbHelper = ref.read(databaseHelperProvider);
  return InstallmentPaymentsRepository(dbHelper);
});

// Simple refresh trigger used across the app to request reloads.
final refreshTriggerProvider = StateProvider<int>((ref) => 0);

// Simple in-memory cache for report computations. Keys are arbitrary strings
// (e.g. 'spendingByCategory:2025-12'). Consumers should invalidate when
// underlying data changes (e.g. when loans/installments are modified).
final reportsCacheProvider = StateProvider<Map<String, dynamic>>((ref) => {});

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
