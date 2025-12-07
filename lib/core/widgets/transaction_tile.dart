// Reusable transaction list tile widget for displaying transaction items.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/core/theme/app_theme_extensions.dart';

/// Type of transaction for determining color and display
enum TransactionType {
  income,
  expense,
}

/// A reusable tile widget for displaying transaction items in lists.
///
/// This widget provides:
/// - Consistent formatting for transaction data
/// - Proper color coding (green for income, red for expense)
/// - Optional icon for transaction type
/// - Support for swipe actions via wrapping with Dismissible
///
/// Example usage:
/// ```dart
/// TransactionTile(
///   title: 'Grocery Shopping',
///   subtitle: '1402/09/15',
///   amount: 150000,
///   type: TransactionType.expense,
///   category: 'food',
///   onTap: () => showDetails(),
/// )
/// ```
class TransactionTile extends StatelessWidget {
  /// Main title (e.g., payee name or transaction description)
  final String title;

  /// Subtitle text (e.g., date, category)
  final String? subtitle;

  /// Transaction amount (will be formatted with proper sign and color)
  final int amount;

  /// Type of transaction (income or expense)
  final TransactionType type;

  /// Optional category for icon display
  final String? category;

  /// Optional icon to display (if not provided, uses default based on type)
  final IconData? icon;

  /// Callback when tile is tapped
  final VoidCallback? onTap;

  /// Optional trailing widget (e.g., status badge, action button)
  final Widget? trailing;
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

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
    required this.type,
    this.category,
    this.icon,
    this.onTap,
    this.trailing,
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
    final textTheme = theme.textTheme;

    // Determine color based on transaction type
    final amountColor = type == TransactionType.income
        ? colorScheme.income
        : colorScheme.expense;

    // Default icon based on type
    final displayIcon = icon ??
        (type == TransactionType.income
            ? Icons.arrow_downward
            : Icons.arrow_upward);

    // Format amount with sign
    final formattedAmount = '${type == TransactionType.expense ? '-' : '+'}${amount.abs()}';

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppConstants.spaceSmall,
        vertical: AppConstants.spaceXSmall,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusSmall,
      ),
      child: ListTile(
        contentPadding: AppConstants.paddingHorizontalMedium,
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          foregroundColor: amountColor,
          child: Icon(displayIcon, size: AppConstants.iconSizeSmall),
        ),
        title: Text(
          title,
          style: textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
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
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        trailing: trailing ??
            Text(
              formattedAmount,
              style: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: amountColor,
              ),
            ),
        onTap: onTap,
      ),
    );
  }
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
    final colorScheme = Theme.of(context).colorScheme;
    if (category == null) return colorScheme.primary;
    
    // Use the existing category color utility
    return colorForCategory(category, brightness: Theme.of(context).brightness);
  }

  String _formatAmount(int amount) {
    // Use the existing formatCurrency utility for consistency
    return formatCurrency(amount);
  }
}
