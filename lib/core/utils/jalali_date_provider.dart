import 'package:shamsi_date/shamsi_date.dart';

/// Jalali-only date handling for Debt Manager.
/// All dates are stored as ISO strings in DB; displayed/input as Jalali.
/// This is the single source of truth for date formatting and parsing.

class JalaliDateProvider {
  /// Convert ISO DateTime string to Jalali date for display.
  static String formatJalaliFromISO(String isoString) {
    try {
      final dt = DateTime.parse(isoString);
      final jalali = Jalali.fromDateTime(dt);
      return formatFull(jalali);
    } catch (_) {
      return isoString; // Fallback if parsing fails
    }
  }

  /// Format a DateTime to ISO 8601 string (for DB storage).
  static String toISO(DateTime dateTime) {
    return dateTime.toIso8601String();
  }

  /// Format a Jalali date to ISO 8601 string (for DB storage).
  static String jalaliToISO(Jalali jalali) {
    return jalali.toDateTime().toIso8601String();
  }

  /// Parse a Jalali date string (e.g., "1403-12-22") to Jalali object.
  static Jalali parseJalali(String jalaliString) {
    try {
      // Support format: "1403-12-22" or similar
      final parts = jalaliString.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        return Jalali(year, month, day);
      }
    } catch (_) {}
    
    // Fallback: try to parse as ISO and convert
    try {
      final dt = DateTime.parse(jalaliString);
      return Jalali.fromDateTime(dt);
    } catch (_) {
      // Last resort: return today
      return Jalali.now();
    }
  }

  /// Get today's date in Jalali, as ISO string.
  static String todayISO() {
    final now = DateTime.now();
    return toISO(now);
  }

  /// Get today's date in Jalali.
  static Jalali today() {
    return Jalali.now();
  }

  /// Format Jalali date as short display string (e.g. "۱۴۰۳/۱۲/۲۲").
  static String formatShort(Jalali jalali) {
    return '${jalali.year}/${jalali.month.toString().padLeft(2, '۰')}/${jalali.day.toString().padLeft(2, '۰')}';
  }

  /// Format Jalali date as long display string (e.g. "۲۲ اسفند ۱۴۰۳").
  static String formatFull(Jalali jalali) {
    const monthNames = [
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    final monthName = monthNames[jalali.month - 1];
    return '${_persianNumber(jalali.day)} $monthName ${_persianNumber(jalali.year)}';
  }

  /// Convert digits to Persian numerals.
  static String _persianNumber(int num) {
    const englishDigits = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const persianDigits = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    String result = num.toString();
    for (int i = 0; i < englishDigits.length; i++) {
      result = result.replaceAll(englishDigits[i], persianDigits[i]);
    }
    return result;
  }

  /// Difference in days between two Jalali dates.
  static int daysBetween(Jalali from, Jalali to) {
    return to.toDateTime().difference(from.toDateTime()).inDays;
  }

  /// Add days to a Jalali date.
  static Jalali addDays(Jalali date, int days) {
    final newDateTime = date.toDateTime().add(Duration(days: days));
    return Jalali.fromDateTime(newDateTime);
  }

  /// Get the last day of a Jalali month.
  static int lastDayOfMonth(int year, int month) {
    if (month < 7) {
      return 31;
    } else if (month < 12) {
      return 30;
    } else {
      // Esfand: 29 or 30 depending on leap year
      return Jalali(year, 12, 1).monthLength;
    }
  }
}
