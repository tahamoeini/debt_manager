// Home screen: dashboard showing summaries and upcoming installments.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
// Loan/installment/counterparty types are part of HomeStats; no direct imports needed here
import 'package:debt_manager/features/home/home_statistics_notifier.dart';
import 'package:debt_manager/components/sensitive_text.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(homeStatisticsProvider);
    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text('خطا هنگام بارگذاری')),
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
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بدهی‌های من',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SensitiveText(formatCurrency(borrowed),
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('طلب‌های من',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SensitiveText(formatCurrency(lent),
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وضعیت خالص',
                              style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          SensitiveText(formatCurrency(net),
                              style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('اقساط نزدیک',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              Card(
                shape: const RoundedRectangleBorder(
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loanTitle,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(cpName,
                            style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dueDisplay),
                            SensitiveText(formatCurrency(inst.amount)),
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
