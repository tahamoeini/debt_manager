import 'package:sqflite/sqflite.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';

// Data Access Object for `installments` related SQL operations.
// All methods are written to accept an already-open `Database` instance
// so callers can control transaction boundaries and initialization.
class InstallmentDao {
  InstallmentDao._();

  static Future<int> insertInstallment(
      Database db, Installment installment) async {
    return await db.insert('installments', installment.toMap());
  }

  static Future<int> updateInstallment(
      Database db, Installment installment) async {
    if (installment.id == null) throw ArgumentError('Installment.id is null');
    return await db.update(
      'installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
  }

  static Future<int> deleteInstallmentsByLoanId(Database db, int loanId) async {
    return await db.delete(
      'installments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
  }

  static Future<List<Installment>> getInstallmentsByLoanId(
      Database db, int loanId) async {
    final rows = await db.query(
      'installments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'due_date_jalali ASC',
    );
    try {
      return rows.map((r) => Installment.fromMap(r)).toList();
    } catch (_) {
      // Defensive: return empty list if parsing fails for any row
      return [];
    }
  }

  static Future<Map<int, List<Installment>>> getInstallmentsGroupedByLoanId(
      Database db, List<int> loanIds) async {
    if (loanIds.isEmpty) return {};
    final placeholders = List.filled(loanIds.length, '?').join(', ');
    final rows = await db.query(
      'installments',
      where: 'loan_id IN ($placeholders)',
      whereArgs: loanIds,
      orderBy: 'loan_id ASC, due_date_jalali ASC',
    );

    final Map<int, List<Installment>> map = {};
    for (final r in rows) {
      final lid = r['loan_id'] is int
          ? r['loan_id'] as int
          : int.parse(r['loan_id'].toString());
      map.putIfAbsent(lid, () => []).add(Installment.fromMap(r));
    }

    return map;
  }

  // Returns installments that are overdue based on the provided [now]
  // (Gregorian). The method internally converts to Jalali strings and
  // returns mapped [Installment] objects; callers don't need to handle
  // raw Jalali strings.
  static Future<List<Installment>> getOverdueInstallments(
      Database db, DateTime now) async {
    final todayJ = dateTimeToJalali(now);
    final todayStr = formatJalali(todayJ);

    // Fetch installments which are either explicitly marked 'overdue' or
    // are still 'pending' but have due dates in the past.
    final rows = await db.rawQuery('''
      SELECT * FROM installments
      WHERE status = 'overdue' OR (status = 'pending' AND due_date_jalali < ?)
      ORDER BY due_date_jalali ASC
    ''', [todayStr]);

    return rows.map((r) => Installment.fromMap(r)).toList();
  }

  // Returns upcoming installments between [from] and [to] (inclusive).
  // Input is Gregorian DateTimes; conversion to Jalali is handled internally.
  static Future<List<Installment>> getUpcomingInstallments(
      Database db, DateTime from, DateTime to) async {
    final fromJ = dateTimeToJalali(from);
    final toJ = dateTimeToJalali(to);
    final fromStr = formatJalali(fromJ);
    final toStr = formatJalali(toJ);

    final rows = await db.query(
      'installments',
      where: "status = ? AND due_date_jalali BETWEEN ? AND ?",
      whereArgs: ['pending', fromStr, toStr],
      orderBy: 'due_date_jalali ASC',
    );

    return rows.map((r) => Installment.fromMap(r)).toList();
  }

  // Update installments that are overdue based on [now] and return the
  // number of rows affected. This performs the same update that used to
  // live in `DatabaseHelper.refreshOverdueInstallments`.
  static Future<int> refreshOverdueInstallments(
      Database db, DateTime now) async {
    final todayJ = dateTimeToJalali(now);
    final todayStr = formatJalali(todayJ);
    final result = await db.rawUpdate(
      "UPDATE installments SET status = 'overdue' WHERE status = 'pending' AND due_date_jalali < ?",
      [todayStr],
    );
    return result;
  }
}
