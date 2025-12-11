// Reports repository: compute analytics and insights for the reports screen
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:debt_manager/core/compute/reports_compute.dart';
import 'package:debt_manager/core/providers/core_providers.dart';

/// ReportsRepository can optionally accept a Riverpod ref to store cached results.
class ReportsRepository {
  ReportsRepository([this._ref]);

  // Accept a dynamic ref to avoid tight coupling with a specific Riverpod
  // ref type in contexts where this repository is constructed directly.
  final dynamic _ref;

  final _db = DatabaseHelper.instance;

  Future<List<Counterparty>> getAllCounterparties() => _db.getAllCounterparties();

  Future<void> refreshOverdueInstallments(DateTime now) => _db.refreshOverdueInstallments(now);

  Future<int> getTotalOutstandingBorrowed() => _db.getTotalOutstandingBorrowed();

  Future<int> getTotalOutstandingLent() => _db.getTotalOutstandingLent();

  Future<List<Loan>> getAllLoans({LoanDirection? direction}) => _db.getAllLoans(direction: direction);

  Future<List<Installment>> getInstallmentsByLoanId(int loanId) => _db.getInstallmentsByLoanId(loanId);

  /// Get spending by category (counterparty type) for a given month
  /// Returns a map of category name to total amount spent
  Future<Map<String, int>> getSpendingByCategory(int year, int month) async {
    await _db.refreshOverdueInstallments(DateTime.now());

    // Fetch loans, counterparties and installments in bulk, then run heavy
    // computation in an isolate via compute(). We pass plain Maps to the
    // isolate function.
    final loans = await _db.getAllLoans(direction: LoanDirection.borrowed);
    final counterparties = await _db.getAllCounterparties();

    final loanIds = loans.map((e) => e.id).whereType<int>().toList();
    final grouped = loanIds.isNotEmpty
        ? await _db.getInstallmentsGroupedByLoanId(loanIds)
        : <int, List<Installment>>{};
    final allInstallments = grouped.values.expand((l) => l).toList();

    final loansMaps = loans.map((l) => l.toMap()).toList();
    final cpMaps = counterparties.map((c) => c.toMap()).toList();
    final instMaps = allInstallments.map((i) => i.toMap()).toList();

    // Try cache when Riverpod ref is available
    final cacheKey =
        'spendingByCategory:$year-${month.toString().padLeft(2, '0')}';
    if (_ref != null) {
      final cached = _ref!
          .read(reportsCacheProvider.notifier)
          .get<Map<String, int>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final res = await compute<Map<String, dynamic>, Map<String, int>>(
          spendingByCategoryEntry, {
        'loans': loansMaps,
        'cps': cpMaps,
        'insts': instMaps,
        'year': year,
        'month': month,
      });

      // Store in cache
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, res);
      }
      return res;
    } catch (e) {
      final fallback =
          computeSpendingByCategory(loansMaps, cpMaps, instMaps, year, month);
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, fallback);
      }
      return fallback;
    }
  }

  /// Get total spending per month for the last N months
  /// Returns a list of maps with year, month, and amount
  Future<List<Map<String, dynamic>>> getSpendingOverTime(int monthsBack) async {
    await _db.refreshOverdueInstallments(DateTime.now());

    final now = DateTime.now();
    final nowJ = dateTimeToJalali(now);

    final loans = await _db.getAllLoans();
    final loanIds = loans.map((e) => e.id).whereType<int>().toList();
    final grouped = loanIds.isNotEmpty
        ? await _db.getInstallmentsGroupedByLoanId(loanIds)
        : <int, List<Installment>>{};
    final allInstallments = grouped.values.expand((l) => l).toList();

    final loanMaps = loans.map((l) => l.toMap()).toList();
    final instMaps = allInstallments.map((i) => i.toMap()).toList();

    final cacheKey =
        'spendingOverTime:months=$monthsBack:now=${nowJ.year}-${nowJ.month}';
    if (_ref != null) {
      final cached = _ref!
          .read(reportsCacheProvider.notifier)
          .get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final res =
          await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
        spendingOverTimeEntry,
        {
          'loans': loanMaps,
          'insts': instMaps,
          'monthsBack': monthsBack,
          'nowYear': nowJ.year,
          'nowMonth': nowJ.month,
        },
      );
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, res);
      }
      return res;
    } catch (e) {
      final fallback = computeSpendingOverTime(
          loanMaps, instMaps, monthsBack, nowJ.year, nowJ.month);
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, fallback);
      }
      return fallback;
    }
  }

  // ignore: unused_element
  Future<int> _getTotalPaidInRange(
      String startDate, String endDate, LoanDirection direction) async {
    // Fetch all paid installments for loans with the given direction and paidAt in range
    final db = await _db.database;
    final directionValue = direction.index; // assuming LoanDirection is an enum
    final List<Map<String, dynamic>> rows = await db.rawQuery('''
      SELECT i.actualPaidAmount, i.amount
      FROM installments i
      JOIN loans l ON i.loanId = l.id
      WHERE l.direction = ?
        AND i.status = ?
        AND i.paidAt IS NOT NULL
        AND i.paidAt >= ?
        AND i.paidAt <= ?
    ''', [
      directionValue,
      InstallmentStatus.paid.index,
      startDate,
      endDate,
    ]);

    int total = 0;
    for (final row in rows) {
      final actualPaidAmount = row['actualPaidAmount'] as int?;
      final amount = row['amount'] as int;
      total += actualPaidAmount ?? amount;
    }
    return total;
  }

  /// Get net worth over time (monthly snapshots for the last N months)
  /// Net worth = total assets (lent) - total debts (borrowed)
  Future<List<Map<String, dynamic>>> getNetWorthOverTime(int monthsBack) async {
    await _db.refreshOverdueInstallments(DateTime.now());

    final now = DateTime.now();
    final nowJ = dateTimeToJalali(now);

    final loans = await _db.getAllLoans();
    final loanIds = loans.map((e) => e.id).whereType<int>().toList();
    final grouped = loanIds.isNotEmpty
        ? await _db.getInstallmentsGroupedByLoanId(loanIds)
        : <int, List<Installment>>{};
    final allInstallments = grouped.values.expand((l) => l).toList();

    final loanMaps = loans.map((l) => l.toMap()).toList();
    final instMaps = allInstallments.map((i) => i.toMap()).toList();

    final cacheKey =
        'netWorthOverTime:months=$monthsBack:now=${nowJ.year}-${nowJ.month}';
    if (_ref != null) {
      final cached = _ref!
          .read(reportsCacheProvider.notifier)
          .get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final res =
          await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
        netWorthOverTimeEntry,
        {
          'loans': loanMaps,
          'insts': instMaps,
          'monthsBack': monthsBack,
          'nowYear': nowJ.year,
          'nowMonth': nowJ.month,
        },
      );
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, res);
      }
      return res;
    } catch (e) {
      final fallback = computeNetWorthOverTime(
          loanMaps, instMaps, monthsBack, nowJ.year, nowJ.month);
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, fallback);
      }
      return fallback;
    }
  }

  // ignore: unused_element
  Future<int> _getOutstandingAsOfDate(
      String asOfDate, LoanDirection direction) async {
    final loans = await _db.getAllLoans(direction: direction);
    var total = 0;

    for (final loan in loans) {
      if (loan.id == null) continue;

      final installments = await _db.getInstallmentsByLoanId(loan.id!);

      for (final inst in installments) {
        // Only count installments that were due on or before the date
        if (inst.dueDateJalali.compareTo(asOfDate) > 0) continue;

        // If not paid or paid after the date, count as outstanding
        if (inst.status != InstallmentStatus.paid ||
            (inst.paidAt != null && inst.paidAt!.compareTo(asOfDate) > 0)) {
          total += inst.amount;
        }
      }
    }

    return total;
  }

  /// Project debt payoff for a specific loan
  /// Returns monthly balance projections
  Future<List<Map<String, dynamic>>> projectDebtPayoff(int loanId,
      {int? extraPayment}) async {
    final loan = await _db.getLoanById(loanId);
    if (loan == null) return [];
    final installments = await _db.getInstallmentsByLoanId(loanId);
    final instMaps = installments.map((i) => i.toMap()).toList();
    final loanMap = loan.toMap();

    final cacheKey =
        'projectDebtPayoff:loan=$loanId:extra=${extraPayment ?? 0}';

    try {
      final res =
          await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
        projectDebtPayoffEntry,
        {
          'loan': loanMap,
          'insts': instMaps,
          'extraPayment': extraPayment,
        },
      );
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, res);
      }
      return res;
    } catch (e) {
      final fallback =
          computeProjectDebtPayoff(loanMap, instMaps, extraPayment);
      if (_ref != null) {
        _ref!.read(reportsCacheProvider.notifier).put(cacheKey, fallback);
      }
      return fallback;
    }
  }

  /// Generate insights for the current month
  Future<List<String>> generateMonthlyInsights() async {
    final insights = <String>[];

    final now = DateTime.now();
    final nowJ = dateTimeToJalali(now);
    final thisYear = nowJ.year;
    final thisMonth = nowJ.month;

    // Get this month and last month data
    final thisMonthData = await getSpendingByCategory(thisYear, thisMonth);

    var lastYear = thisYear;
    var lastMonth = thisMonth - 1;
    if (lastMonth <= 0) {
      lastMonth += 12;
      lastYear -= 1;
    }
    final lastMonthData = await getSpendingByCategory(lastYear, lastMonth);

    // Total spending comparison
    final thisTotal = thisMonthData.values.fold<int>(0, (sum, v) => sum + v);
    final lastTotal = lastMonthData.values.fold<int>(0, (sum, v) => sum + v);

    if (thisTotal > 0 && lastTotal > 0) {
      final diff = thisTotal - lastTotal;
      if (diff > 0) {
        insights.add(
            'این ماه ${(diff / 10000).toStringAsFixed(0)} هزار تومان بیشتر از ماه گذشته هزینه کرده‌اید.');
      } else if (diff < 0) {
        insights.add(
            'این ماه ${((-diff) / 10000).toStringAsFixed(0)} هزار تومان کمتر از ماه گذشته هزینه کرده‌اید. پیشرفت خوبی است!');
      }
    }

    // Top categories
    if (thisMonthData.isNotEmpty) {
      final entries = thisMonthData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      if (entries.isNotEmpty && thisTotal > 0) {
        final topCategory = entries.first;
        final percentage = ((topCategory.value / thisTotal) * 100).round();
        insights.add(
            '$percentage% از هزینه‌های شما در دسته ${topCategory.key} بوده است.');
      }
    }

    // Outstanding debt check
    final borrowed = await _db.getTotalOutstandingBorrowed();
    final lent = await _db.getTotalOutstandingLent();

    if (borrowed > lent) {
      insights.add(
          'بدهی شما بیشتر از طلب است. سعی کنید بدهی‌های خود را کاهش دهید.');
    } else if (lent > borrowed) {
      insights.add('طلب شما بیشتر از بدهی است. وضعیت مالی خوبی دارید!');
    }

    return insights;
  }
}
