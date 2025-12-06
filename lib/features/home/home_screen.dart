import 'package:flutter/material.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/features/insights/smart_insights_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('خلاصه', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        // Top summary cards
        Row(
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LoansListScreen())),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('موجودی خالص', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text('—', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Assets − Debts', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ReportsScreen())),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('هزینه این ماه', style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Text('—', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 4),
                        Text('Spending vs Budget', style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قبوض پیش رو', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('هیچ قبضی در چند روز آینده وجود ندارد', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SmartInsightsWidget(),
      ],
    );
  }
}
