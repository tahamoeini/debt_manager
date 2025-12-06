import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/budget/models/budget.dart';

class BudgetsRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insertBudget(Budget budget) async {
    final db = await _db.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> updateBudget(Budget budget) async {
    if (budget.id == null) throw ArgumentError('Budget.id is null');
    final db = await _db.database;
    return await db.update('budgets', budget.toMap(), where: 'id = ?', whereArgs: [budget.id]);
  }

  Future<int> deleteBudget(int id) async {
    final db = await _db.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> getBudgetsByPeriod(String period) async {
    final db = await _db.database;
    final rows = await db.query('budgets', where: 'period = ?', whereArgs: [period], orderBy: 'category ASC');
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  Future<Budget?> getBudgetById(int id) async {
    final db = await _db.database;
    final rows = await db.query('budgets', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<List<Budget>> getAllBudgets() async {
    final db = await _db.database;
    final rows = await db.query('budgets', orderBy: 'period DESC, category ASC');
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  /// Placeholder: computes utilization for a budget as 0 for now.
  /// Later: sum transactions/payments in the budget.category and period.
  Future<int> computeUtilization(Budget budget) async {
    // TODO: implement by summing transaction amounts for category and period
    return 0;
  }
}
