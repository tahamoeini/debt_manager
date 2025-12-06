import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

/// A reusable card widget for dashboard statistics.
/// Displays a title, value, and optional subtitle with consistent Material 3 styling.
/// 
/// Example usage:
/// ```dart
/// DashboardCard(
///   title: 'موجودی کل',
///   value: '۱۲۳٬۴۵۶ ریال',
///   subtitle: 'دارایی‌ها منهای بدهی‌ها',
///   icon: Icons.account_balance_wallet,
///   color: Colors.blue,
/// )
/// ```
class DashboardCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveColor = color ?? colorScheme.primary;

    Widget content = Container(
      padding: AppDimensions.cardPadding,
      decoration: BoxDecoration(
        borderRadius: AppDimensions.cardBorderRadius,
        color: theme.cardColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: AppDimensions.iconSizeSmall,
                  color: effectiveColor,
                ),
                const SizedBox(width: AppDimensions.spacingS),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacingS),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: AppDimensions.spacingXs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Card(
        elevation: 2,
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
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.cardBorderRadius,
      ),
      child: content,
    );
  }
}
