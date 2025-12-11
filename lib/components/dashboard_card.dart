library;

/// Dashboard Card Widget
/// 
/// A reusable card widget for displaying stats and metrics on dashboard screens.
/// Provides consistent styling with Material 3 design principles.

import 'package:flutter/material.dart';
import '../core/utils/color_extensions.dart';
import 'design_system.dart';

/// A card widget for displaying a statistic or metric on the dashboard
class DashboardCard extends StatelessWidget {
  /// The title/label of the stat
  final String title;

  /// The main value to display
  final String value;

  /// Optional subtitle text
  final String? subtitle;

  /// Optional icon to display
  final IconData? icon;

  /// Optional color for the card accent
  final Color? accentColor;

  /// Whether the card is tappable
  final VoidCallback? onTap;

  /// Whether to show a loading indicator instead of the value
  final bool isLoading;

  const DashboardCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final cardContent = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: accentColor?.withValues(alpha: 0.3) ?? 
                 colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppIconSize.md,
                    color: accentColor ?? colorScheme.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            if (isLoading)
              const SizedBox(
                height: 28,
                child: Center(
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              Text(
                value,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: accentColor ?? colorScheme.onSurface,
                ),
              ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: cardContent,
      );
    }

    return cardContent;
  }
}

/// A simplified stat card for quick metrics display
class StatCard extends StatelessWidget {
  /// The title/label of the stat
  final String title;

  /// The main value to display
  final String value;

  /// The color theme for this stat
  final Color color;

  /// Optional icon
  final IconData? icon;

  /// Optional tap handler
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      title: title,
      value: value,
      icon: icon,
      accentColor: color,
      onTap: onTap,
    );
  }
}
