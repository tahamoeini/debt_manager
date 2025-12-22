import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/installment_payment.dart';
import '../repositories/installment_payments_repository.dart';

part 'installment_payments_provider.g.dart';

@riverpod
class PaymentsNotifier extends _$PaymentsNotifier {
  @override
  Future<List<InstallmentPayment>> build(int loanId) async {
    final repo = ref.watch(installmentPaymentsRepositoryProvider);
    return repo.getPaymentsByLoan(loanId);
  }

  Future<void> recordPayment({
    required int installmentId,
    required int accountId,
    required double amount,
    required Jalali paidDate,
    String? notes,
  }) async {
    final repo = ref.watch(installmentPaymentsRepositoryProvider);
    await repo.recordPayment(
      loanId: state.valueOrNull?.first.loanId ?? 0,
      installmentId: installmentId,
      accountId: accountId,
      amount: amount,
      paidDate: paidDate,
      notes: notes,
    );
    ref.invalidateSelf();
  }

  Future<void> updatePaymentStatus(
    int paymentId,
    PaymentStatus status,
    double amountPaid,
  ) async {
    final repo = ref.watch(installmentPaymentsRepositoryProvider);
    await repo.updatePaymentStatus(paymentId, status, amountPaid);
    ref.invalidateSelf();
  }

  Future<void> markAsPaid(int paymentId, Jalali paidDate) async {
    final repo = ref.watch(installmentPaymentsRepositoryProvider);
    await repo.markAsPaid(paymentId, paidDate);
    ref.invalidateSelf();
  }
}

@riverpod
InstallmentPaymentsRepository installmentPaymentsRepository(
  InstallmentPaymentsRepositoryRef ref,
) {
  throw UnimplementedError();
}

@riverpod
Future<List<InstallmentPayment>> upcomingPayments(
  UpcomingPaymentsRef ref,
) async {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return repo.getUpcomingPayments();
}

@riverpod
Future<List<InstallmentPayment>> overduePayments(
  OverduePaymentsRef ref,
) async {
  final repo = ref.watch(installmentPaymentsRepositoryProvider);
  return repo.getOverduePayments();
}
