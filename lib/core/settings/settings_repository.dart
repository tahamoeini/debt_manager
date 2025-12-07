// Settings repository: stores and retrieves simple user settings.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, defaultSize, large }

enum CalendarType { gregorian, jalali }

enum LanguageOption { english, persian }

class SettingsRepository {
  static const _keyReminderOffsetDays = 'reminder_offset_days';
  static const _keyThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'
  static const _keyFontSize = 'font_size'; // 'small' | 'default' | 'large'
  static const _keyCalendarType = 'calendar_type'; // 'gregorian' | 'jalali'
  static const _keyLanguage = 'language'; // 'english' | 'persian'
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyBillReminders = 'bill_reminders_enabled';
  static const _keyBudgetAlerts = 'budget_alerts_enabled';
  static const _keyBudgetAlertsEnabled = 'budget_alerts_enabled';
  static const _keyBudgetThreshold90 = 'budget_threshold_90';
  static const _keyBudgetThreshold100 = 'budget_threshold_100';
  static const _keySmartSuggestionsEnabled = 'smart_suggestions_enabled';
  static const _keyFinanceCoachEnabled = 'finance_coach_enabled';
  static const _keyMonthEndSummaryEnabled = 'month_end_summary_enabled';

  // A notifier to broadcast theme mode changes across the app.
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);
  
  // A notifier to broadcast font size changes across the app.
  static final ValueNotifier<FontSizeOption> fontSizeNotifier =
      ValueNotifier(FontSizeOption.defaultSize);
  
  // A notifier to broadcast calendar type changes across the app.
  static final ValueNotifier<CalendarType> calendarTypeNotifier =
      ValueNotifier(CalendarType.jalali);
  
  // A notifier to broadcast language changes across the app.
  static final ValueNotifier<LanguageOption> languageNotifier =
      ValueNotifier(LanguageOption.persian);

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

  Future<FontSizeOption> getFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyFontSize) ?? 'default';
    switch (v) {
      case 'small':
        return FontSizeOption.small;
      case 'large':
        return FontSizeOption.large;
      default:
        return FontSizeOption.defaultSize;
    }
  }

  Future<void> setFontSize(FontSizeOption size) async {
    final prefs = await SharedPreferences.getInstance();
    final s = size == FontSizeOption.small
        ? 'small'
        : size == FontSizeOption.large
            ? 'large'
            : 'default';
    await prefs.setString(_keyFontSize, s);
    fontSizeNotifier.value = size;
  }

  Future<CalendarType> getCalendarType() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyCalendarType) ?? 'jalali';
    return v == 'gregorian' ? CalendarType.gregorian : CalendarType.jalali;
  }

  Future<void> setCalendarType(CalendarType type) async {
    final prefs = await SharedPreferences.getInstance();
    final s = type == CalendarType.gregorian ? 'gregorian' : 'jalali';
    await prefs.setString(_keyCalendarType, s);
    calendarTypeNotifier.value = type;
  }

  Future<LanguageOption> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_keyLanguage) ?? 'persian';
    return v == 'english' ? LanguageOption.english : LanguageOption.persian;
  }

  Future<void> setLanguage(LanguageOption language) async {
    final prefs = await SharedPreferences.getInstance();
    final s = language == LanguageOption.english ? 'english' : 'persian';
    await prefs.setString(_keyLanguage, s);
    languageNotifier.value = language;
  }

  Future<bool> getNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyNotificationsEnabled) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<bool> getBillRemindersEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBillReminders) ?? true;
  }

  Future<void> setBillRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBillReminders, enabled);
  }

  Future<bool> getBudgetAlertsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBudgetAlerts) ?? true;
  }

  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlerts, enabled);
  }

  double getFontScale(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.large:
        return 1.15;
      case FontSizeOption.defaultSize:
      default:
        return 1.0;
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
