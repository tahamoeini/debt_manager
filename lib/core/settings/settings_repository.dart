// Settings repository: stores and retrieves simple user settings.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyReminderOffsetDays = 'reminder_offset_days';
  static const _keyThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _keyBudgetAlertsEnabled = 'budget_alerts_enabled';
  static const _keyBudgetThreshold90 = 'budget_threshold_90';
  static const _keyBudgetThreshold100 = 'budget_threshold_100';
  static const _keySmartSuggestionsEnabled = 'smart_suggestions_enabled';
  static const _keyFinanceCoachEnabled = 'finance_coach_enabled';
  static const _keyMonthEndSummaryEnabled = 'month_end_summary_enabled';

  // A notifier to broadcast theme mode changes across the app.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  Future<int> getReminderOffsetDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderOffsetDays) ?? 3;
  }

  Future<void> setReminderOffsetDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderOffsetDays, days);
  }

  Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyThemeMode) ?? 'system';
    switch (v) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final s = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_keyThemeMode, s);
    themeModeNotifier.value = mode;
  }

  // Budget alerts settings
  Future<bool> getBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlertsEnabled) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlertsEnabled, enabled);
  }

  Future<bool> getBudgetThreshold90Enabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetThreshold90) ?? true;
  }

  Future<void> setBudgetThreshold90Enabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetThreshold90, enabled);
  }

  Future<bool> getBudgetThreshold100Enabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetThreshold100) ?? true;
  }

  Future<void> setBudgetThreshold100Enabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetThreshold100, enabled);
  }

  // Smart suggestions settings
  Future<bool> getSmartSuggestionsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keySmartSuggestionsEnabled) ?? true;
  }

  Future<void> setSmartSuggestionsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartSuggestionsEnabled, enabled);
  }

  Future<bool> getFinanceCoachEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyFinanceCoachEnabled) ?? true;
  }

  Future<void> setFinanceCoachEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFinanceCoachEnabled, enabled);
  }

  Future<bool> getMonthEndSummaryEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyMonthEndSummaryEnabled) ?? true;
  }

  Future<void> setMonthEndSummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonthEndSummaryEnabled, enabled);
  }
}
