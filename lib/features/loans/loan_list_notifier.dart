import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/loans/loan_repository.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

// A lightweight DTO used by UI to render loan rows.
class LoanSummary {
  final Loan loan;
  final String counterpartyName;
  final String? counterpartyType;
  final String? counterpartyTag;
  final int remainingCount;
  final int remainingAmount;

  LoanSummary({
    required this.loan,
    required this.counterpartyName,
    this.counterpartyType,
    this.counterpartyTag,
    required this.remainingCount,
    required this.remainingAmount,
  });
}

final loanRepositoryProvider = Provider<LoanRepository>(
  (ref) => LoanRepository(),
);

final loanListProvider =
    StateNotifierProvider.family<
      LoanListNotifier,
      List<LoanSummary>,
      LoanDirection?
    >((ref, direction) {
      return LoanListNotifier(ref, direction);
    });

class LoanListNotifier extends StateNotifier<List<LoanSummary>> {
  final Ref ref;
  final LoanDirection? filter;

  LoanListNotifier(this.ref, this.filter) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(loanRepositoryProvider);
    await repo.refreshOverdueInstallments(DateTime.now());

    final loans = await repo.getAllLoans(direction: filter);
    final cps = await repo.getAllCounterparties();
    final Map<int, Counterparty> cpMap = {for (var c in cps) c.id ?? -1: c};

    final loanIds = loans.where((l) => l.id != null).map((l) => l.id!).toList();
    final grouped = loanIds.isNotEmpty
        ? await repo.getInstallmentsGroupedByLoanId(loanIds)
        : <int, List<Installment>>{};

    final List<LoanSummary> result = [];

    for (final loan in loans) {
      if (loan.id == null) continue;
      final installments = grouped[loan.id] ?? const <Installment>[];
      final unpaid = installments
          .where((i) => i.status != InstallmentStatus.paid)
          .toList();
      final remainingCount = unpaid.length;
      final remainingAmount = unpaid.fold<int>(0, (s, i) => s + i.amount);
      final cp = cpMap[loan.counterpartyId];
      final cpName = cp?.name ?? '';
      final cpType = cp?.type;
      final cpTag = cp?.tag;

      result.add(
        LoanSummary(
          loan: loan,
          counterpartyName: cpName,
          counterpartyType: cpType,
          counterpartyTag: cpTag,
          remainingCount: remainingCount,
          remainingAmount: remainingAmount,
        ),
      );
    }

    state = result;
  }

  Future<void> refresh() => _load();

  Future<void> deleteLoan(int loanId) async {
    final repo = ref.read(loanRepositoryProvider);
    await repo.deleteLoanWithInstallments(loanId);
    state = state.where((s) => s.loan.id != loanId).toList();
  }

  Future<int> addLoan(Loan loan) async {
    final repo = ref.read(loanRepositoryProvider);
    final id = await repo.insertLoan(loan);
    // Reload to compute summaries (installments will be created elsewhere)
    await _load();
    return id;
  }
}
