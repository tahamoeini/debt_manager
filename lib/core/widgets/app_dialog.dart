// Reusable dialog widgets with consistent Material 3 styling.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

/// A base dialog widget with consistent Material 3 styling.
///
/// Features:
/// - Rounded corners
/// - Consistent padding and spacing
/// - Optional icon at the top
/// - Title and content area
/// - Action buttons at the bottom
///
/// Example usage:
/// ```dart
/// AppDialog(
///   title: 'Confirm Delete',
///   content: Text('Are you sure you want to delete this item?'),
///   actions: [
///     TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
///     ElevatedButton(onPressed: onDelete, child: Text('Delete')),
///   ],
/// )
/// ```
class AppDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog content widget
  final Widget content;

  /// Action buttons (typically Cancel and Confirm)
  final List<Widget> actions;

  /// Optional icon displayed at the top
  final IconData? icon;

  /// Icon color (defaults to primary color)
  final Color? iconColor;

  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppConstants.borderRadiusLarge,
      ),
      child: Padding(
        padding: AppConstants.paddingLarge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            if (icon != null) ...[
              Icon(
                icon,
                size: 48,
                color: iconColor ?? colorScheme.primary,
              ),
              const SizedBox(height: AppConstants.spaceMedium),
            ],
            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.spaceMedium),
            // Content
            content,
            const SizedBox(height: AppConstants.spaceXLarge),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: actions
                  .map((action) => Padding(
                        padding: const EdgeInsets.only(left: AppConstants.spaceSmall),
                        child: action,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// A confirmation dialog for yes/no actions.
///
/// Example usage:
/// ```dart
/// final result = await showDialog<bool>(
///   context: context,
///   builder: (context) => ConfirmDialog(
///     title: 'Delete Item',
///     message: 'Are you sure you want to delete this item? This cannot be undone.',
///     confirmText: 'Delete',
///     cancelText: 'Cancel',
///     isDestructive: true,
///   ),
/// );
/// ```
class ConfirmDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Confirmation message
  final String message;

  /// Text for confirm button
  final String confirmText;

  /// Text for cancel button
  final String cancelText;

  /// Whether this is a destructive action (uses danger color)
  final bool isDestructive;

  /// Optional icon
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'تأیید',
    this.cancelText = 'لغو',
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: title,
      icon: icon ?? (isDestructive ? Icons.warning_amber : Icons.help_outline),
      iconColor: isDestructive ? colorScheme.error : null,
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.error,
                  foregroundColor: colorScheme.onError,
                )
              : null,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
