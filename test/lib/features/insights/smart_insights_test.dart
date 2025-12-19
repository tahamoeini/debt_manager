import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smart Insights Detection Tests', () {
    // Helper: Detect unusual spending pattern
    bool detectUnusualSpending({
      required int currentMonthSpending,
      required List<int> previousMonthsSpending,
      required double threshold, // e.g., 1.5 = 50% higher than average
    }) {
      if (previousMonthsSpending.isEmpty) return false;

      final average =
          previousMonthsSpending.fold<double>(0, (sum, val) => sum + val) /
              previousMonthsSpending.length;

      return currentMonthSpending > (average * threshold);
    }

    // Helper: Detect spending trend
    String detectSpendingTrend({
      required List<int> monthlySpending,
      required double trendThreshold, // e.g., 0.1 = 10% increase
    }) {
      if (monthlySpending.length < 2) return 'insufficient_data';

      final first3Months =
          monthlySpending.take(3).fold<double>(0, (sum, val) => sum + val) / 3;
      final last3Months = monthlySpending
              .skip(monthlySpending.length - 3)
              .fold<double>(0, (sum, val) => sum + val) /
          3;

      final changePercent = (last3Months - first3Months) / first3Months;

      if (changePercent > trendThreshold) return 'increasing';
      if (changePercent < -trendThreshold) return 'decreasing';
      return 'stable';
    }

    // Helper: Detect debt payoff opportunity
    bool detectPayoffOpportunity({
      required int currentMonthSavings,
      required int minimumThreshold,
    }) {
      return currentMonthSavings >= minimumThreshold;
    }

    // Helper: Detect subscription (recurring payment)
    bool detectSubscription({
      required List<Map<String, dynamic>> transactions,
      required int minOccurrences,
      required int tolerance, // ±tolerance amount
    }) {
      if (transactions.isEmpty) return false;

      // Group by amount (with tolerance)
      final clusters = <List<int>>[];

      for (final txn in transactions) {
        final amount = txn['amount'] as int;
        var foundCluster = false;

        // Check if this amount belongs to any existing cluster
        for (final cluster in clusters) {
          final clusterAvg =
              cluster.fold<int>(0, (sum, a) => sum + a) ~/ cluster.length;
          if ((amount - clusterAvg).abs() <= tolerance) {
            cluster.add(amount);
            foundCluster = true;
            break;
          }
        }

        // Create new cluster if not found
        if (!foundCluster) {
          clusters.add([amount]);
        }
      }

      // Check if any cluster has enough occurrences
      for (final cluster in clusters) {
        if (cluster.length >= minOccurrences) {
          return true;
        }
      }

      return false;
    }

    // Helper: Calculate financial health score
    Map<String, dynamic> assessFinancialHealth({
      required int monthlyIncome,
      required int monthlyExpenses,
      required int totalDebt,
      required int savingsBalance,
    }) {
      final savingsRate = monthlyIncome > 0
          ? ((monthlyIncome - monthlyExpenses) / monthlyIncome * 100).toInt()
          : 0;
      final debtToIncomeRatio =
          monthlyIncome > 0 ? (totalDebt / monthlyIncome).toDouble() : 0.0;
      final emergencyFund =
          monthlyExpenses > 0 ? savingsBalance ~/ monthlyExpenses : 0;

      String healthScore = 'poor';
      if (savingsRate >= 20 && debtToIncomeRatio < 2.0 && emergencyFund >= 3) {
        healthScore = 'excellent';
      } else if (savingsRate >= 10 && debtToIncomeRatio < 3.0) {
        healthScore = 'good';
      } else if (savingsRate >= 0 && debtToIncomeRatio < 5.0) {
        healthScore = 'fair';
      }

      return {
        'savingsRate': savingsRate,
        'debtToIncomeRatio': debtToIncomeRatio,
        'emergencyFundMonths': emergencyFund,
        'healthScore': healthScore,
      };
    }

    test('Detect unusual spending spike', () {
      const currentMonth = 15000000;
      final previousMonths = [5000000, 6000000, 5500000];

      final isUnusual = detectUnusualSpending(
        currentMonthSpending: currentMonth,
        previousMonthsSpending: previousMonths,
        threshold: 1.5,
      );

      expect(isUnusual, isTrue);
    });

    test('Normal spending variation - not unusual', () {
      const currentMonth = 6000000;
      final previousMonths = [5000000, 6000000, 5500000];

      final isUnusual = detectUnusualSpending(
        currentMonthSpending: currentMonth,
        previousMonthsSpending: previousMonths,
        threshold: 1.5,
      );

      expect(isUnusual, isFalse);
    });

    test('Empty previous months - no detection', () {
      const currentMonth = 15000000;
      final previousMonths = <int>[];

      final isUnusual = detectUnusualSpending(
        currentMonthSpending: currentMonth,
        previousMonthsSpending: previousMonths,
        threshold: 1.5,
      );

      expect(isUnusual, isFalse);
    });

    test('Increasing spending trend detection', () {
      final spending = [5000000, 5500000, 6000000, 6500000, 7000000, 7500000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      expect(trend, equals('increasing'));
    });

    test('Decreasing spending trend detection', () {
      final spending = [10000000, 9500000, 9000000, 8500000, 8000000, 7500000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      expect(trend, equals('decreasing'));
    });

    test('Stable spending trend detection', () {
      final spending = [5000000, 5100000, 5050000, 4950000, 5000000, 5100000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      expect(trend, equals('stable'));
    });

    test('Insufficient data for trend detection', () {
      final spending = [5000000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      expect(trend, equals('insufficient_data'));
    });

    test('Payoff opportunity detection - surplus available', () {
      const savings = 2000000;
      const threshold = 1000000;

      final opportunity = detectPayoffOpportunity(
        currentMonthSavings: savings,
        minimumThreshold: threshold,
      );

      expect(opportunity, isTrue);
    });

    test('Payoff opportunity not detected - insufficient savings', () {
      const savings = 500000;
      const threshold = 1000000;

      final opportunity = detectPayoffOpportunity(
        currentMonthSavings: savings,
        minimumThreshold: threshold,
      );

      expect(opportunity, isFalse);
    });

    test('Subscription detection - recurring payment', () {
      final transactions = [
        {'amount': 100000, 'date': '1403-01-01'},
        {'amount': 100000, 'date': '1403-02-01'},
        {'amount': 100000, 'date': '1403-03-01'},
        {'amount': 100000, 'date': '1403-04-01'},
        {'amount': 50000, 'date': '1403-04-15'},
      ];

      final isSubscription = detectSubscription(
        transactions: transactions,
        minOccurrences: 3,
        tolerance: 5000,
      );

      expect(isSubscription, isTrue);
    });

    test('Subscription detection - similar amounts', () {
      final transactions = [
        {'amount': 100000, 'date': '1403-01-01'},
        {'amount': 101000, 'date': '1403-02-01'},
        {'amount': 99000, 'date': '1403-03-01'},
        {'amount': 100500, 'date': '1403-04-01'},
      ];

      final isSubscription = detectSubscription(
        transactions: transactions,
        minOccurrences: 3,
        tolerance: 2500, // Increased tolerance to cover 99000-101000 range
      );

      expect(isSubscription, isTrue);
    });

    test('Subscription not detected - random amounts', () {
      final transactions = [
        {'amount': 50000, 'date': '1403-01-01'},
        {'amount': 150000, 'date': '1403-02-01'},
        {'amount': 75000, 'date': '1403-03-01'},
        {'amount': 200000, 'date': '1403-04-01'},
      ];

      final isSubscription = detectSubscription(
        transactions: transactions,
        minOccurrences: 3,
        tolerance: 5000,
      );

      expect(isSubscription, isFalse);
    });

    test('Empty transaction list - no subscription', () {
      final transactions = <Map<String, dynamic>>[];

      final isSubscription = detectSubscription(
        transactions: transactions,
        minOccurrences: 3,
        tolerance: 5000,
      );

      expect(isSubscription, isFalse);
    });

    test('Financial health assessment - excellent', () {
      final health = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 6000000,
        totalDebt: 15000000,
        savingsBalance: 20000000,
      );

      expect(health['healthScore'], equals('excellent'));
      expect(health['savingsRate'] as int, equals(40));
      expect(health['emergencyFundMonths'] as int, greaterThanOrEqualTo(3));
    });

    test('Financial health assessment - good', () {
      final health = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 8000000,
        totalDebt: 20000000,
        savingsBalance: 10000000,
      );

      expect(health['healthScore'], equals('good'));
      expect(health['savingsRate'] as int, equals(20));
    });

    test('Financial health assessment - fair', () {
      final health = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 9500000,
        totalDebt: 30000000,
        savingsBalance: 2000000,
      );

      expect(health['healthScore'], equals('fair'));
      expect(health['savingsRate'] as int, equals(5));
    });

    test('Financial health assessment - poor', () {
      final health = assessFinancialHealth(
        monthlyIncome: 5000000,
        monthlyExpenses: 6000000,
        totalDebt: 50000000,
        savingsBalance: 100000,
      );

      expect(health['healthScore'], equals('poor'));
      expect(health['savingsRate'] as int, lessThan(0));
    });

    test('Debt-to-income ratio calculation', () {
      final health = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 5000000,
        totalDebt: 50000000,
        savingsBalance: 10000000,
      );

      expect(health['debtToIncomeRatio'] as double, equals(5.0));
    });

    test('Emergency fund months calculation', () {
      final health = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 2000000,
        totalDebt: 10000000,
        savingsBalance: 6000000,
      );

      expect(health['emergencyFundMonths'] as int, equals(3));
    });

    test('Multiple insights detection', () {
      final spending = [5000000, 5500000, 6000000, 15000000, 6200000, 6100000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      final currentMonthUnusual = detectUnusualSpending(
        currentMonthSpending: 15000000,
        previousMonthsSpending: spending.sublist(0, 3),
        threshold: 1.5,
      );

      expect(trend, isNotEmpty);
      expect(currentMonthUnusual, isTrue);
    });

    test('Subscription detection with varying patterns', () {
      // Subscription + random transactions
      final transactions = [
        {'amount': 50000, 'date': '1403-01-01'}, // subscription
        {'amount': 200000, 'date': '1403-01-15'}, // one-time
        {'amount': 50000, 'date': '1403-02-01'}, // subscription
        {'amount': 150000, 'date': '1403-02-20'}, // one-time
        {'amount': 50000, 'date': '1403-03-01'}, // subscription
        {'amount': 300000, 'date': '1403-03-25'}, // one-time
      ];

      final isSubscription = detectSubscription(
        transactions: transactions,
        minOccurrences: 3,
        tolerance: 5000,
      );

      expect(isSubscription, isTrue);
    });

    test('Health score improves with income increase', () {
      final health1 = assessFinancialHealth(
        monthlyIncome: 5000000,
        monthlyExpenses: 4000000,
        totalDebt: 20000000,
        savingsBalance: 5000000,
      );

      final health2 = assessFinancialHealth(
        monthlyIncome: 10000000,
        monthlyExpenses: 4000000,
        totalDebt: 20000000,
        savingsBalance: 5000000,
      );

      expect(
        health2['savingsRate'] as int,
        greaterThan(health1['savingsRate'] as int),
      );
      expect(
        health2['debtToIncomeRatio'] as double,
        lessThan(health1['debtToIncomeRatio'] as double),
      );
    });

    test('Spending trend anomaly detection combined with health check', () {
      // Simulate user with increasing spending trend but still healthy
      final spending = [3000000, 3500000, 4000000, 4500000, 5000000];

      final trend = detectSpendingTrend(
        monthlySpending: spending,
        trendThreshold: 0.1,
      );

      final health = assessFinancialHealth(
        monthlyIncome: 15000000,
        monthlyExpenses: 5000000,
        totalDebt: 20000000,
        savingsBalance: 25000000,
      );

      expect(trend, equals('increasing')); // Alert: increasing spending
      expect(
        health['healthScore'],
        isNotEmpty,
      ); // But overall health is still tracked
    });
  });
}
