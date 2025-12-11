library;

/// Reusable Dialog Widgets
///
/// Consistent dialog layouts with Material 3 design.

import 'package:flutter/material.dart';
import 'design_system.dart';

/// A base dialog widget with consistent styling
class AppDialog extends StatelessWidget {
  /// Dialog title
  final String? title;

  /// Dialog content
  final Widget content;

  /// List of action buttons
  final List<Widget>? actions;

  /// Whether the dialog is scrollable
  final bool scrollable;

  /// Optional icon to display above the title
  final IconData? icon;

  /// Optional color for the icon
  final Color? iconColor;

  const AppDialog({
    super.key,
    this.title,
    required this.content,
    this.actions,
    this.scrollable = true,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.dialog,
      ),
      title: title != null || icon != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: AppIconSize.xl,
                    color: iconColor ?? colorScheme.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                if (title != null)
                  Text(
                    title!,
                    style: textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
              ],
            )
          : null,
      content: scrollable ? SingleChildScrollView(child: content) : content,
      actions: actions,
      actionsPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
    );
  }
}

/// A confirmation dialog
class ConfirmDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog message
  final String message;

  /// Confirm button text (default: "تأیید")
  final String? confirmText;

  /// Cancel button text (default: "لغو")
  final String? cancelText;

  /// Whether this is a destructive action (uses danger color)
  final bool isDestructive;

  /// Optional icon
  final IconData? icon;

  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText,
    this.cancelText,
    this.isDestructive = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppDialog(
      title: title,
      icon: icon ??
          (isDestructive ? Icons.warning_outlined : Icons.info_outlined),
      iconColor: isDestructive ? colorScheme.danger : colorScheme.primary,
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      scrollable: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText ?? 'لغو'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor:
                isDestructive ? colorScheme.danger : colorScheme.primary,
          ),
          child: Text(confirmText ?? 'تأیید'),
        ),
      ],
    );
  }

  /// Show a confirmation dialog and return the result
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDestructive = false,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        isDestructive: isDestructive,
        icon: icon,
      ),
    );
    return result ?? false;
  }
}

/// An information/message dialog
class MessageDialog extends StatelessWidget {
  /// Dialog title
  final String title;

  /// Dialog message
  final String message;

  /// Button text (default: "باشه")
  final String? buttonText;

  /// Optional icon
  final IconData? icon;

  /// Optional icon color
  final Color? iconColor;

  const MessageDialog({
    super.key,
    required this.title,
    required this.message,
    this.buttonText,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      icon: icon ?? Icons.info_outlined,
      iconColor: iconColor,
      content: Text(
        message,
        textAlign: TextAlign.center,
      ),
      scrollable: false,
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText ?? 'باشه'),
        ),
      ],
    );
  }

  /// Show a message dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog(
      context: context,
      builder: (context) => MessageDialog(
        title: title,
        message: message,
        buttonText: buttonText,
        icon: icon,
        iconColor: iconColor,
      ),
    );
  }
}

/// A loading dialog
class LoadingDialog extends StatelessWidget {
  /// Loading message
  final String? message;

  const LoadingDialog({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.lg),
              Text(
                message!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Show a loading dialog
  static void show(BuildContext context, {String? message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LoadingDialog(message: message),
    );
  }

  /// Dismiss the loading dialog
  static void dismiss(BuildContext context) {
    Navigator.of(context).pop();
  }
}
