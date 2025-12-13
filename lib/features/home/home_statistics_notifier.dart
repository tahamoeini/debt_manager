import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';

// Simple DTO holding home summary values.
class HomeStats {
  final int borrowed;
  final int lent;
  final int net;
  final int monthlySpending; // Current month expenses
  final List<int> spendingTrend; // Last 6 months of spending
  final List<Installment> upcoming;
  final Map<int, Loan> loansById;
  final Map<int, Counterparty> counterpartiesById;

  HomeStats({
    required this.borrowed,
    required this.lent,
    required this.net,
    required this.monthlySpending,
    required this.spendingTrend,
    required this.upcoming,
    required this.loansById,
    required this.counterpartiesById,
  });
}

// StateNotifier that loads and holds HomeStats in an AsyncValue wrapper.
class HomeStatisticsNotifier extends StateNotifier<AsyncValue<HomeStats>> {
  HomeStatisticsNotifier(this.ref) : super(const AsyncValue.loading()) {
    // Recompute when refresh trigger changes
    ref.listen<int>(refreshTriggerProvider, (prev, next) => load());
    load();
  }

  final Ref ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseHelperProvider);

      await db.refreshOverdueInstallments(DateTime.now());

      final borrowed = await db.getTotalOutstandingBorrowed();
      final lent = await db.getTotalOutstandingLent();
      final net = lent - borrowed;
      // Calculate current month spending from paid installments
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      int monthlySpending = 0;
      // Get all loans and their installments
      final loans = await db.getAllLoans(direction: LoanDirection.borrowed);
      final allLoanIds = loans.map((l) => l.id).whereType<int>().toList();
      final grouped = allLoanIds.isNotEmpty
          ? await db.getInstallmentsGroupedByLoanId(allLoanIds)
          : <int, List<Installment>>{};

      for (final installments in grouped.values) {
        for (final inst in installments) {
          if (inst.paidAt != null) {
            final paidDate = DateTime.parse(inst.paidAt!);
            if (paidDate.isAfter(startOfMonth) &&
                paidDate.isBefore(endOfMonth)) {
              monthlySpending += inst.actualPaidAmount ?? inst.amount;
            }
          }
        }
      }

      // Calculate 6-month spending trend
      final spendingTrend = <int>[];
      for (var i = 5; i >= 0; i--) {
        final monthDate = DateTime(now.year, now.month - i, 1);
        final monthStart = DateTime(monthDate.year, monthDate.month, 1);
        final monthEnd = monthDate.month == 12
            ? DateTime(monthDate.year + 1, 1, 1)
            : DateTime(monthDate.year, monthDate.month + 1, 1);

        int monthSpending = 0;
        for (final installments in grouped.values) {
          for (final inst in installments) {
            if (inst.paidAt != null) {
              final paidDate = DateTime.parse(inst.paidAt!);
              if (paidDate.isAfter(monthStart) && paidDate.isBefore(monthEnd)) {
                monthSpending += inst.actualPaidAmount ?? inst.amount;
              }
            }
          }
        }
        spendingTrend.add(monthSpending);
      }

      final today = DateTime.now();
      final to = today.add(const Duration(days: 7));
      final upcoming = await db.getUpcomingInstallments(today, to);

      // load related loans and counterparties
      final loanIds = upcoming.map((i) => i.loanId).toSet();
      final Map<int, Loan> loansById = {};
      for (final id in loanIds) {
        final loan = await db.getLoanById(id);
        if (loan != null) loansById[id] = loan;
      }

      final cps = await db.getAllCounterparties();
      final cpById = {for (var c in cps) c.id ?? -1: c};

      state = AsyncValue.data(HomeStats(
        borrowed: borrowed,
        lent: lent,
        net: net,
        monthlySpending: monthlySpending,
        spendingTrend: spendingTrend,
        upcoming: upcoming,
        loansById: loansById,
        counterpartiesById: cpById,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    // bump global refresh trigger so other listeners also update
    ref.read(refreshTriggerProvider.notifier).state++;
  }
}

final homeStatisticsProvider = StateNotifierProvider.autoDispose<
    HomeStatisticsNotifier, AsyncValue<HomeStats>>((ref) {
  return HomeStatisticsNotifier(ref);
});
