// Home screen: dashboard showing summaries and upcoming installments.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/debug_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> _loadData() async {
    // Ensure overdue statuses are refreshed once before querying totals.
    await _db.refreshOverdueInstallments(DateTime.now());

    if (kDebugLogging) {
      debugLog('HomeScreen: refreshed overdue installments');
    }

    final borrowed = await _db.getTotalOutstandingBorrowed();
    final lent = await _db.getTotalOutstandingLent();
    final net = lent - borrowed;

    final today = DateTime.now();
    final to = today.add(const Duration(days: 7));

    // Fetch upcoming installments for the next 7 days (keeps existing behavior).
    final upcoming = await _db.getUpcomingInstallments(today, to);

    if (kDebugLogging) {
      debugLog('HomeScreen: upcoming installments count=${upcoming.length}');
    }

    // Fetch related loans and counterparties to show titles and names.
    // Load related loans and counterparties once to avoid repeated DB calls
    // while rendering the upcoming list.
    final loanIds = upcoming.map((i) => i.loanId).toSet();
    final Map<int, Loan> loansById = {};
    for (final id in loanIds) {
      final loan = await _db.getLoanById(id);
      if (loan != null) loansById[id] = loan;
    }

    final cps = await _db.getAllCounterparties();
    final Map<int, Counterparty> cpById = {for (var c in cps) c.id ?? -1: c};

    if (kDebugLogging) {
      debugLog(
        'HomeScreen: loansById=${loansById.length}, counterparties=${cpById.length}',
      );
    }

    return {
      'borrowed': borrowed,
      'lent': lent,
      'net': net,
      'upcoming': upcoming,
      'loansById': loansById,
      'counterparties': cpById,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return UIUtils.centeredLoading();
        }

        if (snapshot.hasError) {
          debugPrint('HomeScreen _loadData error: ${snapshot.error}');
          return UIUtils.asyncErrorWidget(snapshot.error);
        }

        final data = snapshot.data ?? {};
        final borrowed = data['borrowed'] as int? ?? 0;
        final lent = data['lent'] as int? ?? 0;
        final net = data['net'] as int? ?? 0;
        final upcoming = data['upcoming'] as List<Installment>? ?? [];
        final loansById = data['loansById'] as Map<int, Loan>? ?? {};
        final cpById = data['counterparties'] as Map<int, Counterparty>? ?? {};

        return ListView(
          padding: AppConstants.pagePadding,
          children: [
            SummaryCards(borrowed: borrowed, lent: lent, net: net),
            const SizedBox(height: AppConstants.spaceXLarge),
            Text(
              'اقساط نزدیک',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppConstants.spaceSmall),
            if (upcoming.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: Padding(
                  padding: AppConstants.cardPadding,
                  child: Text(
                    'اقساط نزدیکی یافت نشد',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            if (upcoming.isNotEmpty)
              ...upcoming.map((inst) {
                final loan = loansById[inst.loanId];
                final loanTitle = loan?.title ?? 'بدون عنوان';
                final cp = loan != null ? cpById[loan.counterpartyId] : null;
                final cpName = cp?.name ?? '';
                final dueJalali = parseJalali(inst.dueDateJalali);
                final dueDisplay = formatJalaliForDisplay(dueJalali);

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  margin: const EdgeInsets.only(bottom: AppConstants.spaceSmall),
                  child: Padding(
                    padding: AppConstants.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loanTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: AppConstants.spaceXSmall),
                        Text(
                          cpName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppConstants.spaceSmall),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dueDisplay),
                            Text(formatCurrency(inst.amount)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
