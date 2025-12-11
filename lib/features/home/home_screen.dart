import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/loans/screens/loan_detail_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/core/widgets/stat_card.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/features/insights/smart_insights_widget.dart';
import 'package:debt_manager/features/home/home_statistics_notifier.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/providers/core_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(homeStatisticsProvider);

    String formatOrDash(int value) => formatCurrency(value);

    return ListView(
      padding: AppDimensions.pagePadding,
      children: [
        Text('خلاصه', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimensions.spacingM),
        // Top summary cards
        Row(
          children: [
            Expanded(
              child: statsAsync.when(
                loading: () => StatCard(
                  title: 'موجودی خالص',
                  value: 'در حال بارگذاری…',
                  icon: Icons.account_balance_wallet,
                  onTap: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const LoansListScreen()),
                    );
                    if (res == true) {
                      ref.read(refreshTriggerProvider.notifier).state++;
                    }
                  },
                ),
                error: (e, st) => StatCard(
                  title: 'موجودی خالص',
                  value: 'خطا',
                  icon: Icons.account_balance_wallet,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const LoansListScreen()));
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
                data: (data) => StatCard(
                  title: 'موجودی خالص',
                  value: formatOrDash(data.net),
                  icon: Icons.account_balance_wallet,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const LoansListScreen()));
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: statsAsync.when(
                loading: () => StatCard(
                  title: 'هزینه این ماه',
                  value: 'در حال بارگذاری…',
                  icon: Icons.receipt_long,
                  onTap: () async {
                    final res = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                    if (res == true) {
                      ref.read(refreshTriggerProvider.notifier).state++;
                    }
                  },
                ),
                error: (e, st) => StatCard(
                  title: 'هزینه این ماه',
                  value: 'خطا',
                  icon: Icons.receipt_long,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReportsScreen()));
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
                data: (data) => StatCard(
                  title: 'هزینه این ماه',
                  value: formatOrDash(0),
                  icon: Icons.receipt_long,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const ReportsScreen()));
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Card(
          child: Padding(
            padding: AppDimensions.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قبوض پیش رو',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.spacingS),
                statsAsync.when(
                  loading: () => SizedBox(
                    height: 56,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, st) => Text('خطا در بارگذاری',
                      style: Theme.of(context).textTheme.bodySmall),
                  data: (data) {
                    if (data.upcoming.isEmpty) {
                      return Text('هیچ قبضی در چند روز آینده وجود ندارد',
                          style: Theme.of(context).textTheme.bodySmall);
                    }

                    // Show up to 3 upcoming installments
                    final items = data.upcoming.take(3).map((inst) {
                      final loan = data.loansById[inst.loanId];
                      final cp = data.counterpartiesById[loan?.counterpartyId ?? -1];
                      final title = loan?.title ?? cp?.name ?? 'بدون عنوان';
                      return InkWell(
                        onTap: () async {
                          final res = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => LoanDetailScreen(loanId: inst.loanId),
                            ),
                          );
                          if (res == true) {
                            ref.read(refreshTriggerProvider.notifier).state++;
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${inst.dueDateJalali} • $title',
                                  style: Theme.of(context).textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                formatCurrency(inst.amount),
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList();

                    return Column(children: items);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        const SmartInsightsWidget(),
      ],
    );
  }
}
