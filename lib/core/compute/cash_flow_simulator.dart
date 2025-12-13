import 'package:debt_manager/core/utils/jalali_utils.dart';

/// DTO for a single day's cash snapshot
class DailyCashSnapshot {
  final DateTime date;
  final String dateJalaliString; // yyyy-MM-dd
  final int openingBalance;
  final int income;
  final int expenses;
  final int debtPayments;
  final int closingBalance;
  final bool isNegative;

  DailyCashSnapshot({
    required this.date,
    required this.dateJalaliString,
    required this.openingBalance,
    required this.income,
    required this.expenses,
    required this.debtPayments,
    required this.closingBalance,
    this.isNegative = false,
  });

  Map<String, dynamic> toMap() => {
        'date': date.toIso8601String(),
        'dateJalali': dateJalaliString,
        'openingBalance': openingBalance,
        'income': income,
        'expenses': expenses,
        'debtPayments': debtPayments,
        'closingBalance': closingBalance,
        'isNegative': isNegative,
      };
}

/// Input DTO for simulator
class CashFlowInput {
  final int startingBalance;
  final List<Map<String, dynamic>> loans; // loan Maps
  final List<Map<String, dynamic>> installments; // installment Maps
  final List<Map<String, dynamic>> budgets; // budget Maps
  final int newRecurringAmount; // new commitment amount
  final String newRecurringFrequency; // 'daily', 'weekly', 'monthly'
  final int simulationDays; // 30-90
  final int avgDailyIncome; // estimated from past data
  final int avgMonthlyExpenses; // baseline spending

  CashFlowInput({
    required this.startingBalance,
    required this.loans,
    required this.installments,
    required this.budgets,
    required this.newRecurringAmount,
    required this.newRecurringFrequency,
    required this.simulationDays,
    required this.avgDailyIncome,
    required this.avgMonthlyExpenses,
  });
}

/// Top-level compute entry: simulate cash flow for N days ahead.
/// All inputs are plain Maps/Lists (isolate-safe).
List<DailyCashSnapshot> simulateCashFlow(CashFlowInput input) {
  final snapshots = <DailyCashSnapshot>[];
  int balance = input.startingBalance;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // Group installments by due date for quick lookup
  final installmentsByDate = <String, List<Map<String, dynamic>>>{};
  for (final inst in input.installments) {
    final paidAt = inst['paid_at'] as String?;
    if (paidAt != null && paidAt.isNotEmpty) {
      // Already paid, skip
      continue;
    }
    final dueDate = inst['due_date'] as String?;
    if (dueDate != null) {
      installmentsByDate.putIfAbsent(dueDate, () => []).add(inst);
    }
  }

  for (var dayOffset = 0; dayOffset < input.simulationDays; dayOffset++) {
    final currentDate = today.add(Duration(days: dayOffset));
    final jalaliDate = dateTimeToJalali(currentDate);
    final dateStr =
        '${jalaliDate.year}-${jalaliDate.month.toString().padLeft(2, '0')}-${jalaliDate.day.toString().padLeft(2, '0')}';

    int dayIncome = 0;
    int dayExpenses = 0;
    int dayDebtPayments = 0;

    // Estimate income: simple heuristic (spread evenly)
    dayIncome = (input.avgDailyIncome * 100 ~/ 100).toInt(); // rounded

    // Estimate expenses: spread budget amounts
    dayExpenses = (input.avgMonthlyExpenses ~/ 30).toInt();

    // Add new recurring commitment
    if (input.newRecurringFrequency == 'daily') {
      dayExpenses += input.newRecurringAmount;
    } else if (input.newRecurringFrequency == 'weekly' && dayOffset % 7 == 0) {
      dayExpenses += input.newRecurringAmount;
    } else if (input.newRecurringFrequency == 'monthly' &&
        currentDate.day == today.day) {
      dayExpenses += input.newRecurringAmount;
    }

    // Check for due installment payments
    final dueSample = installmentsByDate[dateStr];
    if (dueSample != null) {
      for (final inst in dueSample) {
        final amount = inst['amount'] as int? ?? 0;
        dayDebtPayments += amount;
      }
    }

    // Compute balance
    balance = balance + dayIncome - dayExpenses - dayDebtPayments;
    final isNegative = balance < 0;

    snapshots.add(DailyCashSnapshot(
      date: currentDate,
      dateJalaliString: dateStr,
      openingBalance: balance + dayExpenses + dayDebtPayments - dayIncome,
      income: dayIncome,
      expenses: dayExpenses,
      debtPayments: dayDebtPayments,
      closingBalance: balance,
      isNegative: isNegative,
    ));
  }

  return snapshots;
}

/// Result DTO returned by simulator
class CashFlowResult {
  final List<DailyCashSnapshot> snapshots;
  final bool hasNegativeCash;
  final int minBalance;
  final int maxBalance;
  final int daysUntilNegative; // -1 if never negative

  CashFlowResult({
    required this.snapshots,
    required this.hasNegativeCash,
    required this.minBalance,
    required this.maxBalance,
    required this.daysUntilNegative,
  });

  /// Safety assessment
  String get safetyLevel {
    if (!hasNegativeCash && minBalance > 1000000) return 'safe';
    if (!hasNegativeCash && minBalance > 0) return 'tight';
    if (daysUntilNegative > 0) return 'risky';
    return 'critical';
  }

  /// Human-readable recommendation
  String get recommendation {
    switch (safetyLevel) {
      case 'safe':
        return '✓ You can comfortably afford this commitment.';
      case 'tight':
        return '⚠️ Possible but tight. Consider reducing other expenses.';
      case 'risky':
        return '⚠️ You\'ll hit negative cash on day $daysUntilNegative. Not recommended.';
      case 'critical':
        return '✗ This would immediately create cash flow problems.';
      default:
        return 'Unknown';
    }
  }

  Map<String, dynamic> toMap() => {
        'snapshots': snapshots.map((s) => s.toMap()).toList(),
        'hasNegativeCash': hasNegativeCash,
        'minBalance': minBalance,
        'maxBalance': maxBalance,
        'daysUntilNegative': daysUntilNegative,
        'safetyLevel': safetyLevel,
        'recommendation': recommendation,
      };
}

/// Post-process snapshots to compute result
CashFlowResult analyzeCashFlow(List<DailyCashSnapshot> snapshots) {
  if (snapshots.isEmpty) {
    return CashFlowResult(
      snapshots: snapshots,
      hasNegativeCash: false,
      minBalance: 0,
      maxBalance: 0,
      daysUntilNegative: -1,
    );
  }

  int minBalance = snapshots.first.closingBalance;
  int maxBalance = snapshots.first.closingBalance;
  int daysUntilNegative = -1;

  for (var i = 0; i < snapshots.length; i++) {
    final snap = snapshots[i];
    minBalance = minBalance > snap.closingBalance
        ? snap.closingBalance
        : minBalance;
    maxBalance = maxBalance < snap.closingBalance
        ? snap.closingBalance
        : maxBalance;

    if (snap.isNegative && daysUntilNegative < 0) {
      daysUntilNegative = i;
    }
  }

  return CashFlowResult(
    snapshots: snapshots,
    hasNegativeCash: daysUntilNegative >= 0,
    minBalance: minBalance,
    maxBalance: maxBalance,
    daysUntilNegative: daysUntilNegative,
  );
}
