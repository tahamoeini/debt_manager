import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';

/// A reusable list tile widget for displaying transaction/installment information.
/// Provides consistent formatting with proper color coding for income/expense.
/// 
/// Example usage:
/// ```dart
/// TransactionTile(
///   title: 'خرید مواد غذایی',
///   subtitle: '۱۴۰۲/۰۹/۱۵',
///   amount: 50000,
///   isExpense: true,
///   category: 'food',
///   onTap: () => ...,
/// )
/// ```
class TransactionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final int amount;
  final bool isExpense;
  final String? category;
  final IconData? leadingIcon;
  final VoidCallback? onTap;
  final bool showCategoryIndicator;

  const TransactionTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    this.isExpense = true,
    this.category,
    this.leadingIcon,
    this.onTap,
    this.showCategoryIndicator = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amountColor = isExpense ? colorScheme.expense : colorScheme.income;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: AppDimensions.spacingXs),
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.cardBorderRadius,
      ),
      child: ListTile(
        leading: _buildLeading(context),
        title: Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: theme.textTheme.bodyMedium,
              )
            : null,
        trailing: Text(
          '${isExpense ? '-' : '+'}${_formatAmount(amount)}',
          style: theme.textTheme.titleMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
        contentPadding: AppDimensions.listItemPadding,
      ),
    );
  }

  Widget? _buildLeading(BuildContext context) {
    if (leadingIcon != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return CircleAvatar(
        radius: 20,
        backgroundColor: colorScheme.secondaryContainer,
        child: Icon(
          leadingIcon,
          size: AppDimensions.iconSizeMedium,
          color: colorScheme.onSecondaryContainer,
        ),
      );
    }

    if (showCategoryIndicator && category != null) {
      // Show a simple colored dot for the category
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _getCategoryColor(context),
          shape: BoxShape.circle,
        ),
      );
    }

    return null;
  }

  Color _getCategoryColor(BuildContext context) {
    // Import the existing category_colors utility
    // For now, return a basic color
    final colorScheme = Theme.of(context).colorScheme;
    return colorScheme.primary;
  }

  String _formatAmount(int amount) {
    // Basic formatting - actual app should use formatCurrency from format_utils
    final s = amount.abs().toString();
    final withSep = s.replaceAllMapped(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      (m) => ',',
    );
    return '$withSep ریال';
  }
}
