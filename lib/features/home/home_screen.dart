import 'package:flutter/material.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/core/widgets/stat_card.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppDimensions.pagePadding,
      children: [
        Text('خلاصه', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppDimensions.spacingM),
        // Top summary cards
        Row(
          children: [
            Expanded(
              child: StatCard(
                title: 'موجودی خالص',
                value: '—',
                icon: Icons.account_balance_wallet,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoansListScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppDimensions.spacingM),
            Expanded(
              child: StatCard(
                title: 'هزینه این ماه',
                value: '—',
                icon: Icons.trending_down,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacingM),
        Card(
          child: Padding(
            padding: AppDimensions.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('قبوض پیش رو', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppDimensions.spacingS),
                Text('هیچ قبضی در چند روز آینده وجود ندارد', style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
