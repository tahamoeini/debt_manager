import 'package:shamsi_date/shamsi_date.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';

// Top-level, isolate-safe functions for reports computation.

// Debug helper to log compute function performance
void _logComputeEntry(String functionName) {
  if (kDebugMode) {
    print(
        '[Compute] ▶ $functionName started at ${DateTime.now().millisecondsSinceEpoch}');
  }
}

void _logComputeExit(String functionName, int durationMs) {
  if (kDebugMode) {
    print('[Compute] ✓ $functionName completed in ${durationMs}ms');
  }
}

Map<String, int> computeSpendingByCategory(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> counterparties,
  List<Map<String, dynamic>> installments,
  int year,
  int month,
) {
  final startTime = DateTime.now().millisecondsSinceEpoch;
  _logComputeEntry('computeSpendingByCategory');

  final cpMap = <int, Map<String, dynamic>>{};
  for (final cp in counterparties) {
    final id = cp['id'];
    if (id is int) cpMap[id] = cp;
  }

  final loanMap = <int, Map<String, dynamic>>{};
  for (final loan in loans) {
    final id = loan['id'];
    if (id is int) loanMap[id] = loan;
  }

  final lastDay = Jalali(year, month, 1).monthLength;
  final mm = month.toString().padLeft(2, '0');
  final startDate = '$year-$mm-01';
  final endDate = '$year-$mm-${lastDay.toString().padLeft(2, '0')}';

  final categoryTotals = <String, int>{};

  for (final inst in installments) {
    final status = inst['status'] as String? ?? '';
    final paidAt = inst['paid_at'] as String?;
    if (status != 'paid' || paidAt == null) continue;
    if (paidAt.compareTo(startDate) < 0 || paidAt.compareTo(endDate) > 0) {
      continue;
    }

    final loanId = inst['loan_id'] is int
        ? inst['loan_id'] as int
        : int.tryParse(inst['loan_id'].toString()) ?? -1;
    final loan = loanMap[loanId];
    if (loan == null) continue;
    final cp = cpMap[loan['counterparty_id'] as int? ?? -1];
    final category = (cp != null ? (cp['type'] ?? cp['tag']) : null) ?? 'سایر';
    final actual = inst['actual_paid_amount'] is int
        ? inst['actual_paid_amount'] as int
        : (inst['amount'] is int
            ? inst['amount'] as int
            : int.tryParse(inst['amount'].toString()) ?? 0);

    categoryTotals[category] = (categoryTotals[category] ?? 0) + actual;
  }

  final duration = DateTime.now().millisecondsSinceEpoch - startTime;
  _logComputeExit('computeSpendingByCategory', duration);

  return categoryTotals;
}

// Adapter for compute() which requires a single message argument and a
// top-level callback.
Map<String, int> spendingByCategoryEntry(Map<String, dynamic> input) {
  return computeSpendingByCategory(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['cps'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['year'] as int,
    input['month'] as int,
  );
}

List<Map<String, dynamic>> spendingOverTimeEntry(Map<String, dynamic> input) {
  return computeSpendingOverTime(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['monthsBack'] as int,
    input['nowYear'] as int,
    input['nowMonth'] as int,
  );
}

List<Map<String, dynamic>> netWorthOverTimeEntry(Map<String, dynamic> input) {
  return computeNetWorthOverTime(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['monthsBack'] as int,
    input['nowYear'] as int,
    input['nowMonth'] as int,
  );
}

List<Map<String, dynamic>> projectDebtPayoffEntry(Map<String, dynamic> input) {
  return computeProjectDebtPayoff(
    Map<String, dynamic>.from(input['loan'] as Map),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['extraPayment'] as int?,
  );
}

List<Map<String, dynamic>> projectAllDebtsPayoffEntry(
    Map<String, dynamic> input) {
  return computeProjectAllDebtsPayoff(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['extraPayment'] as int?,
    input['strategy'] as String? ?? 'snowball',
  );
}

List<Map<String, dynamic>> computeSpendingOverTime(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> installments,
  int monthsBack,
  int nowYear,
  int nowMonth,
) {
  final results = <Map<String, dynamic>>[];

  for (var i = monthsBack - 1; i >= 0; i--) {
    var targetYear = nowYear;
    var targetMonth = nowMonth - i;
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }

    final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
    final mm = targetMonth.toString().padLeft(2, '0');
    final startDate = '$targetYear-$mm-01';
    final endDate = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';

    int borrowed = 0;
    int lent = 0;

    for (final inst in installments) {
      final status = inst['status'] as String? ?? '';
      final paidAt = inst['paid_at'] as String?;
      if (status != 'paid' || paidAt == null) continue;
      if (paidAt.compareTo(startDate) < 0 || paidAt.compareTo(endDate) > 0) {
        continue;
      }

      final loanId = inst['loan_id'] is int
          ? inst['loan_id'] as int
          : int.tryParse(inst['loan_id'].toString()) ?? -1;
      final loanObj = loans.firstWhere(
        (l) =>
            (l['id'] is int
                ? l['id'] as int
                : int.tryParse(l['id'].toString()) ?? -1) ==
            loanId,
        orElse: () => <String, dynamic>{},
      );
      if (loanObj.isEmpty) continue;
      final dir = loanObj['direction'] as String? ?? 'borrowed';
      final amount = inst['actual_paid_amount'] is int
          ? inst['actual_paid_amount'] as int
          : (inst['amount'] is int
              ? inst['amount'] as int
              : int.tryParse(inst['amount'].toString()) ?? 0);
      if (dir == 'borrowed') {
        borrowed += amount;
      } else {
        lent += amount;
      }
    }

    results.add({
      'year': targetYear,
      'month': targetMonth,
      'label': '$targetYear/$mm',
      'spending': borrowed,
      'income': lent,
      'net': lent - borrowed,
    });
  }

  return results;
}

