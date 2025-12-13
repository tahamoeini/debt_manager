import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/compute/cash_flow_simulator.dart';

void main() {
  group('CashFlowSimulator', () {
    test('simulateCashFlow produces correct number of snapshots', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 100000,
        newRecurringFrequency: 'monthly',
        simulationDays: 30,
        avgDailyIncome: 50000,
        avgMonthlyExpenses: 800000,
      );

      final snapshots = simulateCashFlow(input);

      expect(snapshots.length, equals(30));
      expect(snapshots.first.openingBalance, greaterThan(0));
    });

    test('analyzeCashFlow detects negative cash', () {
      final snapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 100000,
          income: 50000,
          expenses: 200000,
          debtPayments: 0,
          closingBalance: -50000,
          isNegative: true,
        ),
      ];

      final result = analyzeCashFlow(snapshots);

      expect(result.hasNegativeCash, isTrue);
      expect(result.minBalance, equals(-50000));
      expect(result.daysUntilNegative, equals(0));
    });

    test('analyzeCashFlow computes correct safety level - safe', () {
      final snapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 5000000,
          income: 100000,
          expenses: 50000,
          debtPayments: 0,
          closingBalance: 5050000,
        ),
      ];

      final result = analyzeCashFlow(snapshots);

      expect(result.safetyLevel, equals('safe'));
    });

    test('analyzeCashFlow computes correct safety level - tight', () {
      final snapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 500000,
          income: 100000,
          expenses: 90000,
          debtPayments: 0,
          closingBalance: 510000,
        ),
      ];

      final result = analyzeCashFlow(snapshots);

      expect(result.safetyLevel, equals('tight'));
    });

    test('analyzeCashFlow recommendation for safe level', () {
      final snapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 5000000,
          income: 100000,
          expenses: 50000,
          debtPayments: 0,
          closingBalance: 5050000,
        ),
      ];

      final result = analyzeCashFlow(snapshots);

      expect(result.recommendation, contains('comfortably'));
    });

    test('simulateCashFlow accounts for daily recurring costs', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 10000,
        newRecurringFrequency: 'daily',
        simulationDays: 5,
        avgDailyIncome: 50000,
        avgMonthlyExpenses: 0,
      );

      final snapshots = simulateCashFlow(input);

      // Each day should subtract the recurring amount
      for (var i = 0; i < snapshots.length; i++) {
        final snap = snapshots[i];
        expect(snap.expenses, greaterThanOrEqualTo(10000));
      }
    });

    test('simulateCashFlow respects monthly frequency', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 100000,
        newRecurringFrequency: 'monthly',
        simulationDays: 90,
        avgDailyIncome: 50000,
        avgMonthlyExpenses: 0,
      );

      final snapshots = simulateCashFlow(input);

      // Only on day matching current day should recurring apply
      int recurringDays = 0;
      for (final snap in snapshots) {
        if (snap.expenses >= 100000) {
          recurringDays++;
        }
      }
      expect(recurringDays, lessThanOrEqualTo(3)); // ~3 months in 90 days
    });

    test('DailyCashSnapshot.toMap returns valid map', () {
      final snap = DailyCashSnapshot(
        date: DateTime(2025, 1, 1),
        dateJalaliString: '1403-10-11',
        openingBalance: 100000,
        income: 50000,
        expenses: 30000,
        debtPayments: 10000,
        closingBalance: 110000,
      );

      final map = snap.toMap();

      expect(map['dateJalali'], equals('1403-10-11'));
      expect(map['closingBalance'], equals(110000));
      expect(map.containsKey('date'), isTrue);
    });
  });
}
