import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/accounts/models/account.dart';
import 'package:debt_manager/features/accounts/providers/accounts_provider.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/core/utils/jalali_date_picker.dart';
import 'package:debt_manager/core/utils/jalali_date_provider.dart';

class LoanWizardScreen extends ConsumerStatefulWidget {
  final Loan? existingLoan;

  const LoanWizardScreen({this.existingLoan, super.key});

  @override
  ConsumerState<LoanWizardScreen> createState() => _LoanWizardScreenState();
}

class _LoanWizardScreenState extends ConsumerState<LoanWizardScreen> {
  late int _currentStep;
  late String _setupMode; // 'installment-first' or 'total-first'
  
  // Step 1: Basic info
  late Counterparty? _selectedCounterparty;
  late LoanDirection _direction;
  late TextEditingController _titleCtrl;
  
  // Step 2: Mode selection & amounts
  late double _principalAmount;
  late double _totalAmount;
  late int _installmentCount;
  late double _installmentAmount;
  late TextEditingController _principalCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _installmentCountCtrl;
  
  // Step 3: Dates & interest
  late Jalali _startDate;
  late TextEditingController _interestCtrl;
  
  // Step 4: Disbursement account
  late Account? _disbursementAccount;
  
  // Step 5: Review & save
  late TextEditingController _notesCtrl;
  
  late List<Counterparty> _counterparties;

  @override
  void initState() {
    super.initState();
    _currentStep = 0;
    _setupMode = 'installment-first';
    _selectedCounterparty = null;
    _direction = LoanDirection.borrowed;
    _titleCtrl = TextEditingController(text: widget.existingLoan?.title ?? '');
    _principalAmount = (widget.existingLoan?.principalAmount ?? 0).toDouble();
    _totalAmount = (widget.existingLoan?.installmentAmount ?? 0).toDouble() * (widget.existingLoan?.installmentCount ?? 1);
    _installmentCount = widget.existingLoan?.installmentCount ?? 12;
    _installmentAmount = (widget.existingLoan?.installmentAmount ?? 0).toDouble();
    _installmentCtrl = TextEditingController(text: _installmentAmount.toStringAsFixed(0));
    _principalCtrl = TextEditingController(text: _principalAmount.toStringAsFixed(0));
    _totalCtrl = TextEditingController(text: _totalAmount.toStringAsFixed(0));
    _installmentCountCtrl = TextEditingController(text: _installmentCount.toString());
    _startDate = widget.existingLoan?.startDateJalali != null
        ? JalaliDateProvider.parseJalali(widget.existingLoan!.startDateJalali)
        : Jalali.now();
    _interestCtrl = TextEditingController(text: widget.existingLoan?.interestRate?.toString() ?? '');
    _disbursementAccount = null;
    _notesCtrl = TextEditingController(text: widget.existingLoan?.notes ?? '');
    _counterparties = [];
    
    _loadCounterparties();
  }

