/// Budget Progress Bar Widget
/// 
/// A reusable widget for displaying budget utilization with a progress bar.
/// Colors change based on utilization thresholds.

import 'package:flutter/material.dart';
import 'design_system.dart';

/// A widget that displays budget progress with color-coded thresholds
class BudgetBar extends StatelessWidget {
  /// Current amount spent
  final int current;

  /// Budget limit/maximum
  final int limit;

  /// Optional custom height (default: 8)
  final double? height;

  /// Whether to show the percentage label
  final bool showPercentage;

  /// Whether to show the amount label
  final bool showAmount;

  /// Custom low threshold (default: 0.6)
  final double lowThreshold;

  /// Custom medium threshold (default: 0.9)
  final double mediumThreshold;

  const BudgetBar({
    super.key,
    required this.current,
    required this.limit,
    this.height,
    this.showPercentage = true,
    this.showAmount = false,
    this.lowThreshold = 0.6,
    this.mediumThreshold = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Calculate percentage
    final percentage = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;

    // Determine color based on threshold
    Color barColor;
    if (percentage < lowThreshold) {
      barColor = colorScheme.success;
    } else if (percentage < mediumThreshold) {
      barColor = colorScheme.warning;
    } else {
      barColor = colorScheme.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height ?? 8),
          child: SizedBox(
            height: height ?? 8,
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: barColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ),
        if (showPercentage || showAmount) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAmount) ...[
                Text(
                  '$current / $limit',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                if (showPercentage) const SizedBox(width: AppSpacing.sm),
              ],
              if (showPercentage)
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A widget that displays budget progress with detailed labels
class BudgetProgressCard extends StatelessWidget {
  /// Category name
  final String category;

  /// Current amount spent
  final int current;

  /// Budget limit/maximum
  final int limit;

  /// Optional icon
  final IconData? icon;

  /// Optional tap handler
  final VoidCallback? onTap;

  const BudgetProgressCard({
    super.key,
    required this.category,
    required this.current,
    required this.limit,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final percentage = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;
    
    Color statusColor;
    if (percentage < 0.6) {
      statusColor = colorScheme.success;
    } else if (percentage < 0.9) {
      statusColor = colorScheme.warning;
    } else {
      statusColor = colorScheme.danger;
    }

    final content = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppIconSize.md, color: statusColor),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    category,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            BudgetBar(
              current: current,
              limit: limit,
              showPercentage: false,
              showAmount: true,
            ),
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: content,
      );
    }

    return content;
  }
}
