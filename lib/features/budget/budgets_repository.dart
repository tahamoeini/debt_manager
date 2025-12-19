import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/budget/models/budget_entry.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:debt_manager/features/loans/models/counterparty.dart';

// In-memory fallback stores for web where `sqflite` is unavailable.
// These are kept per-repository instance and are intentionally simple.

class BudgetsRepository {
  final _db = DatabaseHelper.instance;
  final bool _isWeb = kIsWeb;
  final List<Map<String, dynamic>> _budgetStore = [];
  final List<Map<String, dynamic>> _budgetEntryStore = [];
  int _budgetId = 0;
  int _budgetEntryId = 0;

  Future<int> insertBudget(Budget budget) async {
    if (_isWeb) {
      _budgetId++;
      final map = budget.toMap();
      map['id'] = _budgetId;
      _budgetStore.add(map);
      return _budgetId;
    }

    final db = await _db.database;
    return await db.insert('budgets', budget.toMap());
  }

  Future<int> insertBudgetEntry(BudgetEntry entry) async {
    if (_isWeb) {
      _budgetEntryId++;
      final map = entry.toMap();
      map['id'] = _budgetEntryId;
      _budgetEntryStore.add(map);
      return _budgetEntryId;
    }

    final db = await _db.database;
    return await db.insert('budget_entries', entry.toMap());
  }

