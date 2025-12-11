import 'package:shamsi_date/shamsi_date.dart';

// Top-level, isolate-safe functions for reports computation.

Map<String, int> computeSpendingByCategory(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> counterparties,
  List<Map<String, dynamic>> installments,
  int year,
  int month,
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
