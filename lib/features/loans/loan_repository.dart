import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';

// A small repository wrapper around [DatabaseHelper] to make it easier to
// inject via Riverpod and keep higher-level logic in the notifier.
class LoanRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> refreshOverdueInstallments(DateTime now) =>
      _db.refreshOverdueInstallments(now);

  Future<List<Loan>> getAllLoans({LoanDirection? direction}) =>
      _db.getAllLoans(direction: direction);

  Future<List<Counterparty>> getAllCounterparties() =>
      _db.getAllCounterparties();

  Future<Loan?> getLoanById(int id) => _db.getLoanById(id);

  Future<List<Installment>> getInstallmentsByLoanId(int loanId) =>
      _db.getInstallmentsByLoanId(loanId);

  Future<void> updateInstallment(Installment inst) =>
      _db.updateInstallment(inst);

  Future<Map<int, List<Installment>>> getInstallmentsGroupedByLoanId(
    List<int> loanIds,
  ) =>
      _db.getInstallmentsGroupedByLoanId(loanIds);

  Future<int> insertLoan(Loan loan) => _db.insertLoan(loan);

  /// Insert a loan and optionally create a disbursement transaction
  /// against [accountId]. Returns the inserted loan id.
  Future<int> disburseLoan(Loan loan, {int? accountId}) async {
    final loanId = await _db.insertLoan(loan);
    if (accountId != null) {
      final now = DateTime.now().toIso8601String();
      final txn = {
        'timestamp': now,
        'amount': loan.principalAmount,
        'direction': 'credit',
        'account_id': accountId,
        'related_type': 'loan',
        'related_id': loanId,
        'description': 'Loan disbursed: ${loan.title}',
        'source': 'system',
      };
      await _db.insertTransaction(txn);
    }
    return loanId;
  }

  Future<int> insertCounterparty(Counterparty cp) => _db.insertCounterparty(cp);

  Future<int> insertInstallment(Installment inst) =>
      _db.insertInstallment(inst);

  /// Record a payment for an installment: create a debit transaction on
  /// [accountId], update the installment paid fields, and return the
  /// transaction id (or -1 on failure).
  Future<int> recordInstallmentPayment(
    Installment inst, {
    required int accountId,
    required int paidAmount,
    DateTime? paidAt,
  }) async {
    if (inst.id == null) throw ArgumentError('Installment.id is null');
    final ts = (paidAt ?? DateTime.now()).toIso8601String();
    final paidJ = formatJalali(dateTimeToJalali(paidAt ?? DateTime.now()));
    final txn = {
      'timestamp': ts,
      'amount': paidAmount,
      'direction': 'debit',
      'account_id': accountId,
      'related_type': 'installment',
      'related_id': inst.id,
      'description': 'Installment payment for loan ${inst.loanId}',
      'source': 'manual',
    };
    final txnId = await _db.insertTransaction(txn);

    final updated = inst.copyWith(
      status: InstallmentStatus.paid,
      paidAt: ts,
      paidAtJalali: paidJ,
      actualPaidAmount: paidAmount,
    );
    await _db.updateInstallment(updated.copyWith(id: inst.id));
    return txnId;
  }

  Future<int> updateLoan(Loan loan) => _db.updateLoan(loan);

  Future<void> deleteLoanWithInstallments(int loanId) =>
      _db.deleteLoanWithInstallments(loanId);
}
