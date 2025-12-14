import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/compute/cash_flow_simulator.dart';

void main() {
  group('CashFlowSimulator - Edge Cases', () {
    test('simulateCashFlow with zero starting balance', () {
      final input = CashFlowInput(
        startingBalance: 0,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 100000,
        newRecurringFrequency: 'monthly',
        simulationDays: 30,
        avgDailyIncome: 100000,
        avgMonthlyExpenses: 50000,
      );

      final snapshots = simulateCashFlow(input);

      expect(snapshots.length, equals(30));
      // Should gradually improve due to income exceeding expenses
      expect(
        snapshots.last.closingBalance,
        greaterThan(snapshots.first.openingBalance),
      );
    });

    test('simulateCashFlow with negative starting balance', () {
      final input = CashFlowInput(
        startingBalance: -500000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 0,
        newRecurringFrequency: 'monthly',
        simulationDays: 30,
        avgDailyIncome: 100000,
        avgMonthlyExpenses: 0,
      );

      final snapshots = simulateCashFlow(input);

      // Should eventually become positive due to daily income
      final lastSnapshot = snapshots.last;
      expect(lastSnapshot.closingBalance, greaterThan(-500000));
    });

    test('simulateCashFlow with very high expenses', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 0,
        newRecurringFrequency: 'monthly',
        simulationDays: 30,
        avgDailyIncome: 10000,
        avgMonthlyExpenses: 5000000,
      );

      final snapshots = simulateCashFlow(input);

      // Should go negative
      expect(snapshots.any((s) => s.closingBalance < 0), isTrue);
    });

    test('analyzeCashFlow with all positive snapshots', () {
      final snapshots = List.generate(
        30,
        (i) => DailyCashSnapshot(
          date: DateTime.now().add(Duration(days: i)),
          dateJalaliString: '1403-09-${(i + 1).toString().padLeft(2, '0')}',
          openingBalance: 1000000 + (i * 50000),
          income: 100000,
          expenses: 50000,
          debtPayments: 0,
          closingBalance: 1000000 + ((i + 1) * 50000),
        ),
      );

      final result = analyzeCashFlow(snapshots);

      expect(result.safetyLevel, equals('safe'));
      expect(result.hasNegativeCash, isFalse);
      expect(result.daysUntilNegative, lessThan(0)); // No negative day
    });

    test('analyzeCashFlow with minimal balance (tight)', () {
      final snapshots = List.generate(
        30,
        (i) => DailyCashSnapshot(
          date: DateTime.now().add(Duration(days: i)),
          dateJalaliString: '1403-09-${(i + 1).toString().padLeft(2, '0')}',
          openingBalance: 100000,
          income: 100000,
          expenses: 99000,
          debtPayments: 0,
          closingBalance: 101000,
        ),
      );

      final result = analyzeCashFlow(snapshots);

      expect(result.safetyLevel, equals('tight'));
    });

    test('analyzeCashFlow handles empty list gracefully', () {
      final snapshots = <DailyCashSnapshot>[];

      final result = analyzeCashFlow(snapshots);

      expect(result.minBalance, equals(0));
      expect(result.maxBalance, equals(0));
    });

    test('DailyCashSnapshot with default isNegative flag', () {
      final snap1 = DailyCashSnapshot(
        date: DateTime(2025, 1, 1),
        dateJalaliString: '1403-10-11',
        openingBalance: 100000,
        income: 50000,
        expenses: 30000,
        debtPayments: 10000,
        closingBalance: 110000,
      );

      expect(snap1.isNegative, isFalse);

      final snap2 = DailyCashSnapshot(
        date: DateTime(2025, 1, 1),
        dateJalaliString: '1403-10-11',
        openingBalance: 100000,
        income: 0,
        expenses: 200000,
        debtPayments: 0,
        closingBalance: -100000,
        isNegative: true,
      );

      expect(snap2.isNegative, isTrue);
    });

    test('CashFlowInput with mixed frequency', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 50000,
        newRecurringFrequency: 'weekly',
        simulationDays: 90,
        avgDailyIncome: 50000,
        avgMonthlyExpenses: 800000,
      );

      final snapshots = simulateCashFlow(input);

      expect(snapshots.length, equals(90));
      // Should have multiple weeks where recurring applies
      final weeklyExpenses = snapshots.where((s) => s.expenses >= 50000).length;
      expect(weeklyExpenses, greaterThan(0));
    });

    test('simulateCashFlow with large commitment amount', () {
      final input = CashFlowInput(
        startingBalance: 10000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 5000000,
        newRecurringFrequency: 'monthly',
        simulationDays: 90,
        avgDailyIncome: 500000,
        avgMonthlyExpenses: 2000000,
      );

      final snapshots = simulateCashFlow(input);

      expect(snapshots.length, equals(90));
      final result = analyzeCashFlow(snapshots);
      expect(result.safetyLevel, isNotNull);
    });

    test('CashFlowResult recommendation levels', () {
      final safeSnapshots = [
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

      final tightSnapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 100000,
          income: 100000,
          expenses: 99000,
          debtPayments: 0,
          closingBalance: 101000,
        ),
      ];

      final riskySnapshots = [
        DailyCashSnapshot(
          date: DateTime.now(),
          dateJalaliString: '1403-09-01',
          openingBalance: 1000000,
          income: 50000,
          expenses: 500000,
          debtPayments: 0,
          closingBalance: 550000,
          isNegative: true,
        ),
      ];

      final safeResult = analyzeCashFlow(safeSnapshots);
      final tightResult = analyzeCashFlow(tightSnapshots);
      final riskyResult = analyzeCashFlow(riskySnapshots);

      expect(safeResult.safetyLevel, equals('safe'));
      expect(tightResult.safetyLevel, equals('tight'));
      expect(riskyResult.hasNegativeCash, isTrue);
    });
  });

  group('CashFlowSimulator - Integration Tests', () {
    test('Complex scenario: multiple commitments and varying expenses', () {
      final input = CashFlowInput(
        startingBalance: 5000000,
        loans: [],
        installments: [
          {'id': 1, 'amount': 500000, 'due_date': '1403-09-15'},
          {'id': 2, 'amount': 300000, 'due_date': '1403-09-25'},
        ],
        budgets: [],
        newRecurringAmount: 200000,
        newRecurringFrequency: 'monthly',
        simulationDays: 90,
        avgDailyIncome: 150000,
        avgMonthlyExpenses: 2000000,
      );

      final snapshots = simulateCashFlow(input);

      expect(snapshots.length, equals(90));
      expect(snapshots.every((s) => s.dateJalaliString.isNotEmpty), isTrue);

      // Verify all snapshots have proper structure
      for (final snap in snapshots) {
        expect(snap.openingBalance, isNotNull);
        expect(snap.closingBalance, isNotNull);
        expect(snap.income, greaterThanOrEqualTo(0));
        expect(snap.expenses, greaterThanOrEqualTo(0));
      }
    });

    test('Scenario: gradual improvement in cash position', () {
      final input = CashFlowInput(
        startingBalance: 1000000,
        loans: [],
        installments: [],
        budgets: [],
        newRecurringAmount: 100000,
        newRecurringFrequency: 'monthly',
        simulationDays: 90,
        avgDailyIncome: 300000,
        avgMonthlyExpenses: 500000,
      );

      final snapshots = simulateCashFlow(input);

      // Check if balance generally improves
      final firstHalf = snapshots.take(45).toList();
      final secondHalf = snapshots.skip(45).toList();

      final avgFirstHalf =
          firstHalf.fold<int>(0, (sum, s) => sum + s.closingBalance) ~/
          firstHalf.length;
      final avgSecondHalf =
          secondHalf.fold<int>(0, (sum, s) => sum + s.closingBalance) ~/
          secondHalf.length;

      expect(avgSecondHalf, greaterThan(avgFirstHalf));
    });

    test('Scenario: cash flow crisis detection', () {
      final input = CashFlowInput(
        startingBalance: 2000000,
        loans: [],
        installments: [
          {'id': 1, 'amount': 2000000, 'due_date': '1403-09-10'},
        ],
        budgets: [],
        newRecurringAmount: 0,
        newRecurringFrequency: 'monthly',
        simulationDays: 30,
        avgDailyIncome: 50000,
        avgMonthlyExpenses: 500000,
      );

      final snapshots = simulateCashFlow(input);
      final result = analyzeCashFlow(snapshots);

      // Should produce valid result
      expect(result.safetyLevel, isNotNull);
      expect(
        ['safe', 'tight', 'risky', 'critical'].contains(result.safetyLevel),
        isTrue,
      );
    });
  });
}
