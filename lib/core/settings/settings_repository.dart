import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const _keyReminderOffsetDays = 'reminder_offset_days';

  Future<int> getReminderOffsetDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyReminderOffsetDays) ?? 3;
  }

  Future<void> setReminderOffsetDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReminderOffsetDays, days);
  }
}
