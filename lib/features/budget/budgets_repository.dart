import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:shamsi_date/shamsi_date.dart';

class BudgetsRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insertBudget(Budget budget) async {
    final db = await _db.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(Budget budget) async {
    if (budget.id == null) throw ArgumentError('Budget.id is null');
    final db = await _db.database;
    return await db.update('budgets', budget.toMap(),
        where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await _db.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> getBudgetsByPeriod(String period) async {
    final db = await _db.database;
    final rows = await db.query('budgets',
        where: 'period = ?', whereArgs: [period], orderBy: 'category ASC');
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  Future<Budget?> getBudgetById(int id) async {
    final db = await _db.database;
    final rows =
        await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await _db.database;
    final rows =
        await db.query('budgets', orderBy: 'period DESC, category ASC');
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  // Placeholder: computes utilization for a budget as 0 for now.
  // Later: sum transactions/payments in the budget.category and period.
  Future<int> computeUtilization(Budget budget) async {
    try {
      final period = budget.period;
      final parts = period.split('-');
      if (parts.length != 2) return 0;
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      if (year == null || month == null) return 0;

      final lastDay = Jalali(year, month, 1).monthLength;
      final mm = month.toString().padLeft(2, '0');
      final start = '${parts[0]}-$mm-01';
      final end = '${parts[0]}-$mm-${lastDay.toString().padLeft(2, '0')}';

      final db = await _db.database;

      if (budget.category == null) {
        final rows = await db.rawQuery('''
          SELECT COALESCE(SUM(CASE WHEN actual_paid_amount IS NOT NULL THEN actual_paid_amount ELSE amount END), 0) as total
          FROM installments
          WHERE paid_at BETWEEN ? AND ?
        ''', [start, end]);

        final value = rows.first['total'];
        if (value is int) return value;
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      final cat = budget.category!.trim();
      if (cat.isEmpty) {
        return 0;
      }

      final like = '%$cat%';
      final rows = await db.rawQuery('''
        SELECT COALESCE(SUM(CASE WHEN i.actual_paid_amount IS NOT NULL THEN i.actual_paid_amount ELSE i.amount END), 0) as total
        FROM installments i
        JOIN loans l ON i.loan_id = l.id
        LEFT JOIN counterparties c ON l.counterparty_id = c.id
        WHERE i.paid_at BETWEEN ? AND ?
          AND (c.tag = ? OR l.title = ? OR (l.notes IS NOT NULL AND l.notes LIKE ?))
      ''', [start, end, cat, cat, like]);

      final value = rows.first['total'];
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

// Provider for injecting the repository into widgets/notifiers.
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});
