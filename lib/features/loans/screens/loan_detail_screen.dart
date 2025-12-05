/// Loan detail screen: shows loan details and its installments and actions.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'add_loan_screen.dart';

class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final int loanId;

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> _loadAll() async {
    final loan = await _db.getLoanById(widget.loanId);

    final cps = await _db.getAllCounterparties();
    final cp = loan != null
        ? cps.firstWhere(
            (c) => c.id == loan.counterpartyId,
            orElse: () => Counterparty(id: null, name: 'نامشخص'),
          )
        : Counterparty(id: null, name: 'نامشخص');

    final installments = loan != null
        ? await _db.getInstallmentsByLoanId(widget.loanId)
        : <Installment>[];

    return {'loan': loan, 'counterparty': cp, 'installments': installments};
  }

  String _directionText(LoanDirection dir) {
    return dir == LoanDirection.borrowed ? 'من بدهکارم' : 'من طلبکارم';
  }

  String _statusText(InstallmentStatus s) {
    switch (s) {
      case InstallmentStatus.paid:
        return 'پرداخت شده';
      case InstallmentStatus.overdue:
        return 'عقب‌افتاده';
      case InstallmentStatus.pending:
        return 'در انتظار';
    }
  }

  Future<void> _markPaid(Installment inst) async {
    if (inst.id == null) return;

    final updated = inst.copyWith(
      status: InstallmentStatus.paid,
      paidAt: DateTime.now().toIso8601String(),
    );
    await _db.updateInstallment(updated);

    if (inst.notificationId != null) {
      await NotificationService().cancelNotification(inst.notificationId!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Scaffold(
            body: const Center(child: CircularProgressIndicator()),
          );
        if (snapshot.hasError) {
          debugPrint('LoanDetailScreen _loadAll error: ${snapshot.error}');
          return const Scaffold(
            body: Center(child: Text('خطا در بارگذاری داده‌ها')),
          );
        }

        final loan = snapshot.data?['loan'] as Loan?;
        final cp = snapshot.data?['counterparty'] as Counterparty?;
        final installments =
            snapshot.data?['installments'] as List<Installment>? ?? [];

        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('جزئیات وام')),
            body: const Center(child: Text('وام یافت نشد')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(loan.title.isNotEmpty ? loan.title : 'بدون عنوان'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    // Navigate to AddLoanScreen in edit mode.
                    final res = await Navigator.of(context).push<bool?>(
                      MaterialPageRoute(
                        builder: (_) => AddLoanScreen(
                          existingLoan: loan,
                          existingCounterparty: cp,
                        ),
                      ),
                    );

                    if (res == true) {
                      // Refresh the screen after editing
                      setState(() {});
                    }
                  } else if (v == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('حذف وام'),
                        content: const Text(
                          'آیا مطمئن هستید؟ این عملیات وام، همه اقساط مرتبط و یادآورها را حذف خواهد کرد.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('انصراف'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      try {
                        if (loan.id != null) {
                          await _db.deleteLoanWithInstallments(loan.id!);
                        }
                        // Pop back to previous screen and signal that caller should refresh.
                        if (mounted) Navigator.of(context).pop(true);
                      } catch (e) {
                        debugPrint('Failed to delete loan: $e');
                        if (mounted)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('خطا هنگام حذف')),
                          );
                      }
                    }
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: Text('ویرایش وام')),
                  const PopupMenuItem(value: 'delete', child: Text('حذف وام')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan.title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cp?.name ?? 'نامشخص',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(_directionText(loan.direction)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'مبلغ اصلی: ${formatCurrency(loan.principalAmount)}',
                          ),
                          Text(
                            'تعداد اقساط: ${toPersianDigits(loan.installmentCount)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'مبلغ قسط: ${formatCurrency(loan.installmentAmount)}',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'شروع: ${formatJalaliForDisplay(parseJalali(loan.startDateJalali))}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'اقساط',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              ...installments.map((inst) {
                final due = formatJalaliForDisplay(
                  parseJalali(inst.dueDateJalali),
                );
                final paid = inst.status == InstallmentStatus.paid;
                return Card(
                  child: ListTile(
                    title: Text(due),
                    subtitle: Text(
                      _statusText(inst.status) +
                          (paid && inst.paidAt != null
                              ? ' • ${inst.paidAt}'
                              : ''),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      formatCurrency(inst.amount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    leading: IconButton(
                      icon: Icon(
                        paid
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: paid ? Colors.green : null,
                      ),
                      onPressed: paid
                          ? null
                          : () async {
                              await _markPaid(inst);
                            },
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
