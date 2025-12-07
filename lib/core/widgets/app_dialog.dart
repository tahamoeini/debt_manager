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
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

/// A reusable dialog wrapper that provides consistent Material 3 styling.
/// Use this as a base for all dialogs in the app to maintain consistency.
/// 
/// Example usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => AppDialog(
///     title: 'تایید حذف',
///     content: Text('آیا مطمئن هستید؟'),
///     actions: [
///       TextButton(
///         onPressed: () => Navigator.pop(context),
///         child: Text('خیر'),
///       ),
///       ElevatedButton(
///         onPressed: () => Navigator.pop(context, true),
///         child: Text('بله'),
///       ),
///     ],
///   ),
/// )
/// ```
class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? content;
  final List<Widget>? actions;
  final EdgeInsets? contentPadding;
  final EdgeInsets? actionsPadding;

  const AppDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.contentPadding,
    this.actionsPadding,
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
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.dialogBorderRadius,
      ),
      title: title != null
          ? Text(
              title!,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
      content: content,
      contentPadding: contentPadding ?? AppDimensions.dialogPadding,
      actionsPadding: actionsPadding ??
          const EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: 16,
          ),
      actions: actions,
    );
  }
}

/// A confirmation dialog with standard Yes/No actions
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final bool isDangerous;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'تایید',
    this.cancelText = 'لغو',
    this.isDangerous = false,
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
    final colorScheme = Theme.of(context).colorScheme;

    return AppDialog(
      title: title,
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
          style: isDangerous
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

/// Helper function to show a confirmation dialog
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'تایید',
  String cancelText = 'لغو',
  bool isDangerous = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => ConfirmationDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      isDangerous: isDangerous,
    ),
  );
  return result ?? false;
}
