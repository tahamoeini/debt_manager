// Reusable dashboard card widget for displaying statistics and metrics.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

/// A reusable card widget for displaying dashboard statistics.
///
/// This widget provides a consistent style for all dashboard cards with:
/// - Material 3 elevated container
/// - Rounded corners
/// - Optional icon
/// - Title, value, and optional subtitle
///
/// Example usage:
/// ```dart
/// DashboardCard(
///   title: 'Total Balance',
///   value: '۱٬۲۳۴٬۵۶۷ ریال',
///   subtitle: 'As of today',
///   icon: Icons.account_balance_wallet,
///   color: Theme.of(context).colorScheme.primary,
/// )
/// ```
class DashboardCard extends StatelessWidget {
  /// The title text displayed at the top of the card
  final String title;

  /// The main value/metric displayed prominently
  final String value;

  /// Optional subtitle or description text
  final String? subtitle;

  /// Optional icon displayed at the top
  final IconData? icon;

  /// Optional color for the icon and accent
  final Color? color;

  /// Custom action widget (e.g., a button)
  final Widget? action;
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
    this.action,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final accentColor = color ?? colorScheme.primary;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusMedium,
      ),
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon and title row
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppConstants.iconSizeSmall,
                    color: accentColor,
                  ),
                  const SizedBox(width: AppConstants.spaceSmall),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppConstants.spaceSmall),
            // Value
            Text(
              value,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
            // Subtitle
            if (subtitle != null) ...[
              const SizedBox(height: AppConstants.spaceXSmall),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
      ),
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
