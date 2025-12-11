import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class LoanProgressChart extends StatelessWidget {
  const LoanProgressChart({super.key, required this.paid, required this.remaining});

  final double paid;
  final double remaining;

  @override
  Widget build(BuildContext context) {
    final total = paid + remaining;
    if (total <= 0) return Center(child: Text('No data', style: Theme.of(context).textTheme.bodySmall));

    final paidPct = (paid / total) * 100;
    final remainingPct = (remaining / total) * 100;

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(value: paid, color: Colors.green, title: '${paidPct.toStringAsFixed(0)}%', radius: 40, titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
          PieChartSectionData(value: remaining, color: Colors.redAccent, title: '${remainingPct.toStringAsFixed(0)}%', radius: 40, titleStyle: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white)),
        ],
        centerSpaceRadius: 18,
        sectionsSpace: 4,
      ),
    );
  }
}
