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
}
