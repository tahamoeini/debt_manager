// Calendar-aware date conversion utilities for Gregorian/Jalali calendar support.
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// Convert DateTime to calendar-aware string (Gregorian or Jalali based on setting).
String formatDateForCalendar(
  DateTime dt,
  CalendarType calendarType,
) {
  if (calendarType == CalendarType.jalali) {
    final j = dateTimeToJalali(dt);
    return formatJalali(j);
  } else {
    return dt.toIso8601String().split('T').first;
  }
}

/// Format DateTime for display in UI (Gregorian or Jalali).
String formatDateForDisplayWithCalendar(
  DateTime dt,
  CalendarType calendarType,
) {
  if (calendarType == CalendarType.jalali) {
    final j = dateTimeToJalali(dt);
    return formatJalaliForDisplay(j);
  } else {
    // Gregorian: e.g., "2025-12-22" → "22 Dec 2025"
    return '${dt.day} ${_monthNameEnglish(dt.month)} ${dt.year}';
  }
}

String _monthNameEnglish(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec'
  ];
  return months[month - 1];
}

/// Parse a Gregorian date string (yyyy-MM-dd) into DateTime.
DateTime parseGregorianString(String value) {
  return DateTime.parse(value);
}

/// Get current date in the specified calendar as a formatted string.
String getCurrentDateForCalendar(CalendarType calendarType) {
  return formatDateForCalendar(DateTime.now(), calendarType);
}

/// Check if a date string (in specified calendar) falls within a range.
/// Both dateStr, fromStr, and toStr should be in yyyy-MM-dd format.
bool isDateInRange(
  String dateStr,
  String? fromStr,
  String? toStr,
  CalendarType calendarType,
) {
  if (calendarType == CalendarType.jalali) {
    // Jalali dates can be compared lexicographically as yyyy-MM-dd
    if (fromStr != null && dateStr.compareTo(fromStr) < 0) return false;
    if (toStr != null && dateStr.compareTo(toStr) > 0) return false;
    return true;
  } else {
    // Gregorian: also yyyy-MM-dd lexicographic comparison
    if (fromStr != null && dateStr.compareTo(fromStr) < 0) return false;
    if (toStr != null && dateStr.compareTo(toStr) > 0) return false;
    return true;
  }
}

/// Convert DateTime to Jalali date (internal utility for compatibility).
Jalali dateTimeToJalaliHelper(DateTime dt) {
  return dateTimeToJalali(dt);
}
