import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

class PayoffSimulatorScreen extends ConsumerStatefulWidget {
  const PayoffSimulatorScreen({super.key});

  @override
  ConsumerState<PayoffSimulatorScreen> createState() =>
      _PayoffSimulatorScreenState();
}

class _PayoffSimulatorScreenState extends ConsumerState<PayoffSimulatorScreen> {
  bool _loading = true;
  List<_DebtItem> _debts = [];
  int _extraPerMonth = 500000; // default slider value

  List<FlSpot> _standardSpots = [];
  List<FlSpot> _acceleratedSpots = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final repo = ref.read(loanRepositoryProvider);
    final loans = await repo.getAllLoans(direction: LoanDirection.borrowed);
    final debts = <_DebtItem>[];
    final ids = loans.map((l) => l.id).whereType<int>().toList();
    final grouped = ids.isNotEmpty
        ? await repo.getInstallmentsGroupedByLoanId(ids)
        : <int, List<Installment>>{};
    for (final loan in loans) {
      final lid = loan.id;
      if (lid == null) continue;
      final insts = grouped[lid] ?? const <Installment>[];
      final unpaid = insts.where((i) => i.status != InstallmentStatus.paid);
      final balance = unpaid.fold<int>(0, (s, i) => s + i.amount);
      if (balance > 0) {
        debts.add(_DebtItem(
          id: lid,
          title: loan.title.isNotEmpty ? loan.title : 'بدون عنوان',
          balance: balance.toDouble(),
          monthlyPayment: loan.installmentAmount,
        ));
      }
    }

    setState(() {
      _debts = debts;
      _loading = false;
    });

    _recomputeSeries();
  }

  void _recomputeSeries() {
    final standard = _simulate(extra: 0, snowball: false);
    final accelerated = _simulate(extra: _extraPerMonth, snowball: true);

    setState(() {
      _standardSpots = standard
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
          .toList();
      _acceleratedSpots = accelerated
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
          .toList();
    });
  }

  List<int> _simulate({required int extra, required bool snowball}) {
    // Copy balances and payments
    final balances = _debts.map((d) => d.balance.toDouble()).toList();
    final payments = _debts.map((d) => d.monthlyPayment.toDouble()).toList();

    final months = <int>[];
    int month = 0;
    const maxMonths = 600; // safety cap

    double totalOutstanding() => balances.fold(0.0, (s, b) => s + b);

    while (totalOutstanding() > 0.5 && month < maxMonths) {
      month++;

      // Apply regular payments
      for (var i = 0; i < balances.length; i++) {
        if (balances[i] <= 0) continue;
        final pay = payments[i].clamp(0.0, balances[i]);
        balances[i] = (balances[i] - pay).clamp(0.0, double.infinity);
      }

      // Apply extra using debt snowball (smallest balance first) or proportional
      var remainingExtra = extra.toDouble();
      if (remainingExtra > 0) {
        if (snowball) {
          // sort indices by current balance ascending
          while (remainingExtra > 0) {
            final positiveIndices = List<int>.generate(
              balances.length,
              (i) => i,
            ).where((i) => balances[i] > 0).toList();
            if (positiveIndices.isEmpty) break;
            positiveIndices.sort((a, b) => balances[a].compareTo(balances[b]));
            final idx = positiveIndices.first;
            final apply = remainingExtra.clamp(0.0, balances[idx]);
            balances[idx] = (balances[idx] - apply).clamp(0.0, double.infinity);
            remainingExtra -= apply;
            if (apply == 0) break;
          }
        } else {
          // distribute extra proportionally to outstanding balances
          final total = totalOutstanding();
          if (total > 0) {
            for (var i = 0; i < balances.length; i++) {
              if (balances[i] <= 0) continue;
              final share = (balances[i] / total) * extra;
              final apply = share.clamp(0.0, balances[i]);
              balances[i] = (balances[i] - apply).clamp(0.0, double.infinity);
            }
          }
        }
      }

      months.add(totalOutstanding().round());
    }

    // include starting point at month 0 (initial total)
    final initial = _debts.fold<int>(0, (s, d) => s + d.balance.round());
    return [initial, ...months];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('شبیه‌ساز پرداخت بدهی (Debt Snowball)')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'مقایسه دوره تسویه',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: LineChart(
                                  LineChartData(
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: _standardSpots,
                                        isCurved: true,
                                        color: Colors.blue,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                      ),
                                      LineChartBarData(
                                        spots: _acceleratedSpots,
                                        isCurved: true,
                                        color: Colors.green,
                                        barWidth: 3,
                                        dotData: const FlDotData(show: false),
                                      ),
                                    ],
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 64,
                                          getTitlesWidget: (v, meta) =>
                                              Text(formatCurrency(v.toInt())),
                                        ),
                                      ),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          interval: 12,
                                          getTitlesWidget: (v, meta) =>
                                              Text(v.toInt().toString()),
                                        ),
                                      ),
                                    ),
                                    gridData: const FlGridData(show: true),
                                    borderData: FlBorderData(show: true),
                                  ),
                                  key: ValueKey<int>(_extraPerMonth),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 8,
                                      color: Colors.blue,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Standard'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 14,
                                      height: 8,
                                      color: Colors.green,
                                    ),
                                    const SizedBox(width: 6),
                                    const Text('Accelerated'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'مبلغ اضافه در هر ماه: ${formatCurrency(_extraPerMonth)}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Slider(
                            value: _extraPerMonth.toDouble(),
                            min: 500000,
                            max: 5000000,
                            divisions: ((5000000 - 500000) ~/ 500000),
                            label: formatCurrency(_extraPerMonth),
                            onChanged: (v) {
                              setState(() {
                                _extraPerMonth = v.round();
                              });
                              _recomputeSeries();
                            },
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'لیست بدهی‌ها: ${_debts.length} مورد',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _DebtItem {
  final int id;
  final String title;
  double balance;
  final int monthlyPayment;

  _DebtItem({
    required this.id,
    required this.title,
    required this.balance,
    required this.monthlyPayment,
  });
}
