import 'package:debt_manager/core/db/database_helper.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:debt_manager/features/loans/models/loan.dart';

class IrregularIncomeService {
  final _db = DatabaseHelper.instance;

  /// Compute rolling average of income (loans with direction 'lent') over the
  /// last [months] months. Returns average in integer currency units.
  Future<int> computeRollingAverage(int months) async {
    final now = DateTime.now();
    final nowJ = Jalali.fromDateTime(now);

    var total = 0;
    var countedMonths = 0;

    for (var i = 0; i < months; i++) {
      var targetYear = nowJ.year;
      var targetMonth = nowJ.month - i;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
      final mm = targetMonth.toString().padLeft(2, '0');
      final start = '$targetYear-$mm-01';
      final end = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';

      if (kIsWeb) {
        // Web: use the in-memory stores via DatabaseHelper public APIs.
        final loans = await _db.getAllLoans();
        final lentLoans =
            loans.where((l) => l.direction == LoanDirection.lent).toList();
        int monthTotal = 0;
        for (final loan in lentLoans) {
          if (loan.id == null) continue;
          final insts = await _db.getInstallmentsByLoanId(loan.id!);
          for (final inst in insts) {
            final paidAt = inst.paidAtJalali;
            if (paidAt == null) continue;
            if (paidAt.compareTo(start) >= 0 && paidAt.compareTo(end) <= 0) {
              monthTotal += inst.actualPaidAmount ?? inst.amount;
            }
          }
        }
        total += monthTotal;
        countedMonths += 1;
      } else {
        final db = await _db.database;
        final rows = await db.rawQuery(
          '''
        SELECT COALESCE(SUM(CASE WHEN i.actual_paid_amount IS NOT NULL THEN i.actual_paid_amount ELSE i.amount END), 0) as total
        FROM installments i
        JOIN loans l ON i.loan_id = l.id
        LEFT JOIN income_profiles p ON l.counterparty_id = p.counterparty_id
        WHERE i.paid_at_jalali BETWEEN ? AND ?
          AND l.direction = 'lent'
          AND (p.mode IS NULL OR p.mode != 'fixed')
      ''',
          [start, end],
        );

        final value = rows.first['total'];
        final monthTotal = value is int
            ? value
            : (value is String ? int.tryParse(value) ?? 0 : 0);
        total += monthTotal;
        countedMonths += 1;
      }
    }

    if (countedMonths == 0) return 0;
    return (total / countedMonths).round();
  }

  /// Suggest a safe extra payment amount based on rolling [months] average
  /// and the provided monthly essential budget total. This is a conservative
  /// suggestion: max(0, rollingAvg - essentialBudget * safetyFactor).
  Future<int> suggestSafeExtra({
    int months = 3,
    required int essentialBudget,
    double safetyFactor = 1.2,
  }) async {
    final avg = await computeRollingAverage(months);
    final safe = (avg - (essentialBudget * safetyFactor)).round();
    return safe > 0 ? safe : 0;
  }
}
