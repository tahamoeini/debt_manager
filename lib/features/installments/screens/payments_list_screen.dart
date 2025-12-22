import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/installment_payment.dart';
import '../providers/installment_payments_provider.dart';
import 'payment_record_screen.dart';

Color _alphaScaled(Color color, double factor) =>
  color.withAlpha((color.a * 255 * factor).round());

class PaymentsListScreen extends ConsumerWidget {
  final int loanId;

  const PaymentsListScreen({required this.loanId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(paymentsNotifierProvider(loanId));

    return Scaffold(
      appBar: AppBar(title: const Text('پرداخت‌ها')),
      body: paymentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('خطا: $err')),
        data: (payments) {
          if (payments.isEmpty) {
            return const Center(
              child: Text('هیچ پرداختی ثبت نشده است'),
            );
          }

          // Group by status
          final pending = payments.where((p) => p.status == PaymentStatus.pending).toList();
          final paid = payments.where((p) => p.status == PaymentStatus.paid).toList();
          final overdue = payments.where((p) => p.isOverdue).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _SummaryCard(
                        title: 'در انتظار',
                        count: pending.length,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'پرداخت شده',
                        count: paid.length,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryCard(
                        title: 'تأخیر',
                        count: overdue.length,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Pending payments
                if (pending.isNotEmpty) ...[
                  Text(
                    'پرداخت‌های درانتظار',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._buildPaymentList(context, ref, pending),
                  const SizedBox(height: 24),
                ],

                // Paid payments
                if (paid.isNotEmpty) ...[
                  Text(
                    'پرداخت‌های انجام شده',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ..._buildPaymentList(context, ref, paid),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildPaymentList(
    BuildContext context,
    WidgetRef ref,
    List<InstallmentPayment> payments,
  ) {
    return payments
        .map((payment) => _PaymentCard(
              payment: payment,
              onTap: () => _navigateToRecord(context, payment),
            ))
        .toList();
  }

  void _navigateToRecord(BuildContext context, InstallmentPayment payment) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaymentRecordScreen(
          loanId: payment.loanId,
          installmentId: payment.installmentId,
          installmentAmount: payment.amount,
          dueDate: payment.dueDate,
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: _alphaScaled(color, 0.1),
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
              count.toString(),
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

class _PaymentCard extends StatelessWidget {
  final InstallmentPayment payment;
  final VoidCallback onTap;

  const _PaymentCard({
    required this.payment,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (payment.status) {
      PaymentStatus.pending => Colors.orange,
      PaymentStatus.paid => Colors.green,
      PaymentStatus.overdue => Colors.red,
      PaymentStatus.partial => Colors.blue,
    };

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: _alphaScaled(statusColor, 0.2),
          child: Icon(
            switch (payment.status) {
              PaymentStatus.pending => Icons.schedule,
              PaymentStatus.paid => Icons.check_circle,
              PaymentStatus.overdue => Icons.error,
              PaymentStatus.partial => Icons.info,
            },
            color: statusColor,
          ),
        ),
        title: Text('${payment.amount.toStringAsFixed(0)} ریال'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('سررسید: ${payment.dueDate}'),
            if (payment.paidDate != null)
              Text('پرداخت شده: ${payment.paidDate}'),
          ],
        ),
        trailing: Chip(
          label: Text(payment.statusLabel),
          backgroundColor: _alphaScaled(statusColor, 0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }
}
