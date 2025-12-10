// Home screen: dashboard showing summaries and upcoming installments.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
// Installment model is referenced via HomeStats; no direct import required here.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/home/home_statistics_notifier.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeStatisticsProvider);

    return async.when(
      loading: () => UIUtils.centeredLoading(),
      error: (e, st) => UIUtils.asyncErrorWidget(e),
      data: (data) {
        final borrowed = data.borrowed;
        final lent = data.lent;
        final net = data.net;
        final upcoming = data.upcoming;
        final loansById = data.loansById;
        final cpById = data.counterpartiesById;

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
