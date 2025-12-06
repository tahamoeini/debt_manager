// Debt payoff projection screen: visualize debt payoff timeline
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debt_manager/features/reports/reports_repository.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

class DebtPayoffProjectionScreen extends StatefulWidget {
  const DebtPayoffProjectionScreen({super.key});

  @override
  State<DebtPayoffProjectionScreen> createState() => _DebtPayoffProjectionScreenState();
}

class _DebtPayoffProjectionScreenState extends State<DebtPayoffProjectionScreen> {
  final _repo = ReportsRepository();
  final _db = DatabaseHelper.instance;
  
  Loan? _selectedLoan;
  List<Loan> _borrowedLoans = [];
  int _extraPayment = 0;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    final loans = await _db.getAllLoans(direction: LoanDirection.borrowed);
    setState(() {
      _borrowedLoans = loans;
      if (loans.isNotEmpty) {
        _selectedLoan = loans.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('پیش‌بینی بازپرداخت بدهی'),
      ),
      body: _borrowedLoans.isEmpty
          ? const Center(
              child: Text('هیچ بدهی‌ای برای نمایش وجود ندارد'),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('انتخاب وام:'),
                        const SizedBox(height: 8),
                        DropdownButton<int>(
                          value: _selectedLoan?.id,
                          isExpanded: true,
                          items: _borrowedLoans.map((loan) {
                            return DropdownMenuItem(
                              value: loan.id,
                              child: Text(loan.title.isNotEmpty ? loan.title : 'بدون عنوان'),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _selectedLoan = _borrowedLoans.firstWhere((l) => l.id == v);
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('پرداخت اضافی ماهانه (تومان):'),
                        const SizedBox(height: 8),
                        TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            setState(() {
                              _extraPayment = int.tryParse(v) ?? 0;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedLoan != null && _selectedLoan!.id != null)
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _repo.projectDebtPayoff(
                      _selectedLoan!.id!,
                      extraPayment: _extraPayment > 0 ? _extraPayment : null,
                    ),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final projections = snap.data ?? [];
                      if (projections.isEmpty) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: Text('این وام بازپرداخت شده است')),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          _buildProjectionChart(projections),
                          const SizedBox(height: 16),
                          _buildProjectionSummary(projections),
                        ],
                      );
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildProjectionChart(List<Map<String, dynamic>> projections) {
    final maxBalance = projections.fold<int>(0, (max, item) {
      final balance = item['balance'] as int;
      return balance > max ? balance : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'نمودار بازپرداخت',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  lineTouchData: const LineTouchData(enabled: true),
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < projections.length) {
                            final item = projections[value.toInt()];
                            final month = item['month'] as int;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                month.toString().padLeft(2, '0'),
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            (value / 1000000).toStringAsFixed(1),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  minY: 0,
                  maxY: maxBalance > 0 ? maxBalance * 1.1 : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: projections.asMap().entries.map((e) {
                        final index = e.key;
                        final item = e.value;
                        final balance = (item['balance'] as int).toDouble();
                        return FlSpot(index.toDouble(), balance);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.error,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('واحد: میلیون تومان', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectionSummary(List<Map<String, dynamic>> projections) {
    final monthsToPayoff = projections.length;
    final firstBalance = projections.first['balance'] as int;
    final totalPayments = projections.fold<int>(0, (sum, item) {
      return sum + (item['payment'] as int) + (item['extraPayment'] as int);
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'خلاصه بازپرداخت',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow('مانده فعلی', formatCurrency(firstBalance)),
            const SizedBox(height: 8),
            _buildSummaryRow('تعداد اقساط باقی‌مانده', '$monthsToPayoff قسط'),
            const SizedBox(height: 8),
            _buildSummaryRow('مجموع پرداخت‌ها', formatCurrency(totalPayments)),
            if (_extraPayment > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('پرداخت اضافی ماهانه', formatCurrency(_extraPayment)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'با پرداخت اضافی ماهانه، بدهی شما در $monthsToPayoff ماه بازپرداخت خواهد شد.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ],
    );
  }
}
