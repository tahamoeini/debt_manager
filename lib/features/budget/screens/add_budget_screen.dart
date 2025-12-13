import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/widgets/form_inputs.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

class AddBudgetScreen extends ConsumerStatefulWidget {
  final Budget? budget;
  const AddBudgetScreen({super.key, this.budget});

  @override
  ConsumerState<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends ConsumerState<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  bool _rollover = false;

  String _currentPeriod() {
    final j = dateTimeToJalali(DateTime.now());
    final y = j.year.toString().padLeft(4, '0');
    final m = j.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _categoryCtrl.text = widget.budget!.category ?? '';
      _amountCtrl.text = (widget.budget!.amount / 100).toStringAsFixed(2);
      _periodCtrl.text = widget.budget!.period;
      _rollover = widget.budget!.rollover;
    } else {
      _periodCtrl.text = _currentPeriod();
    }
  }

  @override
  void dispose() {
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _periodCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final category =
        _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();
    final amountDouble =
        double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;
    final amount = (amountDouble * 100).round();
    final period = _periodCtrl.text.trim();
    final createdAt = formatJalali(dateTimeToJalali(DateTime.now()));

    final budget = Budget(
      id: widget.budget?.id,
      category: category,
      amount: amount,
      period: period,
      rollover: _rollover,
      createdAt: createdAt,
    );

    try {
      if (widget.budget == null) {
        final repo = ref.read(budgetsRepositoryProvider);
        await repo.insertBudget(budget);
        if (!mounted) return;
        UIUtils.showAppSnackBar(context, 'بودجه ذخیره شد');
      } else {
        final repo = ref.read(budgetsRepositoryProvider);
        await repo.updateBudget(budget);
        if (!mounted) return;
        UIUtils.showAppSnackBar(context, 'تغییرات ذخیره شد');
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      UIUtils.showAppSnackBar(context, 'خطا در ذخیره‌سازی بودجه');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budget != null;

    final form = Form(
      key: _formKey,
      child: ListView(
        children: [
          FormInput(
              controller: _categoryCtrl,
              label: 'دسته‌بندی (اختیاری)',
              icon: Icons.category),
          const SizedBox(height: AppConstants.spaceMedium),
          FormInput(
            controller: _amountCtrl,
            label: 'مبلغ (واحد اصلی)',
            icon: Icons.attach_money,
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final d = double.tryParse(v?.replaceAll(',', '') ?? '');
              if (d == null || d <= 0) return 'مبلغ نامعتبر است';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spaceMedium),
          FormInput(
            controller: _periodCtrl,
            label: 'بازه (yyyy-MM)',
            icon: Icons.calendar_month,
            validator: (v) {
              if (v == null || v.isEmpty) return 'بازه را وارد کنید';
              final parts = v.split('-');
              if (parts.length != 2) return 'فرمت باید yyyy-MM باشد';
              return null;
            },
          ),
          const SizedBox(height: AppConstants.spaceMedium),
          SwitchListTile(
              value: _rollover,
              onChanged: (v) => setState(() => _rollover = v),
              title: const Text('انتقال به دوره بعدی')),
          const SizedBox(height: AppConstants.spaceXLarge),
          Row(
            children: [
              Expanded(
                  child: FilledButton(
                      onPressed: _save, child: const Text('ذخیره'))),
              const SizedBox(width: AppConstants.spaceMedium),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('لغو'))),
            ],
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'ویرایش بودجه' : 'افزودن بودجه')),
      body: SafeArea(
          child: Padding(padding: AppConstants.pagePadding, child: form)),
    );
  }
}
