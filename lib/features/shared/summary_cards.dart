// Summary UI cards showing total borrowed, lent and net amounts.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/widgets/dashboard_card.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
import 'package:debt_manager/components/components.dart';

class SummaryCards extends StatelessWidget {
  final int borrowed;
  final int lent;
  final int net;

  const SummaryCards({
    super.key,
    required this.borrowed,
    required this.lent,
    required this.net,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DashboardCard(
            title: 'بدهی‌های من',
            value: formatCurrency(borrowed),
            subtitle: 'مجموع اقساط پرداخت‌نشده‌ای که شما بدهکار هستید',
            icon: Icons.trending_down,
            color: colorScheme.danger,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
            icon: Icons.arrow_upward,
            accentColor: theme.expenseColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DashboardCard(
            title: 'طلب‌های من',
            value: formatCurrency(lent),
            subtitle: 'مجموع اقساط پرداخت‌نشده‌ای که دیگران به شما بدهکارند',
            icon: Icons.trending_up,
            color: colorScheme.success,
          ),
        ),
        const SizedBox(width: AppDimensions.spacingM),
            icon: Icons.arrow_downward,
            accentColor: theme.incomeColor,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: DashboardCard(
            title: 'وضعیت خالص',
            value: formatCurrency(net),
            subtitle: 'طلب منفی یعنی بیشتر بدهکار هستید',
            icon: Icons.account_balance,
            color: net >= 0 ? colorScheme.success : colorScheme.danger,
            icon: Icons.account_balance_wallet,
            accentColor: net >= 0 ? theme.successColor : theme.dangerColor,
          ),
        ),
      ],
    );
  }
}
