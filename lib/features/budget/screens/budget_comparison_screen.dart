// Budget comparison screen: compare budgets vs actual spending
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

class BudgetComparisonScreen extends ConsumerStatefulWidget {
  const BudgetComparisonScreen({super.key});

  @override
  ConsumerState<BudgetComparisonScreen> createState() =>
      _BudgetComparisonScreenState();
}

class _BudgetComparisonScreenState
    extends ConsumerState<BudgetComparisonScreen> {
  late String _selectedPeriod;

  @override
  void initState() {
    super.initState();
    final now = Jalali.now();
    _selectedPeriod = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('مقایسه بودجه و هزینه واقعی'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('انتخاب دوره: '),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _selectedPeriod,
                      items: _generatePeriods(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedPeriod = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Budget>>(
              future: ref
                  .read(budgetsRepositoryProvider)
                  .getBudgetsByPeriod(_selectedPeriod),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final budgets = snap.data ?? [];
                if (budgets.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                          child: Text(
                              'هیچ بودجه‌ای برای این دوره تعریف نشده است')),
                    ),
                  );
                }

                return Column(
                  children: [
                    _buildBudgetChart(budgets),
                    const SizedBox(height: 16),
                    ...budgets.map((budget) => _buildBudgetCard(budget)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _generatePeriods() {
    final now = Jalali.now();
    final periods = <DropdownMenuItem<String>>[];

    for (var i = 0; i < 12; i++) {
      var year = now.year;
      var month = now.month - i;

      while (month <= 0) {
        month += 12;
        year -= 1;
      }

      final period = '$year-${month.toString().padLeft(2, '0')}';
      periods.add(DropdownMenuItem(
        value: period,
        child: Text(period),
      ));
    }

    return periods;
  }

  Widget _buildBudgetChart(List<Budget> budgets) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'مقایسه بودجه و هزینه واقعی',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadBudgetData(budgets),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final data = snap.data ?? [];
                  if (data.isEmpty) {
                    return const Center(
                        child: Text('هیچ داده‌ای برای نمایش وجود ندارد'));
                  }

                  final maxValue = data.fold<int>(0, (max, item) {
                    final budget = item['budget'] as int;
                    final actual = item['actual'] as int;
                    final higher = budget > actual ? budget : actual;
                    return higher > max ? higher : max;
                  });

                  return BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= 0 &&
                                  value.toInt() < data.length) {
                                final item = data[value.toInt()];
                                final category = item['category'] as String;
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    category.length > 8
                                        ? '${category.substring(0, 8)}...'
                                        : category,
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
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                (value / 10000).toStringAsFixed(0),
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: data.asMap().entries.map((e) {
                        final index = e.key;
                        final item = e.value;
                        final budget = (item['budget'] as int).toDouble();
                        final actual = (item['actual'] as int).toDouble();

                        return BarChartGroupData(
                          x: index,
                          barRods: [
                            BarChartRodData(
                              toY: budget,
                              color: Theme.of(context).colorScheme.primary,
                              width: 12,
                            ),
                            BarChartRodData(
                              toY: actual,
                              color: Theme.of(context).colorScheme.secondary,
                              width: 12,
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                    'بودجه', Theme.of(context).colorScheme.primary),
                const SizedBox(width: 16),
                _buildLegendItem(
                    'واقعی', Theme.of(context).colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 8),
            const Text('واحد: هزار تومان', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _loadBudgetData(
      List<Budget> budgets) async {
    final data = <Map<String, dynamic>>[];

    for (final budget in budgets) {
      final actual =
          await ref.read(budgetsRepositoryProvider).computeUtilization(budget);
      data.add({
        'category': budget.category ?? 'عمومی',
        'budget': budget.amount,
        'actual': actual,
      });
    }

    return data;
  }

  Widget _buildBudgetCard(Budget budget) {
    return FutureBuilder<int>(
      future: ref.read(budgetsRepositoryProvider).computeUtilization(budget),
      builder: (context, snap) {
        final actual = snap.data ?? 0;
        final percentage = budget.amount > 0
            ? (actual / budget.amount * 100).clamp(0, 100).toInt()
            : 0;
        final remaining = budget.amount - actual;

        final cs = Theme.of(context).colorScheme;
        Color progressColor;
        if (percentage >= 100) {
          progressColor = cs.error;
        } else if (percentage >= 80) {
          progressColor = Colors.orange;
        } else {
          progressColor = cs.primary;
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  budget.category ?? 'بودجه عمومی',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: percentage / 100,
                  minHeight: 8,
                  color: progressColor,
                  backgroundColor: cs.surfaceContainerHighest,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('بودجه', style: TextStyle(fontSize: 12)),
                        Text(
                          formatCurrency(budget.amount),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('هزینه واقعی',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          formatCurrency(actual),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: progressColor,
                                  ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('باقی‌مانده',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          formatCurrency(remaining),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage% استفاده شده',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: progressColor,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
