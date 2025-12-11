import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';

/// Simple DTO holding home summary values.
class HomeStats {
  final int borrowed;
  final int lent;
  final int net;
  final List<Installment> upcoming;
  final Map<int, Loan> loansById;
  final Map<int, Counterparty> counterpartiesById;

  HomeStats({
    required this.borrowed,
    required this.lent,
    required this.net,
    required this.upcoming,
    required this.loansById,
    required this.counterpartiesById,
  });
}

/// StateNotifier that loads and holds HomeStats in an AsyncValue wrapper.
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
