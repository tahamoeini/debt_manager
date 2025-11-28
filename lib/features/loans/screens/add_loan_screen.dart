import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../../core/notifications/notification_service.dart';
import '../../loans/models/counterparty.dart';
import '../../loans/models/loan.dart';
import '../../loans/models/installment.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AddLoanScreen extends StatefulWidget {
  const AddLoanScreen({super.key});

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _counterpartyController = TextEditingController();
  final _titleController = TextEditingController();
  final _principalController = TextEditingController();
  final _installmentCountController = TextEditingController();
  final _installmentAmountController = TextEditingController();
  final _notesController = TextEditingController();

  LoanDirection _direction = LoanDirection.borrowed;
  Jalali? _startJalali;
  bool _isSubmitting = false;

  final _db = DatabaseHelper.instance;

  @override
  void dispose() {
    _counterpartyController.dispose();
    _titleController.dispose();
    _principalController.dispose();
    _installmentCountController.dispose();
    _installmentAmountController.dispose();
    _notesController.dispose();
    super.dispose();
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
      setState(() {
        _startJalali = dateTimeToJalali(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startJalali == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا تاریخ شروع را انتخاب کنید')));
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // Insert counterparty (fallback if empty)
      final rawCp = _counterpartyController.text.trim();
      final cpName = rawCp.isEmpty ? 'نامشخص' : rawCp;
      final cpId = await _db.insertCounterparty(Counterparty(name: cpName));

      // Parse numeric fields
      final principal = int.tryParse(_principalController.text.trim()) ?? 0;
      final installmentCount = int.tryParse(_installmentCountController.text.trim()) ?? 0;
      final installmentAmount = int.tryParse(_installmentAmountController.text.trim()) ?? 0;

      final createdAt = DateTime.now().toIso8601String();
      final startDateJalaliStr = formatJalali(_startJalali!);

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

      final loanId = await _db.insertLoan(loan);

      // Generate installments
      final schedule = generateMonthlySchedule(_startJalali!, installmentCount);

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

        final instId = await _db.insertInstallment(inst);

        // Schedule notification 3 days before at 9:00 AM
        final dueGregorian = jalaliToDateTime(dueJalali);
        final scheduledBase = dueGregorian.subtract(const Duration(days: 3));
        final scheduledTime = DateTime(scheduledBase.year, scheduledBase.month, scheduledBase.day, 9, 0);

        try {
          await NotificationService().scheduleInstallmentReminder(
            notificationId: instId,
            scheduledTime: scheduledTime,
            title: 'یادآور اقساط',
            body: '${loan.title} - تاریخ: ${formatJalaliForDisplay(dueJalali)}',
          );

          // Update installment with notification ID
          final updated = inst.copyWith(notificationId: instId);
          await _db.updateInstallment(updated.copyWith(id: instId));
        } catch (_) {
          // ignore notification failures for now
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خطا هنگام ذخیره')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('افزودن وام')),
      body: Padding(
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
                decoration: const InputDecoration(labelText: 'طرف مقابل'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'نام طرف مقابل لازم است' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'عنوان وام'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'عنوان لازم است' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _principalController,
                decoration: const InputDecoration(labelText: 'مبلغ اصلی (عدد)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'مقدار عددی وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _installmentCountController,
                decoration: const InputDecoration(labelText: 'تعداد اقساط'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'مقدار عددی وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _installmentAmountController,
                decoration: const InputDecoration(labelText: 'مبلغ هر قسط (عدد)'),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || int.tryParse(v.trim()) == null) ? 'مقدار عددی وارد کنید' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'یادداشت (اختیاری)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(_startJalali == null ? 'تاریخ شروع انتخاب نشده' : 'شروع: ${formatJalaliForDisplay(_startJalali!)}'),
                  ),
                  ElevatedButton(onPressed: _pickStartDate, child: const Text('انتخاب تاریخ')),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting ? const CircularProgressIndicator() : const Text('ثبت وام'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