List<Map<String, dynamic>> computeNetWorthOverTime(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> installments,
  int monthsBack,
  int nowYear,
  int nowMonth,
) {
  final results = <Map<String, dynamic>>[];

  for (var i = monthsBack - 1; i >= 0; i--) {
    var targetYear = nowYear;
    var targetMonth = nowMonth - i;
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }

    final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
    final mm = targetMonth.toString().padLeft(2, '0');
    final endDate = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';

    int assets = 0;
    int debts = 0;

    for (final loan in loans) {
      final lid = loan['id'] is int
          ? loan['id'] as int
          : int.tryParse(loan['id'].toString()) ?? -1;
      final dir = loan['direction'] as String? ?? 'borrowed';

      for (final inst in installments) {
        final due = inst['due_date_jalali'] as String? ?? '';
        if (due.compareTo(endDate) > 0) {
          continue;
        }

        final status = inst['status'] as String? ?? '';
        final paidAt = inst['paid_at'] as String?;
        final paidAfter = paidAt != null && paidAt.compareTo(endDate) > 0;

        final instLoanId = inst['loan_id'] is int
            ? inst['loan_id'] as int
            : int.tryParse(inst['loan_id'].toString()) ?? -1;
        if (instLoanId != lid) {
          continue;
        }

        if (status != 'paid' || paidAfter) {
          if (dir == 'lent') {
            assets += (inst['amount'] as int? ??
                int.tryParse(inst['amount'].toString()) ??
                0);
          } else {
            debts += (inst['amount'] as int? ??
                int.tryParse(inst['amount'].toString()) ??
                0);
          }
        }
      }
    }

    results.add({
      'year': targetYear,
      'month': targetMonth,
      'label': '$targetYear/$mm',
      'assets': assets,
      'debts': debts,
      'netWorth': assets - debts,
    });
  }

  return results;
}

List<Map<String, dynamic>> computeProjectDebtPayoff(
  Map<String, dynamic> loan,
  List<Map<String, dynamic>> installments,
  int? extraPayment,
) {
  final loanId = loan['id'] is int
      ? loan['id'] as int
      : int.tryParse(loan['id'].toString()) ?? -1;

  final insts = installments
      .where((i) =>
          (i['loan_id'] is int
              ? i['loan_id'] as int
              : int.tryParse(i['loan_id'].toString()) ?? -1) ==
          loanId)
      .toList();
  insts.sort((a, b) => (a['due_date_jalali'] as String)
      .compareTo(b['due_date_jalali'] as String));

  var balance = 0;
  for (final inst in insts) {
    final status = inst['status'] as String? ?? '';
    if (status != 'paid') {
      balance += (inst['amount'] as int? ??
          int.tryParse(inst['amount'].toString()) ??
          0);
    }
  }

  final projections = <Map<String, dynamic>>[];

  for (final inst in insts) {
    final status = inst['status'] as String? ?? '';
    if (status == 'paid') continue;
    final due = inst['due_date_jalali'] as String? ?? '';
    final parts = due.split('-');
    final year = int.tryParse(parts[0]) ?? 0;
    final month = int.tryParse(parts[1]) ?? 0;

    var payment =
        inst['amount'] as int? ?? int.tryParse(inst['amount'].toString()) ?? 0;
    if (extraPayment != null && extraPayment > 0) payment += extraPayment;

    balance -= payment;
    if (balance < 0) balance = 0;

    projections.add({
      'year': year,
      'month': month,
      'label': '$year/${month.toString().padLeft(2, '0')}',
      'balance': balance,
      'payment': inst['amount'] as int? ??
          int.tryParse(inst['amount'].toString()) ??
          0,
      'extraPayment': extraPayment ?? 0,
    });

    if (balance == 0) break;
  }

  return projections;
}

