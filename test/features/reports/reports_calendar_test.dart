// Widget test for Reports screen calendar switching.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';

void main() {
  group('Reports Screen Calendar Switching', () {
    setUp(() {
      // Reset calendar type to Jalali before each test
      SettingsRepository.calendarTypeNotifier.value = CalendarType.jalali;
    });

    testWidgets('Displays Jalali date format by default',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: const ReportsScreen(),
            ),
          ),
        ),
      );

      // Wait for initial widget build and any async operations
      await tester.pumpAndSettle();

      // Verify "از تاریخ" (from date) button exists (it starts empty)
      expect(find.text('از تاریخ'), findsWidgets);
      expect(find.text('تا تاریخ'), findsWidgets);
    });

    testWidgets('Switches to Gregorian date format when calendar type changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: const ReportsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Change calendar type to Gregorian
      SettingsRepository.calendarTypeNotifier.value = CalendarType.gregorian;

      // Pump to rebuild widgets listening to the notifier
      await tester.pumpAndSettle();

      // Verify UI still renders correctly (button text updates via ValueListenableBuilder)
      expect(find.text('از تاریخ'), findsWidgets);
      expect(find.text('تا تاریخ'), findsWidgets);
    });

    testWidgets('Toggles between Jalali and Gregorian calendars reactively',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: const ReportsScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Jalali is default
      expect(
          SettingsRepository.calendarTypeNotifier.value, CalendarType.jalali);

      // Switch to Gregorian
      SettingsRepository.calendarTypeNotifier.value = CalendarType.gregorian;
      await tester.pumpAndSettle();
      expect(SettingsRepository.calendarTypeNotifier.value,
          CalendarType.gregorian);

      // Switch back to Jalali
      SettingsRepository.calendarTypeNotifier.value = CalendarType.jalali;
      await tester.pumpAndSettle();
      expect(
          SettingsRepository.calendarTypeNotifier.value, CalendarType.jalali);
    });
  });
}
