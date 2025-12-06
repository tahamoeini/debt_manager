import 'package:flutter/material.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';

class AddBudgetScreen extends StatefulWidget {
  final Budget? budget;
  const AddBudgetScreen({Key? key, this.budget}) : super(key: key);

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _periodCtrl = TextEditingController();
  bool _rollover = false;
  final _repo = BudgetsRepository();

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
    final category = _categoryCtrl.text.trim().isEmpty ? null : _categoryCtrl.text.trim();
    final amountDouble = double.tryParse(_amountCtrl.text.replaceAll(',', '')) ?? 0.0;
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
        await _repo.insertBudget(budget);
        UIUtils.showAppSnackBar(context, 'بودجه ذخیره شد');
      } else {
        await _repo.updateBudget(budget);
        UIUtils.showAppSnackBar(context, 'تغییرات ذخیره شد');
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      UIUtils.showAppSnackBar(context, 'خطا در ذخیره‌سازی بودجه');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.budget != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'ویرایش بودجه' : 'افزودن بودجه')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _categoryCtrl,
                decoration: const InputDecoration(labelText: 'دسته‌بندی (اختیاری)'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(labelText: 'مبلغ (واحد اصلی)'),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  final d = double.tryParse(v?.replaceAll(',', '') ?? '');
                  if (d == null || d <= 0) return 'مبلغ نامعتبر است';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _periodCtrl,
                decoration: const InputDecoration(labelText: 'بازه (yyyy-MM)'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'بازه را وارد کنید';
                  final parts = v.split('-');
                  if (parts.length != 2) return 'فرمت باید yyyy-MM باشد';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _rollover,
                onChanged: (v) => setState(() => _rollover = v),
                title: const Text('انتقال به دوره بعدی'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      child: const Text('ذخیره'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('لغو'),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
