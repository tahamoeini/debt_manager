import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class CategoryPieChart extends StatelessWidget {
  const CategoryPieChart({super.key, required this.data});

  final Map<String, double> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return Center(child: Text('No data', style: Theme.of(context).textTheme.bodySmall));

    final total = data.values.fold<double>(0, (a, b) => a + b);
    var i = 0;
    final sections = data.entries.map((e) {
      final value = e.value;
      final percent = (value / total) * 100;
      final color = Colors.primaries[i % Colors.primaries.length].withOpacity(0.8);
      i++;
      return PieChartSectionData(
        value: value,
        title: '${percent.toStringAsFixed(0)}%',
        color: color,
        radius: 40,
        titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections, sectionsSpace: 4, centerSpaceRadius: 20));
  }
}
