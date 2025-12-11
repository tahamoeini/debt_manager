import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

/// Minimal LoanForm state container used by Add/Edit loan UI.
class LoanFormState {
  final bool loading;
  final Loan? existingLoan;
  final List<Counterparty> counterparties;

  LoanFormState(
      {this.loading = false,
      this.existingLoan,
      this.counterparties = const []});

  LoanFormState copyWith(
      {bool? loading, Loan? existingLoan, List<Counterparty>? counterparties}) {
    return LoanFormState(
      loading: loading ?? this.loading,
      existingLoan: existingLoan ?? this.existingLoan,
      counterparties: counterparties ?? this.counterparties,
    );
  }
}

class LoanFormNotifier extends StateNotifier<AsyncValue<LoanFormState>> {
  LoanFormNotifier(this.ref, [this.loanId])
      : super(const AsyncValue.loading()) {
    _init();
  }

  final Ref ref;
  final int? loanId;

  Future<void> _init() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseHelperProvider);
      final cps = await db.getAllCounterparties();
      Loan? loan;
      if (loanId != null) loan = await db.getLoanById(loanId!);

      state = AsyncValue.data(LoanFormState(
          loading: false, existingLoan: loan, counterparties: cps));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveNewLoan(Loan loan, List<Installment> installments) async {
    final current = state.value ?? LoanFormState();
    state = AsyncValue.data(current.copyWith(loading: true));
    try {
      final db = ref.read(databaseHelperProvider);
      final id = await db.insertLoan(loan);
      // insert installments and schedule notifications via SmartNotificationService
      for (final inst in installments) {
        await db.insertInstallment(inst.copyWith(loanId: id));
      }

      // Notify smart notification service to (re)compute reminders
      final notif = ref.read(smartNotificationServiceProvider);
      await notif.scheduleBillReminders();

      // trigger global refresh
      // invalidate report caches and trigger global refresh
      try {
        ref.read(reportsCacheProvider.notifier).clear();
      } catch (_) {}
      ref.read(refreshTriggerProvider.notifier).state++;
      final now = state.value ?? current;
      state = AsyncValue.data(now.copyWith(loading: false));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLoan(Loan loan) async {
    final current = state.value ?? LoanFormState();
    state = AsyncValue.data(current.copyWith(loading: true));
    try {
      final db = ref.read(databaseHelperProvider);
      await db.updateLoan(loan);
      try {
        ref.read(reportsCacheProvider.notifier).clear();
      } catch (_) {}
      ref.read(refreshTriggerProvider.notifier).state++;
      final now = state.value ?? current;
      state = AsyncValue.data(now.copyWith(loading: false));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final loanFormProvider = StateNotifierProvider.family
    .autoDispose<LoanFormNotifier, AsyncValue<LoanFormState>, int?>(
        (ref, loanId) {
  return LoanFormNotifier(ref, loanId);
});
