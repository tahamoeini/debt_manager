// Jalali date utilities: parse/format and schedule helpers for Jalali dates.
import 'package:shamsi_date/shamsi_date.dart';

// Parse a Jalali date string in the format `yyyy-MM-dd` into a [Jalali].
Jalali parseJalali(String value) {
  final parts = value.split('-');
  if (parts.length != 3) {
    throw const FormatException(
      'Invalid Jalali date format, expected yyyy-MM-dd',
    );
  }
  final year = int.parse(parts[0]);
  final month = int.parse(parts[1]);
  final day = int.parse(parts[2]);
  return Jalali(year, month, day);
}

// Format a [Jalali] date as `yyyy-MM-dd` string.
String formatJalali(Jalali date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

// Format a [Jalali] date for display in a simple Farsi-friendly form.
// Example: `1403/09/15`.
String formatJalaliForDisplay(Jalali date) {
  final y = date.year.toString();
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y/$m/$d';
}

// Generate a monthly schedule of [count] Jalali dates starting from [startDate].
// Rule: keep the same day-of-month when possible; otherwise clamp to monthLength.
// The returned list includes [startDate] as the first element.
List<Jalali> generateMonthlySchedule(Jalali startDate, int count) {
  if (count <= 0) return const <Jalali>[];

  final out = <Jalali>[];
  final startDay = startDate.day;

  for (var i = 0; i < count; i++) {
    final monthIndex = (startDate.month - 1) + i;
    final y = startDate.year + (monthIndex ~/ 12);
    final m = (monthIndex % 12) + 1;
    final monthLen = Jalali(y, m, 1).monthLength;
    final d = startDay <= monthLen ? startDay : monthLen;
    out.add(Jalali(y, m, d));
  }
  return out;
}

// Convert a [Jalali] to a [DateTime] using the Gregorian equivalent.
DateTime jalaliToDateTime(Jalali date) => date.toDateTime();

// Convert a [DateTime] (Gregorian) to a [Jalali].
Jalali dateTimeToJalali(DateTime dt) => Jalali.fromDateTime(dt);