List<Map<String, dynamic>> computeProjectAllDebtsPayoff(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> installments,
  int? extraPayment,
  String strategy,
) {
  // Build unpaid balances per loan
  final loanMap = <int, Map<String, dynamic>>{};
  for (final l in loans) {
    final id = l['id'] is int
        ? l['id'] as int
        : int.tryParse(l['id'].toString()) ?? -1;
    loanMap[id] = l;
  }

  final instsByLoan = <int, List<Map<String, dynamic>>>{};
  for (final inst in installments) {
    final lid = inst['loan_id'] is int
        ? inst['loan_id'] as int
        : int.tryParse(inst['loan_id'].toString()) ?? -1;
    instsByLoan.putIfAbsent(lid, () => []).add(inst);
  }

  final balances = <int, double>{};
  final aprs = <int, double>{};
  final minPayments = <int, double>{};
  final compounds = <int, int>{};
  final grace = <int, int>{};

  for (final entry in loanMap.entries) {
    final lid = entry.key;
    final loan = entry.value;
    final insts = instsByLoan[lid] ?? [];
    var bal = 0;
    for (final i in insts) {
      final status = i['status'] as String? ?? '';
      if (status != 'paid') {
        bal +=
            (i['amount'] as int? ?? int.tryParse(i['amount'].toString()) ?? 0);
      }
    }
    balances[lid] = bal.toDouble();

    final apr = loan['interest_rate'] is num
        ? (loan['interest_rate'] as num).toDouble()
        : (loan['interest_rate'] is String
            ? double.tryParse(loan['interest_rate']) ?? 0.0
            : 0.0);
    aprs[lid] = apr;

    final mp = loan['monthly_payment'] is int
        ? (loan['monthly_payment'] as int).toDouble()
        : (insts.isNotEmpty
            ? (insts.first['amount'] as int? ?? 0).toDouble()
            : 0.0);
    minPayments[lid] = mp > 0 ? mp : 0.0;

    final cf = (loan['compounding_frequency'] as String?) ?? 'monthly';
    final compCount = cf == 'daily'
        ? 365
        : (cf == 'quarterly' ? 4 : (cf == 'yearly' ? 1 : 12));
    compounds[lid] = compCount;

    final gp = loan['grace_period_days'] is int
        ? loan['grace_period_days'] as int
        : (loan['grace_period_days'] != null
            ? int.tryParse(loan['grace_period_days'].toString()) ?? 0
            : 0);
    grace[lid] = gp;
  }

  // Simulation loop - month by month using Jalali months
  var nowJ = Jalali.now();
  final projections = <Map<String, dynamic>>[];

  double totalInterestAccrued = 0.0;

  int monthIndex = 0;
  const maxMonths = 600; // safety cap ~50 years

  double totalBalance() => balances.values.fold(0.0, (a, b) => a + b);

  while (totalBalance() > 0.5 && monthIndex < maxMonths) {
    final targetMonth = nowJ.month + monthIndex;
    var year = nowJ.year;
    var month = targetMonth;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    final daysInMonth = Jalali(year, month, 1).monthLength;

    // Accrue interest for each loan
    double monthlyInterest = 0.0;
    for (final lid in balances.keys) {
      final bal = balances[lid]!;
      if (bal <= 0) continue;

      // respect grace period only for first month(s)
      if (grace[lid]! > 0 && monthIndex == 0) {
        continue;
      }

      final apr = aprs[lid]! / 100.0;
      final comp = compounds[lid]!;
      final dailyRate = (pow(1 + apr / comp, comp / 365.0) - 1);
      final interest = bal * (pow(1 + dailyRate, daysInMonth) - 1);
      balances[lid] = bal + interest;
      monthlyInterest += interest;
      totalInterestAccrued += interest;
    }

    // Determine payment pool: sum of mins + extra
    double totalMin = 0.0;
    for (final lid in balances.keys) {
      if (balances[lid]! > 0) totalMin += minPayments[lid]!;
    }
    var paymentPool =
        totalMin + (extraPayment != null ? extraPayment.toDouble() : 0.0);

    double paymentThisMonth = 0.0;

    // First pay minimums in loan id order
    for (final lid in balances.keys.toList()) {
      if (balances[lid]! <= 0) continue;
      final need = minPayments[lid]!;
      final pay = need <= paymentPool ? need : paymentPool;
      balances[lid] = (balances[lid]! - pay).clamp(0.0, double.infinity);
      paymentPool -= pay;
      paymentThisMonth += pay;
      if (paymentPool <= 0) break;
    }

    // Distribute remaining paymentPool per strategy
    if (paymentPool > 0) {
      if (strategy == 'snowball') {
        // target smallest positive balance
        final target = balances.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        if (target.isNotEmpty) {
          final lid = target.first.key;
          final pay =
              paymentPool <= balances[lid]! ? paymentPool : balances[lid]!;
          balances[lid] = (balances[lid]! - pay).clamp(0.0, double.infinity);
          paymentThisMonth += pay;
          paymentPool -= pay;
        }
      } else {
        // avalanche - highest APR first
        final target = balances.entries.where((e) => e.value > 0).toList()
          ..sort((a, b) => aprs[b.key]!.compareTo(aprs[a.key]!));
        if (target.isNotEmpty) {
          final lid = target.first.key;
          final pay =
              paymentPool <= balances[lid]! ? paymentPool : balances[lid]!;
          balances[lid] = (balances[lid]! - pay).clamp(0.0, double.infinity);
          paymentThisMonth += pay;
          paymentPool -= pay;
        }
      }
    }

    projections.add({
      'year': year,
      'month': month,
      'label': '$year/${month.toString().padLeft(2, '0')}',
      'totalBalance': totalBalance().round(),
      'monthlyInterest': monthlyInterest.round(),
      'totalInterestAccrued': totalInterestAccrued.round(),
      'payment': paymentThisMonth.round(),
      'extraPayment': extraPayment ?? 0,
    });

    // Next month
    monthIndex += 1;
  }

  return projections;
}

