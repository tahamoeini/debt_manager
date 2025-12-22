import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'jalali_date_provider.dart';

/// Jalali-only date picker. Always returns Jalali date.
/// This is the single global date picker for the app.
Future<Jalali?> showJalaliDatePicker(
  BuildContext context, {
  required Jalali initialDate,
  required Jalali firstDate,
  required Jalali lastDate,
}) async {
  // Convert to Gregorian for the native picker, then convert back to Jalali.
  final gregorianInitial = initialDate.toDateTime();
  final gregorianFirst = firstDate.toDateTime();
  final gregorianLast = lastDate.toDateTime();

  final picked = await showDatePicker(
    context: context,
    initialDate: gregorianInitial,
    firstDate: gregorianFirst,
    lastDate: gregorianLast,
  );

  if (picked == null) return null;

  return Jalali.fromDateTime(picked);
}

/// Format a Jalali date as a string for display in forms.
String formatJalaliForForm(Jalali date) {
  return JalaliDateProvider.formatShort(date);
}
