import 'package:flutter/material.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/components/components.dart';
import 'package:debt_manager/features/insights/smart_insights_widget.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: AppSpacing.pagePadding,
      children: [
        Text('خلاصه', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.md),
        // Top summary cards using DashboardCard
        Row(
          children: [
            Expanded(
              child: DashboardCard(
                title: 'موجودی خالص',
                value: '—',
                subtitle: 'Assets − Debts',
                icon: Icons.account_balance_wallet,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LoansListScreen()),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DashboardCard(
                title: 'هزینه این ماه',
                value: '—',
                subtitle: 'Spending vs Budget',
                icon: Icons.receipt_long,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReportsScreen()),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        DashboardCard(
          title: 'قبوض پیش رو',
          value: 'هیچ قبضی در چند روز آینده وجود ندارد',
          icon: Icons.event_note,
        ),
        const SmartInsightsWidget(),
      ],
    );
  }
}
