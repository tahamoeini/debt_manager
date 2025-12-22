import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/features/accounts/providers/accounts_provider.dart';
import 'package:debt_manager/features/installments/providers/installment_payments_provider.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:debt_manager/core/utils/jalali_date_provider.dart';

class ModernHomeDashboard extends ConsumerWidget {
  const ModernHomeDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountsAsync = ref.watch(accountsNotifierProvider);
    final upcomingAsync = ref.watch(upcomingPaymentsProvider);
    final overdueAsync = ref.watch(overduePaymentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App bar
          SliverAppBar(
            title: const Text('داشبورد'),
            floating: true,
            elevation: 0,
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Date header
                Text(
                  JalaliDateProvider.formatFull(Jalali.now()),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 20),

                // Summary section
                Text(
                  'خلاصه مالی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                // Account balances row
                accountsAsync.when(
                  loading: () => const SizedBox(
                    height: 100,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, stack) => Text('خطا: $err'),
                  data: (accounts) {
                    if (accounts.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'هیچ حسابی ثبت نشده است',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }

                    final totalBalance =
                        accounts.fold<double>(0, (sum, acc) => sum + acc.balance);

                    return Column(
                      children: [
                        // Total balance card
                        Card(
                          elevation: 2,
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.shade400,
                                  Colors.blue.shade600,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'کل موجودی',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(color: Colors.white70),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${totalBalance.toStringAsFixed(0)} ریال',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Account cards grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1.2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: accounts.length,
                          itemBuilder: (context, idx) {
                            final acc = accounts[idx];
                            return _AccountCard(account: acc);
                          },
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Upcoming payments
                Text(
                  'پرداخت‌های پیش‌رو',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                upcomingAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Text('خطا: $err'),
                  data: (payments) {
                    if (payments.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'هیچ پرداختی در ۳۰ روز آینده نیست',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: payments.take(5).length,
                      itemBuilder: (context, idx) {
                        final payment = payments[idx];
                        return _UpcomingPaymentTile(payment: payment);
                      },
                    );
                  },
                ),
                const SizedBox(height: 32),

                // Overdue payments alert
                overdueAsync.when(
                  loading: () => const SizedBox(),
                  error: (err, stack) => const SizedBox(),
                  data: (overduePayments) {
                    if (overduePayments.isNotEmpty) {
                      return Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.warning, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    '⚠️ ${overduePayments.length} پرداخت تأخیری',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(color: Colors.red),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...overduePayments.take(3).map((p) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Text(
                                    '• ${p.amount.toStringAsFixed(0)} ریال (تا ${p.dueDate})',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
                const SizedBox(height: 32),

                // Quick actions
                Text(
                  'اقدامات سریع',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _QuickActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'وام جدید',
                      onTap: () {
                        // Navigate to loan wizard
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.payment,
                      label: 'ثبت پرداخت',
                      onTap: () {
                        // Navigate to payment record
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.account_balance,
                      label: 'حساب جدید',
                      onTap: () {
                        // Navigate to account form
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.trending_up,
                      label: 'گزارش‌ها',
                      onTap: () {
                        // Navigate to reports
                      },
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final dynamic account;

  const _AccountCard({required this.account});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  switch (account.type.toString().split('.').last) {
                    'bank' => Icons.account_balance,
                    'wallet' => Icons.card_giftcard,
                    'cash' => Icons.attach_money,
                    _ => Icons.account_circle,
                  },
                  size: 28,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              '${account.balance.toStringAsFixed(0)} ریال',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPaymentTile extends StatelessWidget {
  final dynamic payment;

  const _UpcomingPaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final daysUntilDue =
        payment.dueDate.difference(Jalali.now()).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: CircleAvatar(
          backgroundColor: daysUntilDue <= 7 ? Colors.orange : Colors.blue,
          child: Text(
            daysUntilDue.toString(),
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ),
        title: Text('${payment.amount.toStringAsFixed(0)} ریال'),
        subtitle: Text(
          'سررسید: ${payment.dueDate}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Chip(
          label: Text(daysUntilDue <= 7 ? '⏰ فوری' : 'پیش‌رو'),
          backgroundColor: daysUntilDue <= 7 ? Colors.orange.shade100 : Colors.blue.shade100,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.blue),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
