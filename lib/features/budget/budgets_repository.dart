import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/budget/models/budget_entry.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';

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
      final rows = _budgetEntryStore
          .where((r) => r['period'] == period)
          .toList()
        ..sort((a, b) =>
            (a['category'] as String?)
                ?.compareTo((b['category'] as String?) ?? '') ??
            0);
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
        ..sort((a, b) =>
            (a['category'] as String?)
                ?.compareTo((b['category'] as String?) ?? '') ??
            0);
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
          return (a['category'] as String?)
                  ?.compareTo((b['category'] as String?) ?? '') ??
              0;
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

      // If no category, just sum all expense (negative) ledger entries in range.
      if (budget.category == null) {
        final entries = await _db.getLedgerEntriesBetween(start, end);
        final total = entries.where((e) => e.amount < 0).fold<int>(
              0,
              (sum, e) => sum + (-e.amount),
            );
        return total;
      }

      final cat = budget.category!.trim();
      if (cat.isEmpty) return 0;

      if (_isWeb) {
        final entries = await _db.getLedgerEntriesBetween(start, end);
        final loans = await DatabaseHelper.instance.getAllLoans();
        final cps = await DatabaseHelper.instance.getAllCounterparties();
        final Map<int, Loan> loanById = {
          for (final l in loans.where((l) => l.id != null)) l.id!: l,
        };
        final Map<int, Counterparty> cpById = {
          for (final c in cps.where((c) => c.id != null)) c.id!: c,
        };

        final installmentById = <int, Installment>{};
        for (final loan in loans) {
          if (loan.id == null) continue;
          final list =
              await DatabaseHelper.instance.getInstallmentsByLoanId(loan.id!);
          for (final inst in list) {
            if (inst.id != null) installmentById[inst.id!] = inst;
          }
        }

        int total = 0;
        for (final e in entries) {
          if (e.amount >= 0) continue;
          if (e.refType == 'installment_payment' && e.refId != null) {
            final inst = installmentById[e.refId!];
            if (inst == null) continue;
            final loan = loanById[inst.loanId];
            final matches = _matchesCategory(
              cat,
              loan,
              cpById[loan?.counterpartyId ?? -1],
            );
            if (matches) total += -e.amount;
          } else {
            if ((e.note ?? '').contains(cat)) {
              total += -e.amount;
            }
          }
        }
        return total;
      }

      final db = await _db.database;
      final like = '%$cat%';
      final rows = await db.rawQuery(
        '''
        SELECT COALESCE(SUM(-le.amount), 0) as total
        FROM ledger_entries le
        LEFT JOIN installments i ON le.ref_type = 'installment_payment' AND le.ref_id = i.id
        LEFT JOIN loans l ON i.loan_id = l.id
        LEFT JOIN counterparties c ON l.counterparty_id = c.id
        WHERE le.amount < 0 AND le.date_jalali BETWEEN ? AND ?
          AND (
            (le.ref_type = 'installment_payment' AND (c.tag = ? OR l.title = ? OR (l.notes IS NOT NULL AND l.notes LIKE ?)))
            OR (le.ref_type != 'installment_payment' AND le.note IS NOT NULL AND le.note LIKE ?)
          )
      ''',
        [start, end, cat, cat, like, like],
      );

      final value = rows.first['total'];
      final actual = (value is int)
          ? value
          : (value is String ? int.tryParse(value) ?? 0 : 0);
      return actual;
    } catch (_) {
      return 0;
    }
  }

  bool _matchesCategory(String cat, Loan? loan, Counterparty? cp) {
    if (loan == null) return false;
    final tag = cp?.tag;
    return (tag == cat) ||
        loan.title == cat ||
        (loan.notes?.contains(cat) ?? false);
  }
}

// Provider for injecting the repository into widgets/notifiers.
final budgetsRepositoryProvider = Provider<BudgetsRepository>((ref) {
  return BudgetsRepository();
});
