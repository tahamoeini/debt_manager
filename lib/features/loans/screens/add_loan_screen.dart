// ignore_for_file: use_build_context_synchronously, deprecated_member_use

// Add loan screen: form for creating a loan and its installments.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/notifications/notification_ids.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';

class AddLoanScreen extends ConsumerStatefulWidget {
  // If [existingLoan] is provided the screen operates in edit mode and will
  // update the loan metadata instead of creating a new loan and installments.
  final Loan? existingLoan;
  final Counterparty? existingCounterparty;

  const AddLoanScreen({
    super.key,
    this.existingLoan,
    this.existingCounterparty,
  });

  @override
  ConsumerState<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends ConsumerState<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _counterpartyController = TextEditingController();
  final _counterpartyTagController = TextEditingController();
  final _titleController = TextEditingController();
  final _principalController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _notesController = TextEditingController();

  LoanDirection _direction = LoanDirection.borrowed;
  Jalali? _startJalali;
  bool _isSubmitting = false;
  String? _counterpartyType; // 'person' | 'bank' | 'company'
  late FocusNode _titleFocus;
  bool _isDirty = false;
  bool _disburseNow = false;
  int? _disburseAccountId;
  List<Budget> _accounts = [];

  // Use repository via Riverpod when performing DB operations

  bool get _isEdit => widget.existingLoan != null;

