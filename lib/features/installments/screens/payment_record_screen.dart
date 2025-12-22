import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import '../models/installment_payment.dart';
import '../providers/installment_payments_provider.dart';
import '../../accounts/providers/accounts_provider.dart';
import '../../core/utils/jalali_date_picker.dart';

class PaymentRecordScreen extends ConsumerStatefulWidget {
  final int loanId;
  final int installmentId;
  final double installmentAmount;
  final Jalali dueDate;

  const PaymentRecordScreen({
    required this.loanId,
    required this.installmentId,
    required this.installmentAmount,
    required this.dueDate,
    Key? key,
  }) : super(key: key);

  @override
  ConsumerState<PaymentRecordScreen> createState() => _PaymentRecordScreenState();
}

class _PaymentRecordScreenState extends ConsumerState<PaymentRecordScreen> {
  late TextEditingController _amountCtrl;
  late Jalali _paidDate;
  late int? _selectedAccountId;
  late TextEditingController _notesCtrl;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(text: widget.installmentAmount.toStringAsFixed(0));
    _paidDate = Jalali.now();
    _selectedAccountId = null;
    _notesCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ثبت پرداخت')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('جزئیات قسط',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('مبلغ قسط:'),
                        Text('${widget.installmentAmount.toStringAsFixed(0)} ریال'),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('تاریخ سررسید:'),
                        Text(widget.dueDate.toString()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Amount input
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'مبلغ پرداخت (ریال)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // Account selection
            accounts.when(
              loading: () => const CircularProgressIndicator(),
              error: (err, stack) => Text('خطا: $err'),
              data: (accountList) {
                return DropdownButtonFormField<int>(
                  value: _selectedAccountId,
                  decoration: InputDecoration(
                    labelText: 'حساب منبع',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: accountList
                      .map((acc) => DropdownMenuItem(
                            value: acc.id,
                            child: Text(acc.displayName),
                          ))
                      .toList(),
                  onChanged: (id) => setState(() => _selectedAccountId = id),
                );
              },
            ),
            const SizedBox(height: 16),

            // Date picker
            ListTile(
              title: const Text('تاریخ پرداخت'),
              subtitle: Text(_paidDate.toString()),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showJalaliDatePicker(
                  context,
                  initialDate: _paidDate,
                  firstDate: Jalali.now().addYears(-1),
                  lastDate: Jalali.now(),
                );
                if (picked != null) {
                  setState(() => _paidDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),

            // Notes
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'یادداشت‌ها',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 32),

            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: const Text('ثبت پرداخت'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (_selectedAccountId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا حساب منبع را انتخاب کنید')),
      );
      return;
    }

    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('مبلغ باید بیشتر از صفر باشد')),
      );
      return;
    }

    ref.read(paymentsNotifierProvider(widget.loanId).notifier).recordPayment(
          installmentId: widget.installmentId,
          accountId: _selectedAccountId!,
          amount: amount,
          paidDate: _paidDate,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
        );

    Navigator.pop(context);
  }
}
