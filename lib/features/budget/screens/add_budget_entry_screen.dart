import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/budget/models/budget_entry.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

class AddBudgetEntryScreen extends ConsumerStatefulWidget {
  final BudgetEntry? entry;
  final String? presetCategory;
  final String? presetPeriod;

  const AddBudgetEntryScreen({
    super.key,
    this.entry,
    this.presetCategory,
    this.presetPeriod,
  });

  @override
  ConsumerState<AddBudgetEntryScreen> createState() =>
      _AddBudgetEntryScreenState();
}

class _AddBudgetEntryScreenState extends ConsumerState<AddBudgetEntryScreen> {
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _isOneOff = false;

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      _categoryCtrl.text = widget.entry!.category ?? '';
      _amountCtrl.text = (widget.entry!.amount / 100).toStringAsFixed(2);
      _periodCtrl.text = widget.entry!.period ?? '';
      _dateCtrl.text = widget.entry!.dateJalali ?? '';
      _noteCtrl.text = widget.entry!.note ?? '';
      _isOneOff = widget.entry!.isOneOff;
    } else {
      _periodCtrl.text = widget.presetPeriod ?? _currentPeriod();
      _categoryCtrl.text = widget.presetCategory ?? '';
    }
  }

  String _currentPeriod() {
    final j = dateTimeToJalali(DateTime.now());
    final y = j.year.toString().padLeft(4, '0');
    final m = j.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _periodCtrl.dispose();
    _dateCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = _categoryCtrl.text.trim().isEmpty
        ? null
        : _categoryCtrl.text.trim();
    final amt = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;
    final amount = (amt * 100).round();
    final period = _periodCtrl.text.trim().isEmpty
        ? null
        : _periodCtrl.text.trim();
    final date = _dateCtrl.text.trim().isEmpty ? null : _dateCtrl.text.trim();
    final note = _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim();
    final createdAt = DateTime.now().toIso8601String();

    final entry = BudgetEntry(
      id: widget.entry?.id,
      category: category,
      amount: amount,
      period: period,
      dateJalali: date,
      isOneOff: _isOneOff,
      note: note,
      createdAt: createdAt,
    );

    try {
      final repo = ref.read(budgetsRepositoryProvider);
      if (widget.entry == null) {
        await repo.insertBudgetEntry(entry);
        if (!mounted) return;
        UIUtils.showAppSnackBar(context, 'ورودی بودجه ذخیره شد');
      } else {
        await repo.updateBudgetEntry(entry);
        if (!mounted) return;
        UIUtils.showAppSnackBar(context, 'ورودی بودجه به‌روزرسانی شد');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) UIUtils.showAppSnackBar(context, 'خطا در ذخیره‌سازی ورودی');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'ویرایش ورودی بودجه' : 'افزودن ورودی بودجه'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppConstants.pagePadding,
          child: ListView(
            children: [
              TextField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(
                  labelText: 'دسته‌بندی (اختیاری)',
                ),
              ),
              const SizedBox(height: AppConstants.spaceMedium),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'مبلغ (واحد اصلی)',
                ),
              ),
              const SizedBox(height: AppConstants.spaceMedium),
              SwitchListTile(
                value: _isOneOff,
                onChanged: (v) => setState(() => _isOneOff = v),
                title: const Text('یک‌بار (One-off)'),
              ),
              const SizedBox(height: AppConstants.spaceSmall),
              if (!_isOneOff)
                TextField(
                  controller: _periodCtrl,
                  decoration: const InputDecoration(
                    labelText: 'بازه (yyyy-MM)',
                  ),
                ),
              if (_isOneOff)
                TextField(
                  controller: _dateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'تاریخ (yyyy-MM-dd)',
                  ),
                ),
              const SizedBox(height: AppConstants.spaceMedium),
              TextField(
                controller: _noteCtrl,
                decoration: const InputDecoration(
                  labelText: 'یادداشت (اختیاری)',
                ),
              ),
              const SizedBox(height: AppConstants.spaceXLarge),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('ذخیره'),
                    ),
                  ),
                  const SizedBox(width: AppConstants.spaceMedium),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('لغو'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
