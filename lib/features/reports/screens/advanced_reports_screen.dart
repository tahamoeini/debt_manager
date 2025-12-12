// Advanced reports screen with charts and insights
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:debt_manager/features/reports/reports_repository.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/core/export/export_service.dart';
import 'package:debt_manager/features/budget/screens/budget_comparison_screen.dart';
import 'package:debt_manager/features/reports/screens/debt_payoff_projection_screen.dart';
import 'package:share_plus/share_plus.dart';

class AdvancedReportsScreen extends ConsumerStatefulWidget {
  const AdvancedReportsScreen({super.key});

  @override
  ConsumerState<AdvancedReportsScreen> createState() => _AdvancedReportsScreenState();
}

class _AdvancedReportsScreenState extends ConsumerState<AdvancedReportsScreen> {
  late ReportsRepository _repo;
  final _exportService = ExportService.instance;

  late int _selectedYear;
  late int _selectedMonth;
  int _timeRange = 6; // months back

  @override
  void initState() {
    super.initState();
    final now = dateTimeToJalali(DateTime.now());
    _selectedYear = now.year;
    _selectedMonth = now.month;
    _repo = ReportsRepository(ref);
  }

  Future<void> _exportCSV() async {
    try {
      final filePath = await _exportService.exportInstallmentsCSV();

      if (!mounted) return;

      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'خروجی اقساط',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فایل CSV با موفقیت ایجاد شد')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ایجاد فایل: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('گزارش‌های پیشرفته'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportCSV,
            tooltip: 'خروجی CSV',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Quick action buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const BudgetComparisonScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.pie_chart_outline),
                    label: const Text('مقایسه بودجه'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const DebtPayoffProjectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline),
                    label: const Text('پیش‌بینی بدهی'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Month selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    const Text('انتخاب ماه: '),
                    const SizedBox(width: 8),
                    DropdownButton<int>(
                      value: _selectedMonth,
                      items: List.generate(12, (i) {
                        final month = i + 1;
                        return DropdownMenuItem(
                          value: month,
                          child: Text(month.toString().padLeft(2, '0')),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedMonth = v);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<int>(
                      value: _selectedYear,
                      items: List.generate(5, (i) {
                        final year = dateTimeToJalali(DateTime.now()).year - i;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedYear = v);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Insights section
            FutureBuilder<List<String>>(
              future: _repo.generateMonthlyInsights(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final insights = snap.data ?? [];
                if (insights.isEmpty) return const SizedBox.shrink();

                return Card(
                  color: cs.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lightbulb_outline,
                                color: cs.onPrimaryContainer),
                            const SizedBox(width: 8),
                            Text(
                              'تحلیل‌ها',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: cs.onPrimaryContainer,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...insights.map((insight) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ',
                                      style: TextStyle(
                                          color: cs.onPrimaryContainer)),
                                  Expanded(
                                    child: Text(
                                      insight,
                                      style: TextStyle(
                                          color: cs.onPrimaryContainer),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // Spending by category pie chart
            Text(
              'هزینه‌ها بر اساس دسته‌بندی',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            FutureBuilder<Map<String, int>>(
              future:
                  _repo.getSpendingByCategory(_selectedYear, _selectedMonth),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snap.data ?? {};
                if (data.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                          child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
                    ),
                  );
                }

                return _buildPieChart(data);
              },
            ),

            const SizedBox(height: 24),

            // Time range selector
            Row(
              children: [
                Text(
                  'روند زمانی',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 6, label: Text('6 ماه')),
                    ButtonSegment(value: 12, label: Text('12 ماه')),
                  ],
                  selected: {_timeRange},
                  onSelectionChanged: (Set<int> selection) {
                    setState(() => _timeRange = selection.first);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Spending over time bar chart
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _repo.getSpendingOverTime(_timeRange),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                          child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
                    ),
                  );
                }

                return _buildBarChart(data);
              },
            ),

            const SizedBox(height: 24),

            // Net worth over time line chart
            Text(
              'ارزش خالص در طول زمان',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _repo.getNetWorthOverTime(_timeRange),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snap.data ?? [];
                if (data.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                          child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
                    ),
                  );
                }

                return _buildLineChart(data);
              },
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(Map<String, int> data) {
    final entries = data.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + e.value);

    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((e) {
                    final entry = e.value;
                    final percentage = ((entry.value / total) * 100);
                    final color = colorForCategory(
                      entry.key,
                      brightness: Theme.of(context).brightness,
                    );

                    return PieChartSectionData(
                      value: entry.value.toDouble(),
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: color,
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: entries.map((e) {
                final color = colorForCategory(
                  e.key,
                  brightness: Theme.of(context).brightness,
                );
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text('${e.key}: ${formatCurrency(e.value)}'),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
        ),
      );
    }

    final maxValue = data.fold<int>(0, (max, item) {
      final spending = item['spending'] as int? ?? 0;
      return spending > max ? spending : max;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: BarChart(
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
                    final spending = (item['spending'] as int? ?? 0).toDouble();

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: spending,
                          color: Theme.of(context).colorScheme.primary,
                          width: 16,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('واحد: هزار تومان', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('هیچ داده‌ای برای نمایش وجود ندارد')),
        ),
      );
    }

    final maxValue = data.fold<int>(0, (max, item) {
      final netWorth = (item['netWorth'] as int? ?? 0).abs();
      return netWorth > max ? netWorth : max;
    });

    final minValue = data.fold<int>(0, (min, item) {
      final netWorth = item['netWorth'] as int? ?? 0;
      return netWorth < min ? netWorth : min;
    });

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            final item = data[value.toInt()];
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
                  borderData: FlBorderData(show: true),
                  minY: minValue < 0 ? minValue * 1.2 : 0,
                  maxY: maxValue > 0 ? maxValue * 1.2 : 100,
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        final index = e.key;
                        final item = e.value;
                        final netWorth =
                            (item['netWorth'] as int? ?? 0).toDouble();
                        return FlSpot(index.toDouble(), netWorth);
                      }).toList(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text('واحد: هزار تومان', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