  void _loadCounterparties() async {
    final db = ref.read(databaseHelperProvider);
    final cps = await db.getAllCounterparties();
    setState(() {
      _counterparties = cps;
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _principalCtrl.dispose();
    _totalCtrl.dispose();
    _installmentCountCtrl.dispose();
    _interestCtrl.dispose();
    _notesCtrl.dispose();
    _installmentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جادوی افزودن وام'),
        elevation: 0,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepTapped: (step) => setState(() => _currentStep = step),
        onStepContinue: _currentStep < 4 ? () => setState(() => _currentStep++) : null,
        onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        steps: [
          // Step 1: Basic Info
          Step(
            title: const Text('اطلاعات پایه'),
            isActive: _currentStep >= 0,
            content: _buildStep1(),
          ),
          // Step 2: Amount Entry
          Step(
            title: const Text('نوع و میزان'),
            isActive: _currentStep >= 1,
            content: _buildStep2(),
          ),
          // Step 3: Dates & Interest
          Step(
            title: const Text('تاریخ و بهره'),
            isActive: _currentStep >= 2,
            content: _buildStep3(),
          ),
          // Step 4: Disbursement
          Step(
            title: const Text('منبع تخصیص'),
            isActive: _currentStep >= 3,
            content: _buildStep4(),
          ),
          // Step 5: Review
          Step(
            title: const Text('بررسی و ذخیره'),
            isActive: _currentStep >= 4,
            content: _buildStep5(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Direction
        SegmentedButton<LoanDirection>(
          segments: const [
            ButtonSegment(label: Text('قرض گرفتن'), value: LoanDirection.borrowed),
            ButtonSegment(label: Text('قرض دادن'), value: LoanDirection.lent),
          ],
          selected: {_direction},
          onSelectionChanged: (set) {
            setState(() => _direction = set.first);
          },
        ),
        const SizedBox(height: 20),

        // Counterparty
        DropdownButtonFormField<Counterparty>(
          initialValue: _selectedCounterparty,
          decoration: InputDecoration(
            labelText: 'طرف معامله',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: _counterparties
              .map((cp) => DropdownMenuItem(value: cp, child: Text(cp.name)))
              .toList(),
          onChanged: (cp) => setState(() => _selectedCounterparty = cp),
        ),
        const SizedBox(height: 16),

        // New Counterparty Button
        TextButton.icon(
          onPressed: () {
            // Navigate to create new counterparty (simplified)
          },
          icon: const Icon(Icons.add),
          label: const Text('+ اضافه کردن طرف جدید'),
        ),
        const SizedBox(height: 16),

        // Title
        TextField(
          controller: _titleCtrl,
          decoration: InputDecoration(
            labelText: 'عنوان وام',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode Selection
        Text('نحوه ورود اطلاعات:', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(label: Text('قسط اول'), value: 'installment-first'),
            ButtonSegment(label: Text('کل اول'), value: 'total-first'),
          ],
          selected: {_setupMode},
          onSelectionChanged: (set) {
            setState(() => _setupMode = set.first);
          },
        ),
        const SizedBox(height: 24),

        if (_setupMode == 'installment-first') ...[
          // Installment-first mode: Enter principal, count, installment amount
          TextField(
            controller: _principalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'مبلغ اصلی (ریال)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _installmentCountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'تعداد اقساط',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _installmentCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'مبلغ هر قسط (ریال)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
        ] else ...[
          // Total-first mode: Enter principal and total amount
          TextField(
            controller: _principalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'مبلغ اصلی (ریال)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'کل مبلغ بازپرداخت (ریال)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _installmentCountCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'تعداد اقساط',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (_) => _recalculateAmounts(),
          ),
        ],

        const SizedBox(height: 24),
        // Summary
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('خلاصه:',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('مبلغ اصلی:'),
                    Text('${_principalAmount.toStringAsFixed(0)} ریال'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('کل بازپرداخت:'),
                    Text('${_totalAmount.toStringAsFixed(0)} ریال'),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('هر قسط:'),
                    Text('${_installmentAmount.toStringAsFixed(0)} ریال'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        // Start date
        ListTile(
          title: const Text('تاریخ شروع'),
          subtitle: Text(_startDate.toString()),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showJalaliDatePicker(
              context,
              initialDate: _startDate,
              firstDate: Jalali.now().addYears(-5),
              lastDate: Jalali.now(),
            );
            if (picked != null) {
              setState(() => _startDate = picked);
            }
          },
        ),
        const SizedBox(height: 20),

        // Interest rate
        TextField(
          controller: _interestCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'نرخ بهره سالانه (%)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    final accounts = ref.watch(accountsNotifierProvider);
    
    return accounts.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('خطا: $err')),
      data: (accountList) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'حساب تخصیص وام:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<Account>(
              initialValue: _disbursementAccount,
              decoration: InputDecoration(
                labelText: 'انتخاب حساب',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: accountList
                  .map((acc) => DropdownMenuItem(
                        value: acc,
                        child: Text('${acc.displayName} (${acc.balance.toStringAsFixed(0)})'),
                      ))
                  .toList(),
              onChanged: (acc) => setState(() => _disbursementAccount = acc),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStep5() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Review
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('بررسی جزئیات',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  _reviewField('عنوان:', _titleCtrl.text),
                  _reviewField(
                    'طرف معامله:',
                    _selectedCounterparty?.name ?? 'نامشخص',
                  ),
                  _reviewField('جهت:', _direction.name),
                  _reviewField(
                    'مبلغ اصلی:',
                    '${_principalAmount.toStringAsFixed(0)} ریال',
                  ),
                  _reviewField(
                    'کل مبلغ:',
                    '${_totalAmount.toStringAsFixed(0)} ریال',
                  ),
                  _reviewField(
                    'هر قسط:',
                    '${_installmentAmount.toStringAsFixed(0)} ریال',
                  ),
                  _reviewField('تعداد اقساط:', _installmentCount.toString()),
                  _reviewField('تاریخ شروع:', _startDate.toString()),
                  if (_interestCtrl.text.isNotEmpty)
                    _reviewField('نرخ بهره:', '${_interestCtrl.text}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Notes
          TextField(
            controller: _notesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'یادداشت‌ها',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              child: const Text('ذخیره وام'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _reviewField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _recalculateAmounts() {
    _principalAmount = double.tryParse(_principalCtrl.text) ?? 0;
    _installmentCount = int.tryParse(_installmentCountCtrl.text) ?? 1;

    if (_setupMode == 'installment-first') {
      _installmentAmount = double.tryParse(_installmentCtrl.text) ?? 0;
      _totalAmount = _installmentAmount * _installmentCount;
    } else {
      _totalAmount = double.tryParse(_totalCtrl.text) ?? 0;
      _installmentAmount =
          _installmentCount > 0 ? _totalAmount / _installmentCount : 0;
    }

    setState(() {});
  }

  void _save() {
    if (_selectedCounterparty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفا طرف معامله را انتخاب کنید')),
      );
      return;
    }

    // Create loan and save via notifier
    // This is simplified; actual implementation would use riverpod
    Navigator.pop(context);
  }

    late final TextEditingController _installmentCtrl;
}
