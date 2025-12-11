// Settings repository: stores and retrieves simple user settings.
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum FontSizeOption { small, defaultSize, large }

enum CalendarType { gregorian, jalali }

enum LanguageOption { english, persian }

class SettingsRepository {
  // Keys
  static const _keyReminderOffsetDays = 'reminder_offset_days';
  static const _keyThemeMode = 'theme_mode';
  static const _keyFontSize = 'font_size';
  static const _keyCalendarType = 'calendar_type';
  static const _keyLanguage = 'language';
  static const _keyNotificationsEnabled = 'notifications_enabled';
  static const _keyBillReminders = 'bill_reminders_enabled';
  static const _keyBudgetAlerts = 'budget_alerts_enabled';
  static const _keySmartSuggestionsEnabled = 'smart_suggestions_enabled';
  static const _keyFinanceCoachEnabled = 'finance_coach_enabled';
  static const _keyMonthEndSummaryEnabled = 'month_end_summary_enabled';
  static const _keyBiometricEnabled = 'biometric_enabled';
  static const _keyBudgetThreshold90 = 'budget_threshold_90';
  static const _keyBudgetThreshold100 = 'budget_threshold_100';
  static const _keyOnboardingComplete = 'onboarding_complete';

  // Public (synchronous) fields used by callers in this codebase.
  // These are populated by calling `init()` at app startup or prior to use.
  bool remindersEnabled = true;
  bool billRemindersEnabled = true;
  bool budgetAlertsEnabled = true;
  bool smartSuggestionsEnabled = true;
  bool financeCoachEnabled = true;
  bool monthEndSummaryEnabled = true;
  bool biometricEnabled = false;

  int reminderOffsetDays = 3;
  ThemeMode themeMode = ThemeMode.system;
  FontSizeOption fontSize = FontSizeOption.defaultSize;
  CalendarType calendarType = CalendarType.jalali;
  LanguageOption language = LanguageOption.persian;

