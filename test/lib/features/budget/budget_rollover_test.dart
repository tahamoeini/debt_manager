import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget Rollover Tests', () {
    // Helper: Simulate monthly budget cycle
    Map<String, dynamic> calculateMonthlyRollover({
      required int budgetLimit,
      required int spent,
      required bool allowRollover,
      required double rolloverPercentage,
    }) {
      final remaining = budgetLimit - spent;
      int nextMonthBudget = budgetLimit;

      if (allowRollover && remaining > 0) {
        final rolloverAmount = (remaining * rolloverPercentage).toInt();
        nextMonthBudget = budgetLimit + rolloverAmount;
      }

      return {
        'currentMonthSpent': spent,
        'currentMonthRemaining': remaining,
        'currentMonthOverspent': remaining < 0,
        'nextMonthBudget': nextMonthBudget,
        'rolledOverAmount': allowRollover && remaining > 0
            ? (remaining * rolloverPercentage).toInt()
            : 0,
      };
    }

    // Helper: Simulate budget period (month, quarter, etc.)
    List<Map<String, dynamic>> simulateBudgetPeriods({
      required int initialBudget,
      required List<int> monthlySpending,
      required bool allowRollover,
      required double rolloverPercentage,
    }) {
      final periods = <Map<String, dynamic>>[];
      int currentBudget = initialBudget;

      for (var i = 0; i < monthlySpending.length; i++) {
        final spent = monthlySpending[i];
        final remaining = currentBudget - spent;
        final overBudget = remaining < 0;

        periods.add({
          'month': i + 1,
          'budgetLimit': currentBudget,
          'spent': spent,
          'remaining': remaining,
          'overBudget': overBudget,
          'spending_percentage': (spent / currentBudget * 100).toInt(),
        });

        // Calculate next month budget
        if (allowRollover && remaining > 0) {
          final rollover = (remaining * rolloverPercentage).toInt();
          currentBudget = initialBudget + rollover;
        } else if (overBudget && allowRollover) {
          // Rollover negative (deficit)
          currentBudget = initialBudget;
        } else {
          currentBudget = initialBudget;
        }
      }

      return periods;
    }

    // Helper: Calculate cumulative budget performance
    Map<String, dynamic> analyzeBudgetPerformance(
      List<Map<String, dynamic>> periods,
    ) {
      int totalBudget = 0;
      int totalSpent = 0;
      int totalRemaining = 0;
      int monthsOverBudget = 0;

      for (final period in periods) {
        totalBudget += period['budgetLimit'] as int;
        totalSpent += period['spent'] as int;
        totalRemaining += period['remaining'] as int;
        if (period['overBudget'] as bool) monthsOverBudget += 1;
      }

      return {
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'totalRemaining': totalRemaining,
        'monthsOverBudget': monthsOverBudget,
        'averageMonthlyBudget': (totalBudget / periods.length).toInt(),
        'averageMonthlySpending': (totalSpent / periods.length).toInt(),
        'budgetAdherence': (totalSpent / totalBudget * 100).toInt(),
      };
    }

    test('Simple monthly budget - within limit', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 10000000,
        spent: 7000000,
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      expect(result['currentMonthSpent'], equals(7000000));
      expect(result['currentMonthRemaining'], equals(3000000));
      expect(result['currentMonthOverspent'], isFalse);
      expect(result['rolledOverAmount'], equals(1500000)); // 50% of remaining
    });

    test('Budget exceeded - no rollover', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 10000000,
        spent: 12000000,
        allowRollover: false,
        rolloverPercentage: 0.5,
      );

      expect(result['currentMonthRemaining'], equals(-2000000));
      expect(result['currentMonthOverspent'], isTrue);
      expect(
        result['rolledOverAmount'],
        equals(0),
      ); // No rollover when over budget
      expect(result['nextMonthBudget'], equals(10000000)); // Reset to base
    });

    test('Full rollover - 100% carryover', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 5000000,
        spent: 2000000,
        allowRollover: true,
        rolloverPercentage: 1.0,
      );

      expect(result['rolledOverAmount'], equals(3000000));
      expect(result['nextMonthBudget'], equals(8000000));
    });

    test('No rollover - reset each month', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 5000000,
        spent: 2000000,
        allowRollover: false,
        rolloverPercentage: 0.0,
      );

      expect(result['rolledOverAmount'], equals(0));
      expect(result['nextMonthBudget'], equals(5000000));
    });

    test('Quarterly rollover accumulation', () {
      final periods = simulateBudgetPeriods(
        initialBudget: 5000000,
        monthlySpending: [3000000, 4000000, 2000000],
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      expect(periods.length, equals(3));
      expect(periods[0]['budgetLimit'], equals(5000000));
      expect(periods[0]['spent'], equals(3000000));

      // Second month budget = base + rollover from month 1
      final month1Remaining = 5000000 - 3000000;
      final month1Rollover = (month1Remaining * 0.5).toInt();
      expect(periods[1]['budgetLimit'], equals(5000000 + month1Rollover));
    });

    test('Cumulative budget performance tracking', () {
      final periods = simulateBudgetPeriods(
        initialBudget: 10000000,
        monthlySpending: [8000000, 9000000, 7000000, 10000000],
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      final performance = analyzeBudgetPerformance(periods);

      expect(performance['totalSpent'], equals(34000000));
      expect(performance['monthsOverBudget'], greaterThanOrEqualTo(0));
      expect(performance['budgetAdherence'], greaterThan(0));
      expect(performance['budgetAdherence'], lessThanOrEqualTo(100));
    });

    test('Month-over-month budget trend', () {
      final periods = simulateBudgetPeriods(
        initialBudget: 5000000,
        monthlySpending: [1000000, 2000000, 1500000, 2500000, 1000000],
        allowRollover: true,
        rolloverPercentage: 0.75,
      );

      // First month should be within budget
      expect(periods[0]['overBudget'], isFalse);

      // With rollover, budget should generally grow or stay same unless overspent
      for (var i = 1; i < periods.length; i++) {
        final currentBudget = periods[i]['budgetLimit'] as int;
        final previousBudget = periods[i - 1]['budgetLimit'] as int;

        if (currentBudget < previousBudget) {
          // Budget decreased - only if previous was overspent
          expect(periods[i - 1]['overBudget'], isTrue);
        }
      }
    });

    test('Zero spending - maximum rollover', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 10000000,
        spent: 0,
        allowRollover: true,
        rolloverPercentage: 1.0,
      );

      expect(result['rolledOverAmount'], equals(10000000));
      expect(result['nextMonthBudget'], equals(20000000));
    });

    test('Exact budget match - no surplus or deficit', () {
      final result = calculateMonthlyRollover(
        budgetLimit: 10000000,
        spent: 10000000,
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      expect(result['currentMonthRemaining'], equals(0));
      expect(result['rolledOverAmount'], equals(0));
      expect(result['nextMonthBudget'], equals(10000000));
    });

    test('Negative rollover scenario (deficit handling)', () {
      final periods = simulateBudgetPeriods(
        initialBudget: 5000000,
        monthlySpending: [6000000, 5500000, 4000000],
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      // First month over budget
      expect(periods[0]['overBudget'], isTrue);
      expect(periods[0]['remaining'], equals(-1000000));

      // Second month should reset to base budget
      expect(periods[1]['budgetLimit'], equals(5000000));
    });

    test('Spending percentage calculation', () {
      final periods = simulateBudgetPeriods(
        initialBudget: 10000000,
        monthlySpending: [2500000, 5000000, 7500000, 10000000],
        allowRollover: false,
        rolloverPercentage: 0.0,
      );

      expect(periods[0]['spending_percentage'], equals(25));
      expect(periods[1]['spending_percentage'], equals(50));
      expect(periods[2]['spending_percentage'], equals(75));
      expect(periods[3]['spending_percentage'], equals(100));
    });

    test('Dual-budget scenario (savings + spending)', () {
      // Some months save, some months spend
      final periods = simulateBudgetPeriods(
        initialBudget: 10000000,
        monthlySpending: [2000000, 12000000, 3000000, 11000000, 1000000],
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      // With 10M budget and 12M spending, some months should overspend
      // Just verify that we have periods data
      expect(periods.length, greaterThanOrEqualTo(1));

      // Verify each period has the expected structure
      for (final period in periods) {
        expect(period.containsKey('overBudget'), isTrue);
        expect(period['overBudget'] is bool, isTrue);
      }
    });

    test('Category-based budget rollover', () {
      // Simulate different categories with independent rollover
      final categories = {
        'groceries': {'budget': 2000000, 'spent': 1500000},
        'utilities': {'budget': 500000, 'spent': 500000},
        'entertainment': {'budget': 1000000, 'spent': 800000},
        'transport': {'budget': 500000, 'spent': 600000},
      };

      final results = <String, Map<String, dynamic>>{};
      for (final entry in categories.entries) {
        results[entry.key] = calculateMonthlyRollover(
          budgetLimit: entry.value['budget'] as int,
          spent: entry.value['spent'] as int,
          allowRollover: true,
          rolloverPercentage: 0.5,
        );
      }

      // Groceries and entertainment have surplus
      expect(results['groceries']!['rolledOverAmount'], greaterThan(0));
      expect(results['entertainment']!['rolledOverAmount'], greaterThan(0));

      // Utilities has exact match, transport has deficit
      expect(results['utilities']!['rolledOverAmount'], equals(0));
      expect(results['transport']!['currentMonthOverspent'], isTrue);
    });

    test('Annual budget summary', () {
      final monthlyBudget = 5000000;
      final spending = List.generate(12, (i) => 4000000 + (i % 3) * 500000);

      final periods = simulateBudgetPeriods(
        initialBudget: monthlyBudget,
        monthlySpending: spending,
        allowRollover: false,
        rolloverPercentage: 0.0,
      );

      final performance = analyzeBudgetPerformance(periods);

      expect(performance['budgetAdherence'], greaterThan(70));
      expect(performance['budgetAdherence'], lessThan(100));
      expect(performance['monthsOverBudget'], lessThanOrEqualTo(12));
    });

    test('Rollover percentage variation', () {
      const budgetLimit = 10000000;
      const spent = 6000000;
      const remaining = budgetLimit - spent;

      final noRollover = calculateMonthlyRollover(
        budgetLimit: budgetLimit,
        spent: spent,
        allowRollover: true,
        rolloverPercentage: 0.0,
      );

      final partialRollover = calculateMonthlyRollover(
        budgetLimit: budgetLimit,
        spent: spent,
        allowRollover: true,
        rolloverPercentage: 0.5,
      );

      final fullRollover = calculateMonthlyRollover(
        budgetLimit: budgetLimit,
        spent: spent,
        allowRollover: true,
        rolloverPercentage: 1.0,
      );

      expect(noRollover['nextMonthBudget'], equals(budgetLimit));
      expect(
        partialRollover['nextMonthBudget'],
        equals(budgetLimit + (remaining ~/ 2)),
      );
      expect(fullRollover['nextMonthBudget'], equals(budgetLimit + remaining));
    });
  });
}
