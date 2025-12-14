import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/compute/cash_flow_simulator.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

class CanIAffordThisScreen extends ConsumerStatefulWidget {
  const CanIAffordThisScreen({super.key});

  @override
  ConsumerState<CanIAffordThisScreen> createState() =>
      _CanIAffordThisScreenState();
}

class _CanIAffordThisScreenState extends ConsumerState<CanIAffordThisScreen> {
  late TextEditingController _amountController;
  late TextEditingController _monthlyPaymentController;
  String _frequency = 'monthly'; // 'daily', 'weekly', 'monthly'
  int _durationMonths = 12;

  CashFlowResult? _result;
  bool _isSimulating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _monthlyPaymentController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _monthlyPaymentController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    final amount = int.tryParse(_amountController.text);
    final monthlyPayment = int.tryParse(_monthlyPaymentController.text);

    if (amount == null || amount <= 0) {
      setState(() => _error = 'لطفاً مبلغ قابل قبول وارد کنید');
      return;
    }

    if (monthlyPayment == null || monthlyPayment <= 0) {
      setState(() => _error = 'لطفاً مبلغ ماهانه قابل قبول وارد کنید');
      return;
    }

    setState(() {
      _isSimulating = true;
      _error = null;
      _result = null;
    });

    try {
      final db = DatabaseHelper.instance;

      // Get current balance
      final totalBorrowed = await db.getTotalOutstandingBorrowed();
      final totalLent = await db.getTotalOutstandingLent();
      final currentBalance = totalLent - totalBorrowed;

      // Use default estimates for income/expense
      int avgDailyIncome = 50000; // fallback estimate
      int avgMonthlyExpenses = 800000; // fallback estimate

      // Get existing loans and installments
      final loans = await db.getAllLoans(direction: LoanDirection.borrowed);
      final allInstallments = <Map<String, dynamic>>[];

      for (final loan in loans) {
        if (loan.id == null) continue;
        final insts = await db.getInstallmentsByLoanId(loan.id!);
        for (final inst in insts) {
          allInstallments.add({
            'id': inst.id,
            'loan_id': loan.id,
            'amount': inst.amount,
            'due_date': inst.dueDateJalali,
            'status': inst.status == InstallmentStatus.paid ? 'paid' : 'unpaid',
          });
        }
      }

      // Create simulation input
      final frequency = _frequency;
      final simulationDays = _frequency == 'daily'
          ? _durationMonths * 30
          : _frequency == 'weekly'
          ? _durationMonths * 4
          : _durationMonths * 30;

      final input = CashFlowInput(
        startingBalance: currentBalance,
        loans: loans.map((l) => {'id': l.id, 'title': l.title}).toList(),
        installments: allInstallments,
        budgets: [],
        newRecurringAmount: monthlyPayment,
        newRecurringFrequency: frequency,
        simulationDays: simulationDays,
        avgDailyIncome: avgDailyIncome.abs(),
        avgMonthlyExpenses: avgMonthlyExpenses.abs(),
      );

      // Run simulation
      final snapshots = simulateCashFlow(input);
      final result = analyzeCashFlow(snapshots);

      setState(() {
        _result = result;
        _isSimulating = false;
      });
    } catch (e) {
      setState(() {
        _error = 'خطا در اجرای شبیه‌سازی: $e';
        _isSimulating = false;
      });
    }
  }

  Color _getSafetyColor(String level) {
    return switch (level) {
      'safe' => Colors.green,
      'tight' => Colors.orange,
      'risky' => Colors.deepOrange,
      'critical' => Colors.red,
      _ => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('آیا می‌توانم این خرج را بکنم؟')),
      body: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          Card(
            child: Padding(
              padding: AppDimensions.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'جزئیات تعهد مالی',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'مبلغ کل (تومان)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.money),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  TextField(
                    controller: _monthlyPaymentController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'پرداخت دوره‌ای (تومان)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.calendar_today),
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  DropdownButtonFormField<String>(
                    initialValue: _frequency,
                    decoration: InputDecoration(
                      labelText: 'فرکانس پرداخت',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(value: 'daily', child: Text('روزانه')),
                      DropdownMenuItem(value: 'weekly', child: Text('هفتگی')),
                      DropdownMenuItem(value: 'monthly', child: Text('ماهانه')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _frequency = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  Text(
                    'مدت زمان شبیه‌سازی: $_durationMonths ماه',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Slider(
                    value: _durationMonths.toDouble(),
                    min: 1,
                    max: 24,
                    divisions: 23,
                    label: '$_durationMonths ماه',
                    onChanged: (value) {
                      setState(() => _durationMonths = value.toInt());
                    },
                  ),
                  const SizedBox(height: AppDimensions.spacingM),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red.shade900),
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSimulating ? null : _runSimulation,
                      child: _isSimulating
                          ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('اجرای شبیه‌سازی'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: AppDimensions.spacingM),
            Card(
              child: Padding(
                padding: AppDimensions.cardPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'نتایج شبیه‌سازی',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'سطح ایمنی:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getSafetyColor(_result!.safetyLevel),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            switch (_result!.safetyLevel) {
                              'safe' => 'ایمن',
                              'tight' => 'تنگ',
                              'risky' => 'خطرناک',
                              'critical' => 'بحرانی',
                              _ => _result!.safetyLevel,
                            },
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Text(
                      _result!.recommendation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppDimensions.spacingM),
                    Divider(),
                    const SizedBox(height: AppDimensions.spacingM),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('حداقل موجودی:'),
                        Text(formatCurrency(_result!.minBalance)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('حداکثر موجودی:'),
                        Text(formatCurrency(_result!.maxBalance)),
                      ],
                    ),
                    const SizedBox(height: AppDimensions.spacingS),
                    if (_result!.daysUntilNegative >= 0)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('روزهای تا زیان:'),
                          Text(
                            '${_result!.daysUntilNegative} روز',
                            style: TextStyle(
                              color: _result!.daysUntilNegative < 7
                                  ? Colors.red
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppDimensions.spacingS),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('دارای زیان نقدی:'),
                        Text(
                          _result!.hasNegativeCash ? 'بله' : 'خیر',
                          style: TextStyle(
                            color: _result!.hasNegativeCash
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