/// Compute spending by category across multiple months.
/// Returns a map where:
/// - Keys: category names
/// - Values: lists of monthly spending (oldest to newest)
Map<String, List<int>> computeSpendingHeatmap(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> counterparties,
  List<Map<String, dynamic>> installments,
  int monthsBack,
  int nowYear,
  int nowMonth,
) {
  final cpMap = <int, Map<String, dynamic>>{};
  for (final cp in counterparties) {
    final id = cp['id'];
    if (id is int) cpMap[id] = cp;
  }

  final loanMap = <int, Map<String, dynamic>>{};
  for (final loan in loans) {
    final id = loan['id'];
    if (id is int) loanMap[id] = loan;
  }

  // Initialize categories with empty lists
  final heatmapData = <String, List<int>>{};

  // Iterate through months
  for (var i = monthsBack - 1; i >= 0; i--) {
    var targetYear = nowYear;
    var targetMonth = nowMonth - i;
    while (targetMonth <= 0) {
      targetMonth += 12;
      targetYear -= 1;
    }

    final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
    final mm = targetMonth.toString().padLeft(2, '0');
    final startDate = '$targetYear-$mm-01';
    final endDate = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';

    final monthCategoryTotals = <String, int>{};

    // Process installments for this month
    for (final inst in installments) {
      final status = inst['status'] as String? ?? '';
      final paidAt = inst['paid_at'] as String?;
      if (status != 'paid' || paidAt == null) continue;
      if (paidAt.compareTo(startDate) < 0 || paidAt.compareTo(endDate) > 0) {
        continue;
      }

      final loanId = inst['loan_id'] is int
          ? inst['loan_id'] as int
          : int.tryParse(inst['loan_id'].toString()) ?? -1;
      final loan = loanMap[loanId];
      if (loan == null) continue;

      final cpId = loan['counterparty_id'] is int
          ? loan['counterparty_id'] as int
          : int.tryParse(loan['counterparty_id'].toString()) ?? -1;
      final cp = cpMap[cpId];
      final category =
          (cp != null ? (cp['type'] ?? cp['tag']) : null) ?? 'سایر';

      final actual = inst['actual_paid_amount'] is int
          ? inst['actual_paid_amount'] as int
          : (inst['amount'] is int
              ? inst['amount'] as int
              : int.tryParse(inst['amount'].toString()) ?? 0);

      monthCategoryTotals[category] =
          (monthCategoryTotals[category] ?? 0) + actual;
    }

    // Add monthly totals to heatmap
    final allCategories = <String>{
      ...monthCategoryTotals.keys,
      ...heatmapData.keys
    };
    for (final category in allCategories) {
      heatmapData.putIfAbsent(category, () => []);
      heatmapData[category]!.add(monthCategoryTotals[category] ?? 0);
    }
  }

  // Ensure all categories have the same length
  final maxLength = monthsBack;
  for (final category in heatmapData.keys) {
    while (heatmapData[category]!.length < maxLength) {
      heatmapData[category]!.insert(0, 0);
    }
  }

  return heatmapData;
}

/// Adapter for compute() which requires a single message argument.
Map<String, List<int>> spendingHeatmapEntry(Map<String, dynamic> input) {
  return computeSpendingHeatmap(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['cps'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['monthsBack'] as int,
    input['nowYear'] as int,
    input['nowMonth'] as int,
  );
}
