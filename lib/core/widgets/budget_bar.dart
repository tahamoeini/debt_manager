// Reusable budget progress bar widget.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/core/theme/app_theme_extensions.dart';

/// A reusable widget for displaying budget progress with color-coded thresholds.
///
/// The widget displays:
/// - A linear progress bar with rounded ends
/// - Color changes based on budget utilization (green < 60%, orange < 90%, red >= 90%)
/// - Current amount and limit values
/// - Percentage display
///
/// Example usage:
/// ```dart
/// BudgetBar(
///   current: 450000,
///   limit: 500000,
///   label: 'Food Budget',
/// )
/// ```
class BudgetBar extends StatelessWidget {
  /// Current amount spent/used
  final int current;

  /// Budget limit
  final int limit;

  /// Optional label for the budget
  final String? label;

  /// Show percentage text
  final bool showPercentage;

  /// Show amount text
  final bool showAmount;

  /// Height of the progress bar
  final double? height;

  /// Width of the progress bar
  final double? width;

  const BudgetBar({
    super.key,
    required this.current,
    required this.limit,
    this.label,
    this.showPercentage = true,
    this.showAmount = false,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Calculate percentage (handle division by zero)
    final percentage = limit > 0 ? (current / limit).clamp(0.0, 1.0) : 0.0;

    // Determine color based on thresholds
    final Color barColor;
    if (percentage < AppConstants.budgetWarningThreshold) {
      barColor = colorScheme.success;
    } else if (percentage < AppConstants.budgetDangerThreshold) {
      barColor = colorScheme.warning;
    } else {
      barColor = colorScheme.danger;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label if provided
        if (label != null) ...[
          Text(
            label!,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppConstants.spaceSmall),
        ],
        // Progress bar
        Row(
          children: [
            Expanded(
              child: SizedBox(
                width: width,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    (height ?? AppConstants.progressBarHeight) / 2,
                  ),
                  child: LinearProgressIndicator(
                    value: percentage,
                    minHeight: height ?? AppConstants.progressBarHeight,
                    backgroundColor: barColor.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ),
            ),
            // Percentage text
            if (showPercentage) ...[
              const SizedBox(width: AppConstants.spaceSmall),
              SizedBox(
                width: 45,
                child: Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: barColor,
                  ),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ],
        ),
        // Amount text if requested
        if (showAmount) ...[
          const SizedBox(height: AppConstants.spaceXSmall),
          Text(
            '$current / $limit',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ],
    );
  }
}
