import 'package:flutter/material.dart';
import '../utils/color_extensions.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

/// A reusable progress bar widget for displaying budget utilization.
/// Changes color based on utilization thresholds (green < 60%, orange < 90%, red >= 90%).
/// 
/// Example usage:
/// ```dart
/// BudgetProgressBar(
///   current: 75000,
///   limit: 100000,
///   label: 'خرید مواد غذایی',
///   showPercentage: true,
/// )
/// ```
class BudgetProgressBar extends StatelessWidget {
  final int current;
  final int limit;
  final String? label;
  final bool showPercentage;
  final bool showAmounts;
  final double height;

  const BudgetProgressBar({
    super.key,
    required this.current,
    required this.limit,
    this.label,
    this.showPercentage = true,
    this.showAmounts = false,
    this.height = AppDimensions.progressBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    final utilization = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
    final percentage = (utilization * 100).toInt();
    final progressColor = colorScheme.budgetStatusColor(utilization);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingS),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: utilization,
            color: progressColor,
            backgroundColor: progressColor.withValues(alpha: 0.2),
            minHeight: height,
          ),
        ),
        const SizedBox(height: AppDimensions.spacingXs),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (showAmounts)
              Text(
                '${_formatAmount(current)} / ${_formatAmount(limit)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            if (showPercentage)
              Text(
                '$percentage%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: progressColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    // Use the existing formatCurrency utility for consistency
    return formatCurrency(amount);
  }
}
