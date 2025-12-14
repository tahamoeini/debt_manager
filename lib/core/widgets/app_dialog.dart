// Reusable dialog widgets with consistent Material 3 styling.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

// A reusable dialog wrapper that provides consistent Material 3 styling.
// Use this as a base for all dialogs in the app to maintain consistency.
//
// Example usage:
// ```dart
// showDialog(
//   context: context,
//   builder: (context) => AppDialog(
//     title: 'تأیید حذف',
//     content: Text('آیا مطمئن هستید؟'),
//     actions: [
//       TextButton(
//         onPressed: () => Navigator.pop(context),
//         child: Text('خیر'),
//       ),
//       ElevatedButton(
//         onPressed: () => Navigator.pop(context, true),
//         child: Text('بله'),
//       ),
//     ],
//   ),
// )
// ```
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
    return AlertDialog(
      shape: const RoundedRectangleBorder(
        borderRadius: AppDimensions.dialogBorderRadius,
      ),
      title: title != null
          ? Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            )
          : null,
      content: content,
      contentPadding: contentPadding ?? AppDimensions.dialogPadding,
      actionsPadding:
          actionsPadding ??
          const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      actions: actions,
    );
  }
}

// A confirmation dialog with standard Yes/No actions
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
    this.confirmText = 'تأیید',
    this.cancelText = 'لغو',
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
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

// Helper function to show a confirmation dialog
Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmText = 'تأیید',
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