  @override
  void initState() {
    super.initState();

    final loan = widget.existingLoan;
    final cp = widget.existingCounterparty;

    if (loan != null) {
      _titleController.text = loan.title;
      _principalController.text = loan.principalAmount.toString();
      _installmentCountController.text = loan.installmentCount.toString();
      _installmentAmountController.text = loan.installmentAmount.toString();
      _notesController.text = loan.notes ?? '';
      _direction = loan.direction;
      try {
        _startJalali = parseJalali(loan.startDateJalali);
      } catch (_) {}
    }

    if (cp != null) {
      _counterpartyController.text = cp.name;
      _counterpartyType = cp.type;
      _counterpartyTagController.text = cp.tag ?? '';
    }
    _titleFocus = FocusNode();
    _counterpartyController.addListener(() => _markDirty());
    _titleController.addListener(() => _markDirty());
    _principalController.addListener(() => _markDirty());
    _installmentCountController.addListener(() => _markDirty());
    _installmentAmountController.addListener(() => _markDirty());
    _notesController.addListener(() => _markDirty());
    _counterpartyTagController.addListener(() => _markDirty());
    // Load available budgets/accounts for optional disbursement target
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final repo = ref.read(budgetsRepositoryProvider);
        final list = await repo.getAllBudgets();
        if (!mounted) return;
        setState(() => _accounts = list);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _counterpartyController.dispose();
    _counterpartyTagController.dispose();
    _titleController.dispose();
    _principalController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    _notesController.dispose();
    _titleFocus.dispose();
    super.dispose();
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _startJalali = dateTimeToJalali(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      // Determine or create counterparty. When editing, prefer keeping the
      // existing counterparty id if the name was not changed.
      final rawCp = _counterpartyController.text.trim();
      final cpName = rawCp.isEmpty ? 'نامشخص' : rawCp;
      final cpTagRaw = _counterpartyTagController.text.trim();
      final cpTag = cpTagRaw.isEmpty ? null : cpTagRaw;
      int cpId;
      final repo = ref.read(loanRepositoryProvider);
      if (_isEdit &&
          widget.existingCounterparty != null &&
          widget.existingCounterparty!.name == cpName &&
          widget.existingCounterparty!.id != null) {
        cpId = widget.existingCounterparty!.id!;
      } else {
        cpId = await repo.insertCounterparty(
          Counterparty(name: cpName, type: _counterpartyType, tag: cpTag),
        );
      }

      // Parse numeric fields
      var principal = int.tryParse(_principalController.text.trim()) ?? 0;
      final installmentCount =
          int.tryParse(_installmentCountController.text.trim()) ?? 0;
      var installmentAmount =
          int.tryParse(_installmentAmountController.text.trim()) ?? 0;

      // If both installment count and amount are positive, check consistency
      if (installmentCount > 0 && installmentAmount > 0) {
        final expectedTotal = installmentCount * installmentAmount;
        if (expectedTotal != principal) {
          final choice = await showDialog<int>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('عدم تطابق مبلغ'),
              content: Text(
                'مبلغ اصلی (\uFEFF$principal) برابر نیست با حاصل‌ضرب تعداد اقساط در مبلغ هر قسط (\uFEFF$expectedTotal). لطفاً نحوه هماهنگ‌سازی را انتخاب کنید.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(1),
                  child: const Text('هماهنگ‌سازی اصل وام با اقساط'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(2),
                  child: const Text('محاسبه مبلغ قسط'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(3),
                  child: const Text('ادامه بدون تغییر'),
                ),
              ],
            ),
          );

          if (!mounted) return;

          if (choice == 1) {
            principal = expectedTotal;
            _principalController.text = principal.toString();
          } else if (choice == 2) {
            installmentAmount = (principal / installmentCount).round();
            _installmentAmountController.text = installmentAmount.toString();
          }
        }
      }

      final createdAt = DateTime.now().toIso8601String();
      final startDateJalaliStr = formatJalali(_startJalali!);

      if (_isEdit) {
        // Update existing loan metadata only; do not touch installments.
        final existing = widget.existingLoan!;
        final updated = existing.copyWith(
          counterpartyId: cpId,
          title: _titleController.text.trim(),
          direction: _direction,
          principalAmount: principal,
          installmentCount: installmentCount,
          installmentAmount: installmentAmount,
          startDateJalali: startDateJalaliStr,
          notes: _notesController.text.trim(),
        );

        await repo.updateLoan(updated);
      } else {
        // Create new loan and its installments.
        final loan = Loan(
          counterpartyId: cpId,
          title: _titleController.text.trim(),
          direction: _direction,
          principalAmount: principal,
          installmentCount: installmentCount,
          installmentAmount: installmentAmount,
          startDateJalali: startDateJalaliStr,
          notes: _notesController.text.trim(),
          createdAt: createdAt,
        );

        final loanId = _disburseNow && _disburseAccountId != null
          ? await repo.disburseLoan(loan, accountId: _disburseAccountId)
          : await repo.insertLoan(loan);

        // Load settings (reminder offset) once per submission and generate installments.
        int offsetDays = 3;
        final settingsRepo = SettingsRepository();
        try {
          offsetDays = await settingsRepo.getReminderOffsetDays();
        } catch (e) {
          debugPrint('Failed to get reminder offset, using default: $e');
          offsetDays = 3;
        }

        final schedule = generateMonthlySchedule(
          _startJalali!,
          installmentCount,
        );

        for (final dueJalali in schedule) {
          final dueStr = formatJalali(dueJalali);
          final inst = Installment(
            loanId: loanId,
            dueDateJalali: dueStr,
            amount: installmentAmount,
            status: InstallmentStatus.pending,
            paidAt: null,
            notificationId: null,
          );

          final instId = await repo.insertInstallment(inst);

          final dueGregorian = jalaliToDateTime(dueJalali);
          final scheduledBase = dueGregorian.subtract(
            Duration(days: offsetDays),
          );
          final scheduledTime = DateTime(
            scheduledBase.year,
            scheduledBase.month,
            scheduledBase.day,
            9,
            0,
          );

          try {
            final mappedId = NotificationIds.forInstallment(instId);
            await NotificationService().scheduleInstallmentReminder(
              notificationId: mappedId,
              scheduledTime: scheduledTime,
              title: 'یادآور اقساط',
              body:
                  '${loan.title} - تاریخ: ${formatJalaliForDisplay(dueJalali)}',
            );

            final updated = inst.copyWith(notificationId: mappedId);
            await repo.updateInstallment(updated.copyWith(id: instId));
          } catch (_) {
            // ignore notification failures for now
          }
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      debugPrint('AddLoanScreen _submit error: $e');
      if (mounted) UIUtils.showAppSnackBar(context, 'خطا هنگام ذخیره');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
      // Ensure scheduled notifications are consistent after changes
      try {
        await NotificationService().rebuildScheduledNotifications();
      } catch (e) {
        debugPrint('Failed to rebuild scheduled notifications: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: Text(_isEdit ? 'ویرایش وام' : 'افزودن وام')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  // Direction
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<LoanDirection>(
                          title: const Text('گرفته‌ام'),
                          value: LoanDirection.borrowed,
                          groupValue: _direction,
                          onChanged: (v) => setState(() => _direction = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<LoanDirection>(
                          title: const Text('داده‌ام'),
                          value: LoanDirection.lent,
                          groupValue: _direction,
                          onChanged: (v) => setState(() => _direction = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _counterpartyController,
                    decoration: const InputDecoration(
                      labelText: 'طرف مقابل',
                      hintText: 'نام شخص یا موسسه',
                    ),
                    autofocus: !_isEdit,
                    focusNode: _titleFocus,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'لطفا طرف مقابل را وارد کنید'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: DropdownButtonFormField<String?>(
                          value: _counterpartyType,
                          decoration: const InputDecoration(labelText: 'نوع'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('بدون')),
                            DropdownMenuItem(
                              value: 'person',
                              child: Text('شخص'),
                            ),
                            DropdownMenuItem(
                              value: 'bank',
                              child: Text('بانک'),
                            ),
                            DropdownMenuItem(
                              value: 'company',
                              child: Text('شرکت'),
                            ),
                          ],
                          onChanged: (v) =>
                              setState(() => _counterpartyType = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _counterpartyTagController,
                          decoration: const InputDecoration(
                            labelText: 'برچسب (اختیاری)',
                            hintText: 'مثال: کارت اعتباری, خانواده',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'عنوان وام',
                      hintText: 'مثال: وام خرید خودرو',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'لطفا عنوان وام را وارد کنید'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _principalController,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ اصلی (ریال)',
                      hintText: 'مثلا: 10000000',
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'لطفا مبلغ را وارد کنید';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) {
                        return 'لطفا عدد معتبر وارد کنید';
                      }
                      if (parsed <= 0) {
                        return 'مبلغ باید بیشتر از صفر باشد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _installmentCountController,
                    decoration: const InputDecoration(
                      labelText: 'تعداد اقساط',
                      hintText: 'مثلا: 12',
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'لطفا تعداد اقساط را وارد کنید';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) {
                        return 'لطفا عدد معتبر وارد کنید';
                      }
                      if (parsed < 1) {
                        return 'تعداد باید حداقل 1 باشد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _installmentAmountController,
                    decoration: const InputDecoration(
                      labelText: 'مبلغ هر قسط (ریال)',
                      hintText: 'مثلا: 1000000',
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'لطفا مبلغ قسط را وارد کنید';
                      }
                      final parsed = int.tryParse(v.trim());
                      if (parsed == null) {
                        return 'لطفا عدد معتبر وارد کنید';
                      }
                      if (parsed <= 0) {
                        return 'مبلغ باید بیشتر از صفر باشد';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'یادداشت (اختیاری)',
                      hintText: 'جزئیات بیشتر درباره وام',
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  FormField<String>(
                    validator: (v) => _startJalali == null
                        ? 'لطفا تاریخ شروع را انتخاب کنید'
                        : null,
                    builder: (state) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _startJalali == null
                                      ? 'تاریخ شروع انتخاب نشده'
                                      : 'شروع: ${formatJalaliForDisplay(_startJalali!)}',
                                ),
                              ),
                              FilledButton(
                                onPressed: () async {
                                  await _pickStartDate();
                                  state.validate();
                                },
                                child: const Text('انتخاب تاریخ'),
                              ),
                            ],
                          ),
                          if (state.hasError)
                            Padding(
                              padding: const EdgeInsets.only(
                                top: 6.0,
                                left: 4.0,
                              ),
                              child: Text(
                                state.errorText ?? '',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    title: const Text('پرداخت/دریافت وجه (پرداخت الآن)'),
                    value: _disburseNow,
                    onChanged: (v) => setState(() => _disburseNow = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                  if (_disburseNow)
                    DropdownButtonFormField<int>(
                      value: _disburseAccountId,
                      decoration: const InputDecoration(labelText: 'حساب مقصد'),
                      items: _accounts
                          .map(
                            (b) => DropdownMenuItem<int>(
                              value: b.id,
                              child: Text(b.category ?? 'Primary account'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (v) => setState(() => _disburseAccountId = v),
                      validator: (v) => _disburseNow && v == null ? 'لطفا حساب را انتخاب کنید' : null,
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('ثبت وام'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
