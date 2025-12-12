// Summary UI cards showing total borrowed, lent and net amounts.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/widgets/dashboard_card.dart';
import 'package:debt_manager/components/sensitive_text.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/core/theme/app_colors.dart';

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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DashboardCard(
            title: 'بدهی‌های من',
            value: formatCurrency(borrowed),
            valueWidget: SensitiveText(formatCurrency(borrowed)),
            subtitle: 'مجموع اقساط پرداخت‌نشده‌ای که شما بدهکار هستید',
            icon: Icons.arrow_upward,
            accentColor: colorScheme.expense,
          ),
        ),
        const SizedBox(width: AppConstants.spaceMedium),
        Expanded(
          child: DashboardCard(
            title: 'طلب‌های من',
            value: formatCurrency(lent),
            valueWidget: SensitiveText(formatCurrency(lent)),
            subtitle: 'مجموع اقساط پرداخت‌نشده‌ای که دیگران به شما بدهکارند',
            icon: Icons.arrow_downward,
            accentColor: colorScheme.income,
          ),
        ),
        const SizedBox(width: AppConstants.spaceMedium),
        Expanded(
          child: DashboardCard(
            title: 'وضعیت خالص',
            value: formatCurrency(net),
            valueWidget: SensitiveText(formatCurrency(net)),
            subtitle: 'طلب منفی یعنی بیشتر بدهکار هستید',
            icon: Icons.account_balance_wallet,
            accentColor: net >= 0 ? colorScheme.income : colorScheme.expense,
          ),
        ),
      ],
    );
  }
}
