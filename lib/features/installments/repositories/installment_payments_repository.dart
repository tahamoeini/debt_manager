import 'package:shamsi_date/shamsi_date.dart';
import '../models/installment_payment.dart';
import '../../accounts/models/account.dart';
import '../../../core/db/database_helper.dart';

class InstallmentPaymentsRepository {
  final DatabaseHelper _db;

  InstallmentPaymentsRepository(this._db);

  /// Get all payments for a loan
  Future<List<InstallmentPayment>> getPaymentsByLoan(int loanId) async {
    final database = await _db.database;
    final results = await database.query(
      'installment_payments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
      orderBy: 'due_date ASC',
    );

    return results.map(_mapRowToPayment).toList();
  }

  /// Get payment by ID
  Future<InstallmentPayment?> getPaymentById(int id) async {
    final database = await _db.database;
    final results = await database.query(
      'installment_payments',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return _mapRowToPayment(results.first);
  }

  /// Record a payment
  Future<int> recordPayment({
    required int loanId,
    required int installmentId,
    required int accountId,
    required double amount,
    required Jalali paidDate,
    String? notes,
  }) async {
    final database = await _db.database;
    final now = DateTime.now().toIso8601String();

    return await database.insert('installment_payments', {
      'loan_id': loanId,
      'installment_id': installmentId,
      'account_id': accountId,
      'amount': amount.toInt(),
      'paid_date': paidDate.toString(),
      'amount_paid': amount.toInt(),
      'status': PaymentStatus.paid.index,
      'notes': notes,
      'created_at': now,
    });
  }

  /// Update payment status
  Future<void> updatePaymentStatus(
    int paymentId,
    PaymentStatus status,
    double amountPaid,
  ) async {
    final database = await _db.database;
    await database.update(
      'installment_payments',
      {
        'status': status.index,
        'amount_paid': amountPaid.toInt(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  /// Mark payment as fully paid
  Future<void> markAsPaid(int paymentId, Jalali paidDate) async {
    final database = await _db.database;
    final payment = await getPaymentById(paymentId);
    if (payment == null) return;

    await database.update(
      'installment_payments',
      {
        'status': PaymentStatus.paid.index,
        'amount_paid': payment.amount.toInt(),
        'paid_date': paidDate.toString(),
      },
      where: 'id = ?',
      whereArgs: [paymentId],
    );
  }

  /// Get upcoming payments (within 30 days)
  Future<List<InstallmentPayment>> getUpcomingPayments() async {
    final database = await _db.database;
    final today = Jalali.now();
    final thirtyDaysLater = today.addDays(30);

    final results = await database.query(
      'installment_payments',
      where: 'due_date BETWEEN ? AND ? AND status != ?',
      whereArgs: [today.toString(), thirtyDaysLater.toString(), PaymentStatus.paid.index],
      orderBy: 'due_date ASC',
    );

    return results.map(_mapRowToPayment).toList();
  }

  /// Get overdue payments
  Future<List<InstallmentPayment>> getOverduePayments() async {
    final database = await _db.database;
    final today = Jalali.now();

    final results = await database.query(
      'installment_payments',
      where: 'due_date < ? AND status != ?',
      whereArgs: [today.toString(), PaymentStatus.paid.index],
      orderBy: 'due_date ASC',
    );

    return results.map(_mapRowToPayment).toList();
  }

  InstallmentPayment _mapRowToPayment(Map<String, dynamic> row) {
    return InstallmentPayment(
      id: row['id'] as int,
      installmentId: row['installment_id'] as int,
      loanId: row['loan_id'] as int,
      accountId: row['account_id'] as int,
      amount: (row['amount'] as num).toDouble(),
      dueDate: Jalali.parse(row['due_date'] as String),
      paidDate: row['paid_date'] != null
          ? Jalali.parse(row['paid_date'] as String)
          : null,
      amountPaid: (row['amount_paid'] as num).toDouble(),
      status: PaymentStatus.values[row['status'] as int],
      notes: row['notes'] as String?,
      createdAt: row['created_at'] as String,
    );
  }
}
