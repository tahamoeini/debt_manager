import 'package:flutter/material.dart';
import '../settings/settings_repository.dart';
import 'jalali_utils.dart';

// Shows a date picker and returns a [DateTime] (Gregorian) or [Jalali]
// depending on the user's calendar preference. For Jalali selection,
// this helper still uses the material picker (Gregorian) and converts
// the result to Jalali for compatibility with existing code.
Future<dynamic> showCalendarAwareDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final settings = SettingsRepository();

  // Show the picker immediately to avoid using `context` after an await.
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (picked == null) return null;
  await settings.init();
  if (settings.calendarType == CalendarType.jalali) {
    return dateTimeToJalali(picked);
  }
  return picked;
}