  // Notifiers for reactive UI
  static final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);
  static final ValueNotifier<FontSizeOption> fontSizeNotifier =
      ValueNotifier(FontSizeOption.defaultSize);
  static final ValueNotifier<CalendarType> calendarTypeNotifier =
      ValueNotifier(CalendarType.jalali);
  static final ValueNotifier<LanguageOption> languageNotifier =
      ValueNotifier(LanguageOption.persian);
  static final ValueNotifier<bool> biometricEnabledNotifier =
      ValueNotifier(false);

  // Initialize repository and populate public fields from SharedPreferences.
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    reminderOffsetDays = prefs.getInt(_keyReminderOffsetDays) ?? 3;
    final tm = prefs.getString(_keyThemeMode) ?? 'system';
    themeMode = tm == 'light'
        ? ThemeMode.light
        : tm == 'dark'
            ? ThemeMode.dark
            : ThemeMode.system;
    themeModeNotifier.value = themeMode;

    final fs = prefs.getString(_keyFontSize) ?? 'default';
    fontSize = fs == 'small'
        ? FontSizeOption.small
        : fs == 'large'
            ? FontSizeOption.large
            : FontSizeOption.defaultSize;
    fontSizeNotifier.value = fontSize;

    final ct = prefs.getString(_keyCalendarType) ?? 'jalali';
    calendarType =
        ct == 'gregorian' ? CalendarType.gregorian : CalendarType.jalali;
    calendarTypeNotifier.value = calendarType;

    final lang = prefs.getString(_keyLanguage) ?? 'persian';
    language =
        lang == 'english' ? LanguageOption.english : LanguageOption.persian;
    languageNotifier.value = language;

    remindersEnabled = prefs.getBool(_keyNotificationsEnabled) ?? true;
    billRemindersEnabled = prefs.getBool(_keyBillReminders) ?? true;
    budgetAlertsEnabled = prefs.getBool(_keyBudgetAlerts) ?? true;
    smartSuggestionsEnabled =
        prefs.getBool(_keySmartSuggestionsEnabled) ?? true;
    financeCoachEnabled = prefs.getBool(_keyFinanceCoachEnabled) ?? true;
    monthEndSummaryEnabled = prefs.getBool(_keyMonthEndSummaryEnabled) ?? true;
    biometricEnabled = prefs.getBool(_keyBiometricEnabled) ?? false;
    biometricEnabledNotifier.value = biometricEnabled;
  }

  // Backward-compatible async getters/setters used throughout code.
  Future<int> getReminderOffsetDays() async => reminderOffsetDays;
  Future<void> setReminderOffsetDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderOffsetDays, days);
    reminderOffsetDays = days;
  }

  Future<ThemeMode> getThemeMode() async => themeMode;
  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final s = mode == ThemeMode.light
        ? 'light'
        : mode == ThemeMode.dark
            ? 'dark'
            : 'system';
    await prefs.setString(_keyThemeMode, s);
    themeMode = mode;
    themeModeNotifier.value = mode;
  }

  Future<FontSizeOption> getFontSize() async => fontSize;
  Future<void> setFontSize(FontSizeOption size) async {
    final prefs = await SharedPreferences.getInstance();
    final s = size == FontSizeOption.small
        ? 'small'
        : size == FontSizeOption.large
            ? 'large'
            : 'default';
    await prefs.setString(_keyFontSize, s);
    fontSize = size;
    fontSizeNotifier.value = size;
  }

  Future<CalendarType> getCalendarType() async => calendarType;
  Future<void> setCalendarType(CalendarType type) async {
    final prefs = await SharedPreferences.getInstance();
    final s = type == CalendarType.gregorian ? 'gregorian' : 'jalali';
    await prefs.setString(_keyCalendarType, s);
    calendarType = type;
    calendarTypeNotifier.value = type;
  }

  Future<LanguageOption> getLanguage() async => language;
  Future<void> setLanguage(LanguageOption lang) async {
    final prefs = await SharedPreferences.getInstance();
    final s = lang == LanguageOption.english ? 'english' : 'persian';
    await prefs.setString(_keyLanguage, s);
    language = lang;
    languageNotifier.value = lang;
  }

  Future<bool> getNotificationsEnabled() async => remindersEnabled;
  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyNotificationsEnabled, enabled);
    remindersEnabled = enabled;
  }

  Future<bool> getBillRemindersEnabled() async => billRemindersEnabled;
  Future<void> setBillRemindersEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBillReminders, enabled);
    billRemindersEnabled = enabled;
  }

  Future<bool> getBudgetAlertsEnabled() async => budgetAlertsEnabled;
  Future<void> setBudgetAlertsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBudgetAlerts, enabled);
    budgetAlertsEnabled = enabled;
  }

  Future<bool> getSmartSuggestionsEnabled() async => smartSuggestionsEnabled;
  Future<void> setSmartSuggestionsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySmartSuggestionsEnabled, enabled);
    smartSuggestionsEnabled = enabled;
  }

  // Alias to match previous API
  bool get smartInsightsEnabled => smartSuggestionsEnabled;

  // Backwards-compatible getter expected by older code
  bool get monthlySummaryEnabled => monthEndSummaryEnabled;

  Future<bool> getFinanceCoachEnabled() async => financeCoachEnabled;
  Future<void> setFinanceCoachEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFinanceCoachEnabled, enabled);
    financeCoachEnabled = enabled;
  }

  Future<bool> getMonthEndSummaryEnabled() async => monthEndSummaryEnabled;
  Future<void> setMonthEndSummaryEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMonthEndSummaryEnabled, enabled);
    monthEndSummaryEnabled = enabled;
  }

  Future<bool> getBiometricEnabled() async => biometricEnabled;
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
    biometricEnabled = enabled;
    biometricEnabledNotifier.value = enabled;
  }

  // Compatibility helpers expected by older code
  double getFontScale(FontSizeOption size) {
    switch (size) {
      case FontSizeOption.small:
        return 0.85;
      case FontSizeOption.large:
        return 1.15;
      case FontSizeOption.defaultSize:
        return 1.0;
    }
  }

  String get languageCode => language == LanguageOption.english ? 'en' : 'fa';

  Future<void> setLanguageCode(String code) async {
    final lc = (code.toLowerCase() == 'en' || code.toLowerCase() == 'english')
        ? LanguageOption.english
        : LanguageOption.persian;
    await setLanguage(lc);
  }

  // Backwards-compatible names
  Future<void> setRemindersEnabled(bool v) => setNotificationsEnabled(v);
  Future<void> setMonthlySummaryEnabled(bool v) => setMonthEndSummaryEnabled(v);
  Future<void> setSmartInsightsEnabled(bool v) => setSmartSuggestionsEnabled(v);

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

  Future<void> setOnboardingComplete(bool complete) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, complete);
  }

  Future<void> replayOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingComplete, false);
  }
}
