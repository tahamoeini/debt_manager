// Loan detail screen: shows loan details and its installments and actions.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
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

  Future<void> _showEditInstallmentSheet(Installment inst) async {
    final now = DateTime.now();
    var isPaid = inst.status == InstallmentStatus.paid;
    final amountController = TextEditingController(
      text: inst.actualPaidAmount?.toString() ?? inst.amount.toString(),
    );
    // Initial selected Jalali date
    var selectedJalali = parseJalali(inst.dueDateJalali);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setInnerState) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ویرایش قسط',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('نشانه‌گذاری به عنوان پرداخت‌شده'),
                      value: isPaid,
                      onChanged: (v) => setInnerState(() => isPaid = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'مبلغ پرداختی واقعی (اختیاری)',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'تاریخ سررسید: ${formatJalaliForDisplay(selectedJalali)}',
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final initial = jalaliToDateTime(selectedJalali);
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: initial,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setInnerState(() {
                                selectedJalali = dateTimeToJalali(picked);
                              });
                            }
                          },
                          child: const Text('تغییر'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('انصراف'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            // Build updated installment
                            final entered = amountController.text.trim();
                            final actualAmt = entered.isEmpty
                                ? null
                                : int.tryParse(entered);

                            final dueStr = formatJalali(selectedJalali);

                            // Determine status for unpaid case: overdue if past today
                            final todayJ = dateTimeToJalali(now);
                            final todayStr = formatJalali(todayJ);

                            final newStatus = isPaid
                                ? InstallmentStatus.paid
                                : (dueStr.compareTo(todayStr) < 0
                                      ? InstallmentStatus.overdue
                                      : InstallmentStatus.pending);

                            final updated = inst.copyWith(
                              dueDateJalali: dueStr,
                              status: newStatus,
                              paidAt: isPaid
                                  ? DateTime.now().toIso8601String()
                                  : null,
                              actualPaidAmount:
                                  actualAmt ?? inst.actualPaidAmount,
                            );

                            // Capture navigator for the bottom sheet before awaiting
                            final sheetNavigator = Navigator.of(ctx);

                            await _db.updateInstallment(updated);

                            // Cancel notification if marking paid
                            if (isPaid && inst.notificationId != null) {
                              try {
                                await NotificationService().cancelNotification(
                                  inst.notificationId!,
                                );
                              } catch (_) {}
                            }

                            if (mounted) setState(() {});
                            sheetNavigator.pop();
                          },
                          child: const Text('ذخیره'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: UIUtils.centeredLoading());
        }
        if (snapshot.hasError) {
          debugPrint('LoanDetailScreen _loadAll error: ${snapshot.error}');
          return Scaffold(body: UIUtils.asyncErrorWidget(snapshot.error));
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
                  // Capture context-bound helpers once before any awaits
                  final navigator = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  if (v == 'edit') {
                    // Navigate to AddLoanScreen in edit mode.
                    final res = await navigator.push<bool?>(
                      MaterialPageRoute(
                        builder: (_) => AddLoanScreen(
                          existingLoan: loan,
                          existingCounterparty: cp,
                        ),
                      ),
                    );

                    if (!mounted) return;

                    if (res == true) {
                      // Editing was successful: pop this detail screen and signal
                      // the caller (loans list) to refresh.
                      navigator.pop(true);
                      return;
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

                        if (!mounted) return;

                        // Pop back to previous screen and signal that caller should refresh.
                        navigator.pop(true);
                      } catch (e) {
                        debugPrint('Failed to delete loan: $e');
                        if (mounted) {
                          messenger.showSnackBar(
                            const SnackBar(content: Text('خطا هنگام حذف')),
                          );
                        }
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

                // Friendly paid date display
                String paidFriendly = '';
                if (inst.paidAt != null && inst.paidAt!.isNotEmpty) {
                  try {
                    final dt = DateTime.parse(inst.paidAt!);
                    paidFriendly = formatJalaliForDisplay(dateTimeToJalali(dt));
                  } catch (_) {
                    paidFriendly = inst.paidAt!;
                  }
                }

                // Amount display: show scheduled, and if actual present show it too
                final scheduled = formatCurrency(inst.amount);
                final actual = inst.actualPaidAmount != null
                    ? formatCurrency(inst.actualPaidAmount!)
                    : null;

                return Card(
                  child: ListTile(
                    title: Text(due),
                    subtitle: Text(
                      _statusText(inst.status) +
                          (paid && paidFriendly.isNotEmpty
                              ? ' • پرداخت: $paidFriendly'
                              : '') +
                          (actual != null ? ' • واقعی: $actual' : ''),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          scheduled,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () async {
                            await _showEditInstallmentSheet(inst);
                          },
                        ),
                      ],
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
