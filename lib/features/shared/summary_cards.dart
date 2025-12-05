/// Summary UI cards showing total borrowed, lent and net amounts.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

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
    final textTheme = Theme.of(context).textTheme;

    Widget buildCard(String title, int value, String subtitle) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(formatCurrency(value), style: textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(subtitle, style: textTheme.bodySmall),
            ],
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: buildCard(
            'بدهی‌های من',
            borrowed,
            'مجموع اقساط پرداخت‌نشده‌ای که شما بدهکار هستید',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildCard(
            'طلب‌های من',
            lent,
            'مجموع اقساط پرداخت‌نشده‌ای که دیگران به شما بدهکارند',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: buildCard(
            'وضعیت خالص',
            net,
            'طلب منفی یعنی بیشتر بدهکار هستید',
          ),
        ),
      ],
    );
  }
}
