import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/features/installments/models/installment_payment.dart';
import 'package:debt_manager/features/installments/repositories/installment_payments_repository.dart';
import 'package:debt_manager/core/providers/core_providers.dart';

/// Provides a list of all upcoming payments
final upcomingPaymentsProvider = FutureProvider<List<InstallmentPayment>>((ref) async {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return repo.getUpcomingPayments();
});

/// Provides a list of all overdue payments
final overduePaymentsProvider = FutureProvider<List<InstallmentPayment>>((ref) async {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return repo.getOverduePayments();
});

/// Provides payments for a specific loan
final paymentsForLoanProvider = FutureProviderFamily<List<InstallmentPayment>, int>((ref, loanId) async {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return repo.getPaymentsByLoan(loanId);
});

/// Notifier for managing payment operations for a specific loan
class LoanPaymentsNotifier extends StateNotifier<AsyncValue<List<InstallmentPayment>>> {
  final InstallmentPaymentsRepository _repository;
  final int _loanId;

  LoanPaymentsNotifier(this._repository, this._loanId)
      : super(const AsyncValue.loading());

  Future<void> loadPayments() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.getPaymentsByLoan(_loanId));
  }

  Future<void> recordPayment({
    required int installmentId,
    required int accountId,
    required double amount,
    required Jalali paidDate,
    String? notes,
  }) async {
    await _repository.recordPayment(
      loanId: _loanId,
      installmentId: installmentId,
      accountId: accountId,
      amount: amount,
      paidDate: paidDate,
      notes: notes,
    );
    await loadPayments();
  }

  Future<void> updatePaymentStatus(
    int paymentId,
    PaymentStatus status,
    double amountPaid,
  ) async {
    await _repository.updatePaymentStatus(paymentId, status, amountPaid);
    await loadPayments();
  }

  Future<void> markAsPaid(int paymentId, Jalali paidDate) async {
    await _repository.markAsPaid(paymentId, paidDate);
    await loadPayments();
  }
}

/// Provides the payments notifier for a specific loan
final paymentsNotifierProvider = StateNotifierProvider.family<
    LoanPaymentsNotifier,
    AsyncValue<List<InstallmentPayment>>,
    int>((ref, loanId) {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return LoanPaymentsNotifier(repo, loanId)..loadPayments();
});
