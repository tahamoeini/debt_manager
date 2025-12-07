// Reports repository: compute analytics and insights for the reports screen
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

class ReportsRepository {
  final _db = DatabaseHelper.instance;

  /// Get spending by category (counterparty type) for a given month
  /// Returns a map of category name to total amount spent
  Future<Map<String, int>> getSpendingByCategory(int year, int month) async {
    await _db.refreshOverdueInstallments(DateTime.now());
    
    final lastDay = Jalali(year, month, 1).monthLength;
    final mm = month.toString().padLeft(2, '0');
    final startDate = '$year-$mm-01';
    final endDate = '$year-$mm-${lastDay.toString().padLeft(2, '0')}';

    final loans = await _db.getAllLoans(direction: LoanDirection.borrowed);
    final counterparties = await _db.getAllCounterparties();
    
    final cpMap = <int, Counterparty>{};
    for (final cp in counterparties) {
      if (cp.id != null) cpMap[cp.id!] = cp;
    }

    final categoryTotals = <String, int>{};

    // Build a map from loanId to loan for quick lookup
    final loanMap = <int, Loan>{};
    for (final loan in loans) {
      if (loan.id != null) loanMap[loan.id!] = loan;
    }

    // Fetch all paid installments for borrowed loans in the date range
    final allInstallments = <Installment>[];
    for (final loanId in loanMap.keys) {
      final installments = await _db.getInstallmentsByLoanId(loanId);
      // Filter by date range and status
      allInstallments.addAll(installments.where((inst) =>
          inst.status == InstallmentStatus.paid &&
          inst.paidDate != null &&
          inst.paidDate!.compareTo(startDate) >= 0 &&
          inst.paidDate!.compareTo(endDate) <= 0));
    }

    for (final inst in allInstallments) {
      final loan = loanMap[inst.loanId];
      if (loan == null) continue;
      final cp = cpMap[loan.counterpartyId];
      final category = cp?.type ?? cp?.tag ?? 'سایر';
      final amount = inst.actualPaidAmount ?? inst.amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount.toInt();
    }

    return categoryTotals;
  }

  /// Get total spending per month for the last N months
  /// Returns a list of maps with year, month, and amount
  Future<List<Map<String, dynamic>>> getSpendingOverTime(int monthsBack) async {
    await _db.refreshOverdueInstallments(DateTime.now());
    
    final now = DateTime.now();
    final nowJ = dateTimeToJalali(now);
    
    final results = <Map<String, dynamic>>[];
    
    for (var i = monthsBack - 1; i >= 0; i--) {
      final monthsAgo = i;
      var targetYear = nowJ.year;
      var targetMonth = nowJ.month - monthsAgo;
      
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      
      final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
      final mm = targetMonth.toString().padLeft(2, '0');
      final startDate = '$targetYear-$mm-01';
      final endDate = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';
      
      // Calculate spending (borrowed payments) and income (lent payments)
      final borrowed = await _getTotalPaidInRange(startDate, endDate, LoanDirection.borrowed);
      final lent = await _getTotalPaidInRange(startDate, endDate, LoanDirection.lent);
      
      results.add({
        'year': targetYear,
        'month': targetMonth,
        'label': '$targetYear/${mm}',
        'spending': borrowed,
        'income': lent,
        'net': lent - borrowed,
      });
    }
    
    return results;
  }

  Future<int> _getTotalPaidInRange(String startDate, String endDate, LoanDirection direction) async {
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
    
    final results = <Map<String, dynamic>>[];
    
    for (var i = monthsBack - 1; i >= 0; i--) {
      final monthsAgo = i;
      var targetYear = nowJ.year;
      var targetMonth = nowJ.month - monthsAgo;
      
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      
      final lastDay = Jalali(targetYear, targetMonth, 1).monthLength;
      final mm = targetMonth.toString().padLeft(2, '0');
      final endDate = '$targetYear-$mm-${lastDay.toString().padLeft(2, '0')}';
      
      // Calculate outstanding amounts as of end of that month
      final assets = await _getOutstandingAsOfDate(endDate, LoanDirection.lent);
      final debts = await _getOutstandingAsOfDate(endDate, LoanDirection.borrowed);
      
      results.add({
        'year': targetYear,
        'month': targetMonth,
        'label': '$targetYear/${mm}',
        'assets': assets,
        'debts': debts,
        'netWorth': assets - debts,
      });
    }
    
    return results;
  }

  Future<int> _getOutstandingAsOfDate(String asOfDate, LoanDirection direction) async {
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
  Future<List<Map<String, dynamic>>> projectDebtPayoff(int loanId, {int? extraPayment}) async {
    final loan = await _db.getLoanById(loanId);
    if (loan == null) return [];
    
    final installments = await _db.getInstallmentsByLoanId(loanId);
    
    // Sort by due date
    installments.sort((a, b) => a.dueDateJalali.compareTo(b.dueDateJalali));
    
    final projections = <Map<String, dynamic>>[];
    var balance = 0;
    
    // Calculate initial balance (unpaid installments)
    for (final inst in installments) {
      if (inst.status != InstallmentStatus.paid) {
        balance += inst.amount;
      }
    }
    
    final now = DateTime.now();
    final nowJ = dateTimeToJalali(now);
    
    for (final inst in installments) {
      if (inst.status == InstallmentStatus.paid) continue;
      
      final dueJ = parseJalali(inst.dueDateJalali);
      
      var payment = inst.amount;
      if (extraPayment != null && extraPayment > 0) {
        payment += extraPayment;
      }
      
      balance -= payment;
      if (balance < 0) balance = 0;
      
      projections.add({
        'year': dueJ.year,
        'month': dueJ.month,
        'label': '${dueJ.year}/${dueJ.month.toString().padLeft(2, '0')}',
        'balance': balance,
        'payment': inst.amount,
        'extraPayment': extraPayment ?? 0,
      });
      
      if (balance == 0) break;
    }
    
    return projections;
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
        insights.add('این ماه ${(diff / 10000).toStringAsFixed(0)} هزار تومان بیشتر از ماه گذشته هزینه کرده‌اید.');
      } else if (diff < 0) {
        insights.add('این ماه ${((-diff) / 10000).toStringAsFixed(0)} هزار تومان کمتر از ماه گذشته هزینه کرده‌اید. پیشرفت خوبی است!');
      }
    }
    
    // Top categories
    if (thisMonthData.isNotEmpty) {
      final entries = thisMonthData.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      if (entries.isNotEmpty && thisTotal > 0) {
        final topCategory = entries.first;
        final percentage = ((topCategory.value / thisTotal) * 100).round();
        insights.add('${percentage}% از هزینه‌های شما در دسته ${topCategory.key} بوده است.');
      }
    }
    
    // Outstanding debt check
    final borrowed = await _db.getTotalOutstandingBorrowed();
    final lent = await _db.getTotalOutstandingLent();
    
    if (borrowed > lent) {
      insights.add('بدهی شما بیشتر از طلب است. سعی کنید بدهی‌های خود را کاهش دهید.');
    } else if (lent > borrowed) {
      insights.add('طلب شما بیشتر از بدهی است. وضعیت مالی خوبی دارید!');
    }
    
    return insights;
  }
}
