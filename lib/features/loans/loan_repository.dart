import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';

/// A small repository wrapper around [DatabaseHelper] to make it easier to
/// inject via Riverpod and keep higher-level logic in the notifier.
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
          List<int> loanIds) =>
      _db.getInstallmentsGroupedByLoanId(loanIds);

  Future<int> insertLoan(Loan loan) => _db.insertLoan(loan);

  Future<void> deleteLoanWithInstallments(int loanId) =>
      _db.deleteLoanWithInstallments(loanId);
}