  Future<int> updateBudgetEntry(BudgetEntry entry) async {
    if (entry.id == null) throw ArgumentError('BudgetEntry.id is null');
    final db = await _db.database;
    return await db.update(
      'budget_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> deleteBudgetEntry(int id) async {
    final db = await _db.database;
    return await db.delete('budget_entries', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BudgetEntry>> getBudgetEntriesByPeriod(String period) async {
    if (_isWeb) {
      final rows = _budgetEntryStore.where((r) => r['period'] == period).toList()
        ..sort((a, b) => (a['category'] as String?)?.compareTo((b['category'] as String?) ?? '') ?? 0);
      return rows.map((r) => BudgetEntry.fromMap(r)).toList();
    }

    final db = await _db.database;
    final rows = await db.query(
      'budget_entries',
      where: 'period = ?',
      whereArgs: [period],
      orderBy: 'category ASC',
    );
    return rows.map((r) => BudgetEntry.fromMap(r)).toList();
  }

  Future<BudgetEntry?> getOverrideForCategoryPeriod(
    String? category,
    String period,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'budget_entries',
      where: 'period = ? AND is_one_off = 0 AND category IS ?',
      whereArgs: [period, category],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return BudgetEntry.fromMap(rows.first);
  }

  Future<int> updateBudget(Budget budget) async {
    if (budget.id == null) throw ArgumentError('Budget.id is null');
    if (_isWeb) {
      final idx = _budgetStore.indexWhere((r) => r['id'] == budget.id);
      if (idx == -1) throw ArgumentError('Budget not found');
      _budgetStore[idx] = budget.toMap();
      return 1;
    }

    final db = await _db.database;
    return await db.update(
      'budgets',
      budget.toMap(),
      where: 'id = ?',
      whereArgs: [budget.id],
    );
  }

  Future<int> deleteBudget(int id) async {
    if (_isWeb) {
      _budgetStore.removeWhere((r) => r['id'] == id);
      return 1;
    }

    final db = await _db.database;
    return await db.delete('budgets', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Budget>> getBudgetsByPeriod(String period) async {
    if (_isWeb) {
      final rows = _budgetStore.where((r) => r['period'] == period).toList()
        ..sort((a, b) => (a['category'] as String?)?.compareTo((b['category'] as String?) ?? '') ?? 0);
      return rows.map((r) => Budget.fromMap(r)).toList();
    }

    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      where: 'period = ?',
      whereArgs: [period],
      orderBy: 'category ASC',
    );
    return rows.map((r) => Budget.fromMap(r)).toList();
  }

  Future<Budget?> getBudgetById(int id) async {
    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Budget.fromMap(rows.first);
  }

  Future<List<Budget>> getAllBudgets() async {
    if (_isWeb) {
      final rows = List<Map<String, dynamic>>.from(_budgetStore)
        ..sort((a, b) {
          final p = (b['period'] as String).compareTo(a['period'] as String);
          if (p != 0) return p;
          return (a['category'] as String?)?.compareTo((b['category'] as String?) ?? '') ?? 0;
        });
      return rows.map((r) => Budget.fromMap(r)).toList();
    }

    final db = await _db.database;
    final rows = await db.query(
      'budgets',
      orderBy: 'period DESC, category ASC',
    );
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
      if (_isWeb) {
        // Web: fall back to in-memory transaction scanning where possible.
        // Iterate loans/installments and prefer transaction amounts when present.
        final loans = await DatabaseHelper.instance.getAllLoans();
        final cps = await DatabaseHelper.instance.getAllCounterparties();
        int total = 0;
        for (final loan in loans) {
          final insts = await DatabaseHelper.instance.getInstallmentsByLoanId(loan.id ?? -1);
          for (final i in insts) {
            final paidAt = i.paidAt;
            if (paidAt == null) continue;
            if (paidAt.compareTo(start) < 0 || paidAt.compareTo(end) > 0) continue;
            // Prefer transaction record if one exists for this installment
            final txns = await DatabaseHelper.instance.getTransactionsByRelated('installment', i.id ?? -1);
            final debitTxn = txns.firstWhere(
              (t) => (t['direction'] as String?) == 'debit',
              orElse: () => {},
            );
            if (debitTxn is Map && debitTxn.isNotEmpty) {
              final amt = debitTxn['amount'];
              total += (amt is int) ? amt : int.tryParse('$amt') ?? 0;
              continue;
            }

            if (budget.category == null) {
              total += i.actualPaidAmount ?? i.amount;
            } else {
              final cat = budget.category!.trim();
              if (cat.isEmpty) continue;
              final cp = cps.firstWhere(
                (c) => c.id == loan.counterpartyId,
                orElse: () => const Counterparty(id: null, name: ''),
              );
              final tag = cp.tag;
              final matches = (tag == cat) || loan.title == cat || (loan.notes?.contains(cat) ?? false);
              if (matches) total += i.actualPaidAmount ?? i.amount;
            }
          }
        }
        return total;
      }

      final db = await _db.database;

      // No-op: per-month overrides not used in current utilization calculation

      // Use transactions table to compute utilization for native DB for accuracy.
      if (budget.category == null) {
        final rows = await db.rawQuery(
          '''
          SELECT COALESCE(SUM(CASE WHEN direction = 'debit' THEN amount ELSE 0 END), 0) as total
          FROM transactions
          WHERE SUBSTR(timestamp, 1, 10) BETWEEN ? AND ?
            AND related_type = 'installment'
        ''',
          [start, end],
        );

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
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(CASE WHEN t.direction = 'debit' THEN t.amount ELSE 0 END), 0) as total
        FROM transactions t
        LEFT JOIN installments i ON t.related_type = 'installment' AND t.related_id = i.id
        LEFT JOIN loans l ON i.loan_id = l.id
        LEFT JOIN counterparties c ON l.counterparty_id = c.id
        WHERE SUBSTR(t.timestamp,1,10) BETWEEN ? AND ?
          AND (c.tag = ? OR l.title = ? OR (l.notes IS NOT NULL AND l.notes LIKE ?))
      ''',
        [start, end, cat, cat, like],
      );

      final value = rows.first['total'];
      final actual = (value is int)
          ? value
          : (value is String ? int.tryParse(value) ?? 0 : 0);
      // If rollover is enabled and there's a rollover entry from previous month, reduce the effective budget
      if (budget.rollover) {
        // Find previous period entries marked as one-off negative (unused rollovers are stored as budget_entries with negative amount)
        // For now, if an override exists, it's already taken as effectiveAmount. Rollover handling would require tracking unused amount; keep simple: no-op here.
      }

      return actual;
    } catch (_) {
      return 0;
    }
  }
}

// Provider for injecting the repository into widgets/notifiers.
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});
