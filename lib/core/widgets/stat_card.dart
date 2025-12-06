import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

/// A compact card widget for displaying a statistic with title and value.
/// Useful for overview sections and summary displays.
/// 
/// Example usage:
/// ```dart
/// StatCard(
///   title: 'بودجه باقی‌مانده',
///   value: '۵۰٬۰۰۰ ریال',
///   color: Colors.green,
///   icon: Icons.trending_up,
/// )
/// ```
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData? icon;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    Widget content = Container(
      padding: AppDimensions.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: AppDimensions.iconSizeMedium,
              color: effectiveColor,
            ),
          if (icon != null) const SizedBox(height: AppDimensions.spacingS),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimensions.cardBorderRadius,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppDimensions.cardBorderRadius,
          child: content,
        ),
      );
    }

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.cardBorderRadius,
      ),
      child: content,
    );
  }
}
