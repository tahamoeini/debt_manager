import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/loans/screens/home_screen.dart';
import 'package:debt_manager/features/home/home_statistics_notifier.dart';

void main() {
  testWidgets('Home shows net worth and monthly cashflow cards',
      (tester) async {
    final stub = HomeStats(
      borrowed: 1000,
      lent: 500,
      net: -500,
      netWorth: 250000,
      monthlySpending: 20000,
      monthlyCashflow: 40000,
      spendingTrend: [10000, 15000, 20000, 18000, 22000, 20000],
      upcoming: const [],
      loansById: {},
      counterpartiesById: {},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeStatisticsProvider.overrideWith((ref) => stub),
        ],
        child: const MaterialApp(home: Scaffold(body: HomeScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('دارایی خالص'), findsOneWidget);
    expect(find.text('جریان نقدی ماهانه'), findsOneWidget);
    expect(find.text('سلامت بودجه'), findsOneWidget);
  });
}
