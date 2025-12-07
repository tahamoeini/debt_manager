/// Transaction List Tile Widget
/// 
/// A reusable widget for displaying transaction items in lists.
/// Provides consistent formatting and supports swipe actions.

import 'package:flutter/material.dart';
import 'category_icon.dart';
import 'package:debt_manager/components/design_system.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

/// Type of transaction
enum TransactionType {
  income,
  expense,
}

/// A list tile widget for displaying transaction information
class TransactionTile extends StatelessWidget {
  /// Transaction title/description
  final String title;

  /// Transaction amount (in base currency units)
  final int amount;

  /// Type of transaction (income or expense)
  final TransactionType type;

  /// Optional date
  final String? date;

  /// Optional payee/payer name
  final String? payee;

  /// Optional category
  final String? category;

  /// Optional subtitle (overrides generated subtitle)
  final String? subtitle;

  /// Tap handler
  final VoidCallback? onTap;

  /// Optional swipe to delete handler
  final VoidCallback? onDelete;

  /// Optional swipe to edit handler
  final VoidCallback? onEdit;

  /// Whether to show the category icon
  final bool showCategoryIcon;

  const TransactionTile({
    super.key,
    required this.title,
    required this.amount,
    required this.type,
    this.date,
    this.payee,
    this.category,
    this.subtitle,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.showCategoryIcon = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine amount color based on type
    final amountColor = type == TransactionType.income
        ? colorScheme.income
        : colorScheme.expense;

    // Build subtitle
    String? effectiveSubtitle = subtitle;
    if (effectiveSubtitle == null) {
      final parts = <String>[];
      if (payee != null && payee!.isNotEmpty) parts.add(payee!);
      if (category != null && category!.isNotEmpty) parts.add(category!);
      if (date != null && date!.isNotEmpty) parts.add(date!);
      effectiveSubtitle = parts.isNotEmpty ? parts.join(' · ') : null;
    }

    Widget tileContent = Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: AppSpacing.listItemPadding,
        leading: showCategoryIcon && category != null
            ? CategoryIcon(
                category: category,
                style: CategoryIconStyle.circle,
                size: AppIconSize.lg,
              )
            : Icon(
                type == TransactionType.income
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                color: amountColor,
              ),
        title: Text(
          title.isNotEmpty ? title : 'بدون عنوان',
          style: textTheme.titleMedium,
        ),
        subtitle: effectiveSubtitle != null
            ? Text(
                effectiveSubtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
              )
            : null,
        trailing: Text(
          '${type == TransactionType.income ? '+' : '-'}${formatCurrency(amount.abs())}',
          style: textTheme.titleMedium?.copyWith(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: onTap,
      ),
    );

    // Wrap with Dismissible if swipe actions are provided
    if (onDelete != null || onEdit != null) {
      return Dismissible(
        key: ValueKey('$title-$amount-${payee ?? ""}-${category ?? ""}'),
        background: Container(
          decoration: BoxDecoration(
            color: colorScheme.danger,
            borderRadius: AppRadius.card,
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.lg),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        secondaryBackground: onEdit != null
            ? Container(
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: AppRadius.card,
                ),
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: AppSpacing.lg),
                child: const Icon(Icons.edit_outlined, color: Colors.white),
              )
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.endToStart && onEdit != null) {
            onEdit!();
            return false;
          } else if (direction == DismissDirection.startToEnd && onDelete != null) {
            // Show confirmation dialog
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('تأیید حذف'),
                content: const Text('آیا مطمئن هستید که می‌خواهید این مورد را حذف کنید؟'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('لغو'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('حذف', style: TextStyle(color: colorScheme.danger)),
                  ),
                ],
              ),
            );
            if (confirmed == true) {
              onDelete!();
            }
            return confirmed ?? false;
          }
          return false;
        },
        child: tileContent,
      );
    }

    return tileContent;
  }
}
