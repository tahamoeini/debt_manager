// Loan detail screen: shows loan details and its installments and actions.
// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/utils/celebration_utils.dart';
import 'package:debt_manager/features/achievements/achievements_repository.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/loans/loan_detail_notifier.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:go_router/go_router.dart';
import 'package:debt_manager/features/finance/finance_repository.dart';
import 'package:debt_manager/features/finance/models/finance_models.dart';

// Delay before showing celebration to allow UI to update
const Duration _celebrationDelay = Duration(milliseconds: 300);

class LoanDetailScreen extends ConsumerStatefulWidget {
  const LoanDetailScreen({super.key, required this.loanId});

  final int loanId;

  @override
  ConsumerState<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends ConsumerState<LoanDetailScreen> {
  // Safe parser for Jalali dates - returns current date if parsing fails
  Jalali _parseJalaliSafe(String jalaliStr) {
    try {
      return parseJalali(jalaliStr);
    } catch (_) {
      return dateTimeToJalali(DateTime.now());
    }
  }

  // Data provided through [loanDetailProvider]

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

  // Removed unused _markPaid method.

  Future<void> _showEditInstallmentSheet(Installment inst) async {
    final now = DateTime.now();
    var isPaid = inst.status == InstallmentStatus.paid;
    final amountController = TextEditingController(
      text: inst.actualPaidAmount?.toString() ?? inst.amount.toString(),
    );
    // Initial selected Jalali date - with error handling
    Jalali selectedJalali = _parseJalaliSafe(inst.dueDateJalali);
    // Load categories for optional tagging of this payment
    List<Category> _sheetCategories = [];
    try {
      final frepo = ref.read(financeRepositoryProvider);
      _sheetCategories = await frepo.getCategories();
    } catch (_) {
      _sheetCategories = [];
    }
    int? _selectedCategory;

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
                    // Category selector for this payment (optional)
                    if (_sheetCategories.isNotEmpty)
                      DropdownButtonFormField<int?>(
                        value: null,
                        decoration: const InputDecoration(labelText: 'دسته‌بندی پرداخت (اختیاری)'),
                        items: _sheetCategories
                            .map((c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) => setInnerState(() => _selectedCategory = v),
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
                        FilledButton(
                          onPressed: () async {
                            // Capture navigator context for bottom sheet

                            // Build updated installment
                            final entered = amountController.text.trim();
                            final actualAmt =
                                entered.isEmpty ? null : int.tryParse(entered);

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
                              paidAtJalali: isPaid
                                  ? formatJalali(
                                      dateTimeToJalali(DateTime.now()),
                                    )
                                  : null,
                              actualPaidAmount:
                                  actualAmt ?? inst.actualPaidAmount,
                            );

                            // Capture navigator for the bottom sheet before awaiting
                            final sheetNavigator = Navigator.of(ctx);

                            // If marking as paid, check budgets for the paid period
                            if (isPaid) {
                              try {
                                final paidDate = DateTime.now();
                                final j = dateTimeToJalali(paidDate);
                                final period =
                                    '${j.year.toString().padLeft(4, '0')}-${j.month.toString().padLeft(2, '0')}';

                                final repo = BudgetsRepository();
                                final budgets = await repo.getBudgetsByPeriod(
                                  period,
                                );

                                final amountPaid = actualAmt ??
                                    inst.actualPaidAmount ??
                                    inst.amount;

                                final exceeded = <Budget>[];
                                for (final b in budgets) {
                                  final used = await repo.computeUtilization(b);
                                  if ((used + amountPaid) > b.amount) {
                                    exceeded.add(b);
                                  }
                                }

                                if (exceeded.isNotEmpty) {
                                  final b = exceeded.first;
                                  final title = b.category ?? 'عمومی';
                                  final used = await repo.computeUtilization(b);
                                  final projected = used + amountPaid;
                                  if (!mounted) return;
                                  final proceed = await showDialog<bool>(
                                    context: context,
                                    builder: (dctx) => AlertDialog(
                                      title: const Text('هشدار بودجه'),
                                      content: Text(
                                        'این پرداخت باعث می‌شود بودجه "$title" از حد تعیین‌شده فراتر رود:\n\n'
                                        'بودجه: ${formatCurrency(b.amount)}\n'
                                        'استفاده تا کنون: ${formatCurrency(used)}\n'
                                        'پس از پرداخت: ${formatCurrency(projected)}\n\n'
                                        'آیا مایل به ادامه هستید؟',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(dctx).pop(false),
                                          child: const Text('انصراف'),
                                        ),
                                        FilledButton(
                                          onPressed: () =>
                                              Navigator.of(dctx).pop(true),
                                          child: const Text('ادامه'),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (proceed != true) {
                                    // User cancelled; do not save
                                    return;
                                  }
                                }
                              } catch (_) {
                                // On any error, fall back to saving without blocking.
                              }
                            }

                            // Persist via provider notifier
                            await ref
                                .read(
                                  loanDetailProvider(widget.loanId).notifier,
                                )
                                .updateInstallment(updated);

                            // If user selected a category for this payment, persist it on the ledger entry
                            if (_selectedCategory != null && inst.id != null) {
                              try {
                                await DatabaseHelper.instance.setLedgerEntryCategoryByRef(
                                  'installment_payment',
                                  inst.id!,
                                  _selectedCategory!,
                                );
                              } catch (_) {}
                            }

                            // Cancel notifications if marking paid
                            if (isPaid && inst.id != null) {
                              try {
                                // Get offset days from settings to cancel all notifications
                                final settings = SettingsRepository();
                                final maxOffsetDays =
                                    await settings.getReminderOffsetDays();
                                await NotificationService()
                                    .cancelInstallmentNotifications(
                                  inst.id!,
                                  maxOffsetDays,
                                );
                              } catch (_) {}
                            }

                            // Check if all installments are now paid and celebrate!
                            if (isPaid) {
                              final allInst = ref
                                      .read(loanDetailProvider(widget.loanId))
                                      .value
                                      ?.installments ??
                                  [];
                              final allPaid = allInst.every(
                                (i) => i.status == InstallmentStatus.paid,
                              );
                              if (allPaid) {
                                if (!mounted) {
                                  // Widget disposed; bail out
                                } else {
                                  // Allow UI a short delay before showing celebration
                                  await Future.delayed(_celebrationDelay);
                                  if (!mounted) return;
                                  showDebtCompletionCelebration(context);
                                  try {
                                    final newly = await AchievementsRepository
                                        .instance
                                        .handlePayment(
                                      loanId: widget.loanId,
                                      paidAt: DateTime.now(),
                                    );
                                    if (!mounted) return;
                                    if (newly.isNotEmpty) {
                                      for (final a in newly) {
                                        showAchievementDialog(
                                          context,
                                          title: a.title,
                                          message: a.message,
                                        );
                                      }
                                    }
                                  } catch (_) {}
                                }
                              }
                            }

                            // Notifier has refreshed state already.
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
    final async = ref.watch(loanDetailProvider(widget.loanId));
    return async.when(
      loading: () => Scaffold(body: SafeArea(child: UIUtils.centeredLoading())),
      error: (e, st) {
        debugPrint('LoanDetailScreen error: $e');
        return Scaffold(body: SafeArea(child: UIUtils.asyncErrorWidget(e)));
      },
      data: (data) {
        final loan = data.loan;
        final cp = data.counterparty;
        final installments = data.installments;

        if (loan == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('جزئیات وام')),
            body: SafeArea(child: const Center(child: Text('وام یافت نشد'))),
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
                    final res = await context.pushNamed<bool?>(
                      'loanEdit',
                      pathParameters: {
                        'loanId': (loan.id ?? widget.loanId).toString(),
                      },
                      extra: {
                        'loan': loan,
                        'counterparty': cp,
                      },
                    );

                    if (!mounted) return;

                    if (res == true) {
                      // Editing was successful: refresh global loans list and
                      // pop this detail screen.
                      ref.read(loanListProvider(null).notifier).refresh();
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
                          await ref
                              .read(loanDetailProvider(widget.loanId).notifier)
                              .deleteLoan(loan.id!);
                        }

                        if (!mounted) return;

                        // Refresh list and pop back to previous screen.
                        ref.read(loanListProvider(null).notifier).refresh();
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
          body: SafeArea(
            child: ListView(
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
                        const SizedBox(height: 12),
                        // Transactions linked to this loan (disbursement, fees, etc.)
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: DatabaseHelper.instance
                              .getTransactionsByRelated('loan', loan.id ?? -1),
                          builder: (ctx, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const SizedBox.shrink();
                            }
                            final txns = snap.data ?? [];
                            if (txns.isEmpty) return const SizedBox.shrink();
                            return Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'تراکنش‌ها',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    ...txns.map((t) {
                                      final ts =
                                          t['timestamp'] as String? ?? '';
                                      final dir =
                                          t['direction'] as String? ?? '';
                                      final amt = t['amount'];
                                      final desc =
                                          t['description'] as String? ?? '';
                                      return ListTile(
                                        dense: true,
                                        title:
                                            Text(desc.isNotEmpty ? desc : ts),
                                        subtitle: Text(ts),
                                        trailing: Text(
                                          "${dir == 'credit' ? '+' : '-'} ${formatCurrency(amt is int ? amt : int.tryParse('$amt') ?? 0)}",
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
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
                          'شروع: ${formatJalaliForDisplay(_parseJalaliSafe(loan.startDateJalali))}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'اقساط',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                ...installments.map(
                  (inst) => Card(
                    child: ExpansionTile(
                      title: Text(
                        formatJalaliForDisplay(
                          _parseJalaliSafe(inst.dueDateJalali),
                        ),
                      ),
                      subtitle: Text(_statusText(inst.status)),
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _showEditInstallmentSheet(inst),
                              ),
                            ],
                          ),
                        ),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: DatabaseHelper.instance
                              .getTransactionsByRelated(
                                  'installment', inst.id ?? -1),
                          builder: (c, s) {
                            if (s.connectionState != ConnectionState.done) {
                              return const SizedBox.shrink();
                            }
                            final list = s.data ?? [];
                            if (list.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return Column(
                              children: list.map((t) {
                                final ts = t['timestamp'] as String? ?? '';
                                final dir = t['direction'] as String? ?? '';
                                final amt = t['amount'];
                                final desc = t['description'] as String? ?? '';
                                return ListTile(
                                  dense: true,
                                  title: Text(desc.isNotEmpty ? desc : ts),
                                  subtitle: Text(ts),
                                  trailing: Text(
                                    "${dir == 'credit' ? '+' : '-'} ${formatCurrency(amt is int ? amt : int.tryParse('$amt') ?? 0)}",
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
