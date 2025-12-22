import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/utils/calendar_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';

void main() {
  group('Calendar utils formatting', () {
    test('formatDateForDisplayWithCalendar returns Gregorian string', () {
      final dt = DateTime(2025, 12, 22);
      final s = formatDateForDisplayWithCalendar(dt, CalendarType.gregorian);
      expect(s, '22 Dec 2025');
    });

    test('formatDateForDisplayWithCalendar returns Jalali string', () {
      final dt = DateTime(2025, 12, 22);
      final expected = formatJalaliForDisplay(dateTimeToJalali(dt));
      final s = formatDateForDisplayWithCalendar(dt, CalendarType.jalali);
      expect(s, expected);
    });
  });

  testWidgets('Widget updates when calendar type changes', (tester) async {
    final fixedDate = DateTime(2025, 12, 22);

    Widget build() {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: ValueListenableBuilder<CalendarType>(
          valueListenable: SettingsRepository.calendarTypeNotifier,
          builder: (context, calType, _) {
            return Text(formatDateForDisplayWithCalendar(fixedDate, calType),
                textDirection: TextDirection.ltr);
          },
        ),
      );
    }

    // Start with Jalali
    SettingsRepository.calendarTypeNotifier.value = CalendarType.jalali;
    await tester.pumpWidget(build());
    final jalaliText = formatJalaliForDisplay(dateTimeToJalali(fixedDate));
    expect(find.text(jalaliText), findsOneWidget);

    // Switch to Gregorian and re-pump
    SettingsRepository.calendarTypeNotifier.value = CalendarType.gregorian;
    await tester.pump();
    expect(find.text('22 Dec 2025'), findsOneWidget);
  });
}
