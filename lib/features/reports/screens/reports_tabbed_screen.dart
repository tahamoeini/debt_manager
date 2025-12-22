import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:debt_manager/features/accounts/providers/accounts_provider.dart';

class ReportsTabbedScreen extends ConsumerStatefulWidget {
  const ReportsTabbedScreen({super.key});

  @override
  ConsumerState<ReportsTabbedScreen> createState() =>
      _ReportsTabbedScreenState();
}

class _ReportsTabbedScreenState extends ConsumerState<ReportsTabbedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Jalali _startDate;
  late Jalali _endDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _startDate = Jalali.now().addMonths(-1);
    _endDate = Jalali.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loansAsync = ref.watch(loansListNotifierProvider);
    final accountsAsync = ref.watch(accountsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌ها'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'ساده'),
            Tab(text: 'پیشرفته'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date range selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _DateRangeButton(
                    label: 'از',
                    date: _startDate,
                    onTap: () async {
                      // Show date picker
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DateRangeButton(
                    label: 'تا',
                    date: _endDate,
                    onTap: () async {
                      // Show date picker
                    },
                  ),
                ),
              ],
            ),
          ),
          // Tabs
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Simple report
                _SimpleReportTab(
                  loans: loansAsync,
                  accounts: accountsAsync,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
                // Advanced report
                _AdvancedReportTab(
                  loans: loansAsync,
                  accounts: accountsAsync,
                  startDate: _startDate,
                  endDate: _endDate,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final String label;
  final Jalali date;
  final VoidCallback onTap;

  const _DateRangeButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
            ),
            Text(
              date.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleReportTab extends ConsumerWidget {
  final AsyncValue loans;
  final AsyncValue accounts;
  final Jalali startDate;
  final Jalali endDate;

  const _SimpleReportTab({
    required this.loans,
    required this.accounts,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Text(
            'خلاصه',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          loans.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('خطا: $err'),
            data: (loansList) {
              if (loansList.isEmpty) {
                return Text(
                  'داده‌ای برای نمایش نیست',
                  style: Theme.of(context).textTheme.bodySmall,
                );
              }

              final totalBorrowed = loansList.fold<double>(
                0,
                (sum, loan) =>
                    sum +
                    (loan.direction.toString().contains('borrowed')
                        ? loan.principalAmount
                        : 0),
              );

              final totalLent = loansList.fold<double>(
                0,
                (sum, loan) =>
                    sum +
                    (loan.direction.toString().contains('lent')
                        ? loan.principalAmount
                        : 0),
              );

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _StatCard(
                    title: 'قرض گرفته',
                    amount: totalBorrowed,
                    color: Colors.red,
                  ),
                  _StatCard(
                    title: 'قرض داده',
                    amount: totalLent,
                    color: Colors.green,
                  ),
                  _StatCard(
                    title: 'تعداد وام‌ها',
                    amount: loansList.length.toDouble(),
                    color: Colors.blue,
                    isCount: true,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Loans list
          Text(
            'وام‌ها',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          loans.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('خطا: $err'),
            data: (loansList) {
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: loansList.length,
                itemBuilder: (context, idx) {
                  final loan = loansList[idx];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(loan.title),
                      subtitle: Text(
                        '${loan.principalAmount} ریال - ${loan.installmentCount} قسط',
                      ),
                      trailing: Chip(
                        label: Text(
                          loan.direction.toString().contains('borrowed')
                              ? 'قرض گرفتن'
                              : 'قرض دادن',
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AdvancedReportTab extends ConsumerWidget {
  final AsyncValue loans;
  final AsyncValue accounts;
  final Jalali startDate;
  final Jalali endDate;

  const _AdvancedReportTab({
    required this.loans,
    required this.accounts,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          Text(
            'فیلترها',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('فعال'),
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('تکمیل شده'),
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('متأخر'),
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Detailed breakdown
          Text(
            'تفصیل',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),

          accounts.when(
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('خطا: $err'),
            data: (accountsList) {
              return Column(
                children: accountsList
                    .map((acc) => _AccountBreakdownCard(account: acc))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),

          // Export options
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Export to PDF
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Export to CSV
                  },
                  icon: const Icon(Icons.table_chart),
                  label: const Text('CSV'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;
  final bool isCount;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.color,
    this.isCount = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withAlpha((color.a * 255 * 0.1).round()),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              isCount
                  ? amount.toStringAsFixed(0)
                  : '${amount.toStringAsFixed(0)} ریال',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBreakdownCard extends StatelessWidget {
  final dynamic account;

  const _AccountBreakdownCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        title: Text(account.name),
        subtitle: Text('${account.balance.toStringAsFixed(0)} ریال'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('موجودی فعلی:'),
                    Text('${account.balance.toStringAsFixed(0)} ریال'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('نوع:'),
                    Text(account.type.toString().split('.').last),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ایجاد شده:'),
                    Text(account.createdAt.substring(0, 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
