// Settings repository: stores and retrieves simple user settings.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyReminderOffsetDays = 'reminder_offset_days';
  static const _keyThemeMode = 'theme_mode'; // 'system' | 'light' | 'dark'

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
}
