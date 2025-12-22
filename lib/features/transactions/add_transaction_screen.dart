import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/calendar_utils.dart';
import 'package:debt_manager/core/utils/calendar_picker.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/features/finance/finance_repository.dart';
import 'package:debt_manager/features/finance/models/finance_models.dart';
import 'package:debt_manager/features/ledger/models/ledger_entry.dart';

class AddTransactionScreen extends ConsumerStatefulWidget {
  final int? presetAccountId;
  final int? presetCategoryId;
  final String? presetCategoryName;

  const AddTransactionScreen({
    super.key,
    this.presetAccountId,
    this.presetCategoryId,
    this.presetCategoryName,
  });

  @override
  ConsumerState<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends ConsumerState<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  int? _selectedAccountId;
  int? _selectedCategoryId;
  String _direction = 'debit';
  final _amountCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  List<Account> _accounts = [];
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final repo = ref.read(financeRepositoryProvider);
        final accs = await repo.getAccounts();
        final cats = await repo.getCategories();
        if (!mounted) return;
        setState(() {
          _accounts = accs;
          _categories = cats;
          if (widget.presetAccountId != null) {
            _selectedAccountId = widget.presetAccountId;
          } else if (_accounts.isNotEmpty) {
            _selectedAccountId = _accounts.first.id;
          }

          if (widget.presetCategoryId != null) {
            _selectedCategoryId = widget.presetCategoryId;
          } else if (widget.presetCategoryName != null) {
            final idx = _categories.indexWhere((c) =>
                c.name.toLowerCase() == widget.presetCategoryName!.toLowerCase());
            if (idx != -1) _selectedCategoryId = _categories[idx].id;
          }
        });
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final amt = int.tryParse(_amountCtrl.text.trim()) ?? 0;
    if (amt <= 0) return;

    final txn = <String, dynamic>{
      'timestamp': _selectedDate.toIso8601String(),
      'amount': amt,
      'direction': _direction,
      'account_id': _selectedAccountId,
      'description': _descCtrl.text.trim(),
      'source': 'manual',
    };
    if (_selectedCategoryId != null) txn['category_id'] = _selectedCategoryId;

    try {
      final id = await DatabaseHelper.instance.insertTransaction(txn);

      // Also upsert a matching ledger entry for reporting (optional)
      final j = dateTimeToJalali(_selectedDate);
      final dateJ = formatJalali(j);
      final ledgerAmount = _direction == 'credit' ? amt : -amt;
      final entry = LedgerEntry(
        amount: ledgerAmount,
        categoryId: _selectedCategoryId,
        refType: 'transaction',
        refId: id,
        dateJalali: dateJ,
        note: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
      );
      await DatabaseHelper.instance.upsertLedgerEntry(entry);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا هنگام ذخیره تراکنش: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('افزودن تراکنش')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropdownButtonFormField<int?>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(labelText: 'حساب'),
                  items: _accounts
                      .map((a) => DropdownMenuItem<int?>(value: a.id, child: Text(a.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedAccountId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('برداشت'),
                        value: 'debit',
                        groupValue: _direction,
                        onChanged: (v) => setState(() => _direction = v ?? 'debit'),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('واریز'),
                        value: 'credit',
                        groupValue: _direction,
                        onChanged: (v) => setState(() => _direction = v ?? 'debit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'مبلغ'),
                  validator: (v) => (v?.trim().isEmpty ?? true) ? 'مقدار را وارد کنید' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descCtrl,
                  decoration: const InputDecoration(labelText: 'توضیحات (اختیاری)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'دسته‌بندی (اختیاری)'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('بدون دسته‌بندی'),
                    ),
                    ..._categories
                        .where((c) => c.id != null)
                        .map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                  ],
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<CalendarType>(
                        valueListenable: SettingsRepository.calendarTypeNotifier,
                        builder: (context, calType, _) {
                          return Text(
                            'تاریخ: ${formatDateForDisplayWithCalendar(_selectedDate, calType)}',
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        final picked = await showCalendarAwareDatePicker(
                          context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(1900),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        // Convert to DateTime if Jalali returned
                        if (picked is Jalali) {
                          setState(() => _selectedDate = jalaliToDateTime(picked));
                        } else if (picked is DateTime) {
                          setState(() => _selectedDate = picked);
                        } else {
                          debugPrint('Unexpected date type from showCalendarAwareDatePicker: ${picked.runtimeType}');
                        }
                      },
                      child: const Text('انتخاب'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('ذخیره تراکنش'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
