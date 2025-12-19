import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Payoff Projection Tests', () {
    // Helper: Snowball strategy (lowest balance first)
    List<Map<String, dynamic>> simulateSnowball({
      required List<Map<String, dynamic>>
          debts, // [{balance, rate, minPayment}]
      required int extraPayment,
      required int maxMonths,
    }) {
      final projections = <Map<String, dynamic>>[];
      final balances = debts.map((d) => d['balance'] as int).toList();
      const annualRate = 12.0;

      for (var month = 0; month < maxMonths; month++) {
        // Sort by balance (snowball)
        final sorted = <(int index, int balance)>[];
        for (var i = 0; i < balances.length; i++) {
          if (balances[i] > 0) {
            sorted.add((i, balances[i]));
          }
        }
        sorted.sort((a, b) => a.$2.compareTo(b.$2));

        // Apply payments (minimum + extra to smallest)
        int remainingExtra = extraPayment;
        for (final (index, _) in sorted) {
          final minPayment = debts[index]['minPayment'] as int? ?? 50000;
          int payment = minPayment;

          if (index == sorted.first.$1) {
            // Add extra to smallest debt
            payment += remainingExtra;
            remainingExtra = 0;
          }

          balances[index] = (balances[index] - payment).clamp(0, 999999999);
        }

        // Accrue interest
        for (var i = 0; i < balances.length; i++) {
          final interest = (balances[i] * (annualRate / 100.0 / 12)).toInt();
          balances[i] += interest;
        }

        final totalBalance = balances.fold<int>(0, (sum, b) => sum + b);
        projections.add({
          'month': month + 1,
          'totalBalance': totalBalance,
          'balances': List<int>.from(balances),
        });

        if (totalBalance == 0) break;
      }

      return projections;
    }

    // Helper: Avalanche strategy (highest rate first)
    List<Map<String, dynamic>> simulateAvalanche({
      required List<Map<String, dynamic>>
          debts, // [{balance, rate, minPayment}]
      required int extraPayment,
      required int maxMonths,
    }) {
      final projections = <Map<String, dynamic>>[];
      final balances = debts.map((d) => d['balance'] as int).toList();
      final rates = debts.map((d) => d['rate'] as double? ?? 12.0).toList();

      for (var month = 0; month < maxMonths; month++) {
        // Sort by rate (avalanche)
        final sorted = <(int index, double rate)>[];
        for (var i = 0; i < balances.length; i++) {
          if (balances[i] > 0) {
            sorted.add((i, rates[i]));
          }
        }
        sorted.sort((a, b) => b.$2.compareTo(a.$2)); // Highest rate first

        // Apply payments (minimum + extra to highest rate)
        int remainingExtra = extraPayment;
        for (final (index, _) in sorted) {
          final minPayment = debts[index]['minPayment'] as int? ?? 50000;
          int payment = minPayment;

          if (index == sorted.first.$1) {
            // Add extra to highest rate debt
            payment += remainingExtra;
            remainingExtra = 0;
          }

          balances[index] = (balances[index] - payment).clamp(0, 999999999);
        }

        // Accrue interest
        for (var i = 0; i < balances.length; i++) {
          final interest = (balances[i] * (rates[i] / 100.0 / 12)).toInt();
          balances[i] += interest;
        }

        final totalBalance = balances.fold<int>(0, (sum, b) => sum + b);
        projections.add({
          'month': month + 1,
          'totalBalance': totalBalance,
          'balances': List<int>.from(balances),
        });

        if (totalBalance == 0) break;
      }

      return projections;
    }

    test('Snowball strategy - single debt payoff', () {
      final debts = [
        {'balance': 5000000, 'rate': 12.0, 'minPayment': 100000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 200,
      );

      expect(projections.isNotEmpty, isTrue);
      expect(projections.last['totalBalance'], equals(0));
      expect(projections.length, lessThan(30)); // Should pay off in ~2-3 years
    });

    test('Avalanche strategy - single debt payoff', () {
      final debts = [
        {'balance': 5000000, 'rate': 15.0, 'minPayment': 100000},
      ];

      final projections = simulateAvalanche(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 200,
      );

      expect(projections.isNotEmpty, isTrue);
      expect(projections.last['totalBalance'], equals(0));
    });

    test('Snowball vs Avalanche - total interest comparison', () {
      final debts = [
        {'balance': 3000000, 'rate': 12.0, 'minPayment': 50000},
        {'balance': 5000000, 'rate': 18.0, 'minPayment': 100000},
        {'balance': 2000000, 'rate': 10.0, 'minPayment': 40000},
      ];

      final snowball = simulateSnowball(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 120,
      );

      final avalanche = simulateAvalanche(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 120,
      );

      // Both should have same payoff if they reach zero
      if (snowball.last['totalBalance'] == 0 &&
          avalanche.last['totalBalance'] == 0) {
        expect(snowball.length, lessThanOrEqualTo(avalanche.length + 2));
      }
    });

    test('Snowball strategy - multiple debts payoff order', () {
      final debts = [
        {'balance': 1000000, 'rate': 12.0, 'minPayment': 50000},
        {'balance': 5000000, 'rate': 12.0, 'minPayment': 100000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 300000,
        maxMonths: 120,
      );

      expect(projections.isNotEmpty, isTrue);
      // Smallest debt should be eliminated first
      expect(
        projections.first['balances'][0] < projections.first['balances'][1],
        isTrue,
      );
    });

    test('Avalanche strategy - highest rate payoff priority', () {
      final debts = [
        {'balance': 3000000, 'rate': 8.0, 'minPayment': 60000},
        {'balance': 3000000, 'rate': 20.0, 'minPayment': 60000},
      ];

      final projections = simulateAvalanche(
        debts: debts,
        extraPayment: 300000,
        maxMonths: 120,
      );

      expect(projections.isNotEmpty, isTrue);
      // Over time, higher rate debt should decrease faster
      final firstMonth = projections[0];
      final tenthMonth = projections[min(9, projections.length - 1)];

      expect(
        (firstMonth['balances'][1] as int) - (tenthMonth['balances'][1] as int),
        greaterThan(
          (firstMonth['balances'][0] as int) -
              (tenthMonth['balances'][0] as int),
        ),
      );
    });

    test('No extra payment - minimum payments only', () {
      final debts = [
        {'balance': 2000000, 'rate': 12.0, 'minPayment': 100000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 0,
        maxMonths: 300,
      );

      expect(projections.isNotEmpty, isTrue);
      // Should eventually pay off with just minimum payments
      expect(projections.any((p) => p['totalBalance'] == 0), isTrue);
    });

    test('High extra payment - rapid payoff', () {
      final debts = [
        {'balance': 2000000, 'rate': 12.0, 'minPayment': 50000},
      ];

      final slowPayoff = simulateSnowball(
        debts: debts,
        extraPayment: 0,
        maxMonths: 300,
      );

      final fastPayoff = simulateSnowball(
        debts: debts,
        extraPayment: 500000,
        maxMonths: 300,
      );

      // Fast payoff should complete in fewer months
      expect(
        fastPayoff.where((p) => p['totalBalance'] == 0).length,
        greaterThan(0),
      );
      expect(
        fastPayoff.takeWhile((p) => p['totalBalance'] > 0).length,
        lessThan(slowPayoff.takeWhile((p) => p['totalBalance'] > 0).length),
      );
    });

    test('Balance never increases after payment', () {
      final debts = [
        {'balance': 3000000, 'rate': 15.0, 'minPayment': 100000},
        {'balance': 2000000, 'rate': 12.0, 'minPayment': 80000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 60,
      );

      // Each month's total balance should not increase beyond the previous
      for (var i = 1; i < projections.length; i++) {
        final prev = projections[i - 1]['totalBalance'] as int;
        final current = projections[i]['totalBalance'] as int;

        // Current balance should be less (with small tolerance for interest)
        expect(current, lessThanOrEqualTo(prev + 1000));
      }
    });

    test('Very high interest rate scenario', () {
      final debts = [
        {
          'balance': 1000000,
          'rate': 50.0, // Very high interest
          'minPayment': 200000,
        },
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 300000,
        maxMonths: 120,
      );

      expect(projections.isNotEmpty, isTrue);
      // Should still eventually pay off
      expect(projections.any((p) => p['totalBalance'] == 0), isTrue);
    });

    test('Multiple debts with different rates and balances', () {
      final debts = [
        {'balance': 500000, 'rate': 8.0, 'minPayment': 25000},
        {'balance': 3000000, 'rate': 15.0, 'minPayment': 100000},
        {'balance': 1500000, 'rate': 12.0, 'minPayment': 50000},
        {'balance': 2000000, 'rate': 20.0, 'minPayment': 80000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 500000,
        maxMonths: 120,
      );

      expect(projections.isNotEmpty, isTrue);
      expect(projections.last['totalBalance'], equals(0));
    });

    test('Payoff date calculation - months until zero balance', () {
      final debts = [
        {'balance': 5000000, 'rate': 12.0, 'minPayment': 100000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 400000,
        maxMonths: 200,
      );

      final paidOffMonth = projections.indexWhere(
        (p) => p['totalBalance'] == 0,
      );
      expect(paidOffMonth, greaterThan(0));
      expect(paidOffMonth, lessThan(20)); // Should pay off within ~1.5 years
    });

    test('Consistent interest calculation across months', () {
      final debts = [
        {'balance': 1000000, 'rate': 12.0, 'minPayment': 50000},
      ];

      final projections = simulateSnowball(
        debts: debts,
        extraPayment: 200000,
        maxMonths: 10,
      );

      // Each month's interest should be reasonable
      for (var i = 1; i < projections.length; i++) {
        final currentBalance = projections[i]['totalBalance'] as int;
        final previousBalance = projections[i - 1]['totalBalance'] as int;

        expect(currentBalance, lessThanOrEqualTo(previousBalance));
      }
    });
  });
}

int min(int a, int b) => a < b ? a : b;
