import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/loans/screens/loan_detail_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/features/automation/screens/can_i_afford_this_screen.dart';
import 'package:debt_manager/features/achievements/screens/progress_screen.dart';
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
                      MaterialPageRoute(
                        builder: (_) => const LoansListScreen(),
                      ),
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
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoansListScreen(),
                      ),
                    );
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
                data: (data) => StatCard(
                  title: 'موجودی خالص',
                  value: formatOrDash(data.net),
                  icon: Icons.account_balance_wallet,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LoansListScreen(),
                      ),
                    );
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
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
                    ref.read(refreshTriggerProvider.notifier).state++;
                  },
                ),
                data: (data) => StatCard(
                  title: 'هزینه این ماه',
                  value: formatOrDash(data.monthlySpending),
                  icon: Icons.receipt_long,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportsScreen()),
                    );
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
                Text(
                  'قبوض پیش رو',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                statsAsync.when(
                  loading: () => SizedBox(
                    height: 56,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  error: (e, st) => Text(
                    'خطا در بارگذاری',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  data: (data) {
                    if (data.upcoming.isEmpty) {
                      return Text(
                        'هیچ قبضی در چند روز آینده وجود ندارد',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    }

                    // Show up to 3 upcoming installments
                    final items = data.upcoming.take(3).map((inst) {
                      final loan = data.loansById[inst.loanId];
                      final cp =
                          data.counterpartiesById[loan?.counterpartyId ?? -1];
                      final title = loan?.title ?? cp?.name ?? 'بدون عنوان';

                      // Check if overdue based on status
                      final isOverdue =
                          inst.status.toString() == 'InstallmentStatus.overdue';
                      final color = isOverdue
                          ? Colors.red.shade600
                          : Colors.blue.shade700;

                      return Container(
                        margin: const EdgeInsets.only(
                          bottom: AppDimensions.spacingS,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isOverdue
                                ? Colors.red.shade200
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isOverdue
                              ? Colors.red.shade50
                              : Colors.grey.shade50,
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final res =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) =>
                                      LoanDetailScreen(loanId: inst.loanId),
                                ),
                              );
                              if (res == true) {
                                ref
                                    .read(refreshTriggerProvider.notifier)
                                    .state++;
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppDimensions.spacingM,
                                vertical: AppDimensions.spacingS,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: color,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        inst.dueDateJalali,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: isOverdue
                                                  ? Colors.red.shade600
                                                  : Colors.grey.shade700,
                                            ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        formatCurrency(inst.amount),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: color,
                                            ),
                                      ),
                                      if (isOverdue)
                                        Text(
                                          'تأخیر',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelSmall
                                              ?.copyWith(
                                                color: Colors.red.shade600,
                                              ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
        // Spending trend chart
        statsAsync.when(
          loading: () => Card(
            child: Padding(
              padding: AppDimensions.cardPadding,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
          error: (e, st) => Card(
            child: Padding(
              padding: AppDimensions.cardPadding,
              child: Text(
                'خطا در بارگذاری نمودار',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          data: (data) => Card(
            child: Padding(
              padding: AppDimensions.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'روند هزینه (6 ماه)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'میانگین: ${formatCurrency((data.spendingTrend.fold<int>(0, (a, b) => a + b) ~/ data.spendingTrend.length))}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  SizedBox(
                    height: 150,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: data.spendingTrend
                                .asMap()
                                .entries
                                .map(
                                  (e) => FlSpot(
                                    e.key.toDouble(),
                                    (e.value / 1000000).toDouble(),
                                  ),
                                )
                                .toList(),
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.blue.shade300,
                                Colors.blue.shade700,
                              ],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Colors.blue.shade700,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade300.withAlpha(100),
                                  Colors.blue.shade700.withAlpha(50),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: AppDimensions.spacingM),
        // Action buttons for new features
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CanIAffordThisScreen(),
                    ),
                  );
                },
                icon: Icon(Icons.trending_up),
                label: Text('آیا می‌توانم؟'),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProgressScreen()),
                  );
                },
                icon: Icon(Icons.emoji_events),
                label: Text('پیشرفت'),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        const SmartInsightsWidget(),
      ],
    );
  }
}
