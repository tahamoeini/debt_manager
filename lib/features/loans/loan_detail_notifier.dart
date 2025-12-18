import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/loans/loan_repository.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';

class LoanDetailState {
  final Loan? loan;
  final Counterparty? counterparty;
  final List<Installment> installments;

  LoanDetailState({this.loan, this.counterparty, this.installments = const []});

  LoanDetailState copyWith({
    Loan? loan,
    Counterparty? counterparty,
    List<Installment>? installments,
  }) {
    return LoanDetailState(
      loan: loan ?? this.loan,
      counterparty: counterparty ?? this.counterparty,
      installments: installments ?? this.installments,
    );
  }
}

class LoanDetailNotifier extends StateNotifier<AsyncValue<LoanDetailState>> {
  final Ref ref;
  final int loanId;

  LoanDetailNotifier(this.ref, this.loanId)
      : super(const AsyncValue.loading()) {
    _load();
  }

  LoanRepository get _repo => ref.read(loanRepositoryProvider);

  Future<void> _load() async {
    try {
      final loan = await _repo.getLoanById(loanId);
      final cps = await _repo.getAllCounterparties();
      final cp = loan != null
          ? cps.firstWhere(
              (c) => c.id == loan.counterpartyId,
              orElse: () => const Counterparty(id: null, name: 'نامشخص'),
            )
          : const Counterparty(id: null, name: 'نامشخص');
      final installments = loan != null
          ? await _repo.getInstallmentsByLoanId(loanId)
          : <Installment>[];
      state = AsyncValue.data(
        LoanDetailState(
          loan: loan,
          counterparty: cp,
          installments: installments,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() => _load();

  Future<void> updateInstallment(Installment updated) async {
    try {
      state = const AsyncValue.loading();
      await _repo.updateInstallment(updated);
      await _load();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteLoan(int id) async {
    try {
      state = const AsyncValue.loading();
      await _repo.deleteLoanWithInstallments(id);
      state = AsyncValue.data(
        LoanDetailState(loan: null, counterparty: null, installments: []),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final loanDetailProvider = StateNotifierProvider.family<LoanDetailNotifier,
    AsyncValue<LoanDetailState>, int>((ref, loanId) {
  return LoanDetailNotifier(ref, loanId);
});
