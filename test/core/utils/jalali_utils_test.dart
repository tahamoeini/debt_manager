import 'package:flutter_test/flutter_test.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';

void main() {
  test('Jalali schedule clamps end-of-month across 31->30 boundary', () {
    final start = Jalali(1402, 6, 31); // Shahrivar has 31
    final s = generateMonthlySchedule(start, 2);
    expect(s[0], start);
    // Mehr has 30 days
    expect(s[1], Jalali(1402, 7, 30));
  });

  test('Jalali schedule keeps day when month supports it', () {
    final start = Jalali(1402, 2, 15);
    final s = generateMonthlySchedule(start, 3);
    expect(s, [Jalali(1402, 2, 15), Jalali(1402, 3, 15), Jalali(1402, 4, 15)]);
  });

  group('Jalali monthly schedule edge cases', () {
    test('start 1403/12/30 + 1 month → 1404/01/30', () {
      // Esfand (month 12) in a non-leap year has 29 days, but in leap year has 30
      // 1403 is not a leap year in Jalali
      // So Esfand 1403 has 29 days max
      final start = Jalali(1403, 12, 29); // Last day of Esfand 1403
      final s = generateMonthlySchedule(start, 2);
      expect(s[0], Jalali(1403, 12, 29));
      // Next month is Farvardin 1404, which has 31 days
      expect(s[1], Jalali(1404, 1, 29)); // Keeps day 29
    });

    test('leap-year Esfand behavior: day 30 carries to next month', () {
      // 1399 is a Jalali leap year (Esfand has 30 days)
      final start = Jalali(1399, 12, 30); // Last day of leap year Esfand
      final s = generateMonthlySchedule(start, 2);
      expect(s[0], Jalali(1399, 12, 30));
      // Next month is Farvardin 1400, which has 31 days
      expect(s[1], Jalali(1400, 1, 30)); // Keeps day 30
    });

    test('end-of-month drift: 31 → 30 → 29 → 31 cycle', () {
      // Start at day 31 (Shahrivar)
      final start = Jalali(1402, 6, 31); // 31 days
      final s = generateMonthlySchedule(start, 4);
      expect(s[0], Jalali(1402, 6, 31)); // Shahrivar: 31 days
      expect(s[1], Jalali(1402, 7, 30)); // Mehr: 30 days (clamped)
      expect(s[2], Jalali(1402, 8, 30)); // Aban: 30 days (kept from clamp)
      expect(s[3], Jalali(1402, 9, 30)); // Azar: 30 days (keeps clamped day)
    });

    test('year-end wrap-around maintains day', () {
      final start = Jalali(1402, 11, 15); // Bahman 15
      final s = generateMonthlySchedule(start, 3);
      expect(s[0], Jalali(1402, 11, 15)); // Bahman: 30 days
      expect(
          s[1], Jalali(1402, 12, 15)); // Esfand (non-leap): 29 days, day kept
      expect(s[2], Jalali(1403, 1, 15)); // Farvardin 1403: 31 days
    });

    test('parseJalali and formatJalali round-trip', () {
      const dateStr = '1403-09-15';
      final parsed = parseJalali(dateStr);
      expect(parsed, Jalali(1403, 9, 15));
      expect(formatJalali(parsed), dateStr);
    });

    test('formatJalaliForDisplay produces correct format', () {
      final date = Jalali(1403, 9, 5);
      expect(formatJalaliForDisplay(date), '1403/09/05');
    });

    test('Jalali month lengths vary by month', () {
      // Months 1-6: 31 days each
      for (var m = 1; m <= 6; m++) {
        expect(Jalali(1403, m, 1).monthLength, 31,
            reason: 'Months 1-6 should have 31 days');
      }
      // Months 7-11: 30 days each
      for (var m = 7; m <= 11; m++) {
        expect(Jalali(1403, m, 1).monthLength, 30,
            reason: 'Months 7-11 should have 30 days');
      }
      // Month 12 (Esfand): 29 or 30 days depending on leap year
      // 1403 is a leap year so Esfand has 30 days
      expect(Jalali(1403, 12, 1).monthLength, 30,
          reason: 'Esfand in leap year 1403 should have 30 days');
      // 1399 is also a leap year
      expect(Jalali(1399, 12, 1).monthLength, 30,
          reason: 'Esfand in leap year 1399 should have 30 days');
    });

    test('schedules with zero count return empty list', () {
      final start = Jalali(1403, 9, 15);
      expect(generateMonthlySchedule(start, 0), isEmpty);
    });

    test('single-element schedule returns only start date', () {
      final start = Jalali(1403, 9, 15);
      final s = generateMonthlySchedule(start, 1);
      expect(s, [start]);
    });

    test('large schedule across multiple years', () {
      final start = Jalali(1402, 11, 15);
      final s = generateMonthlySchedule(start, 14); // Over a year
      expect(s.length, 14);
      expect(s.first, Jalali(1402, 11, 15));
      expect(s.last, Jalali(1403, 12, 15)); // Should wrap to next year
    });
  });
}
