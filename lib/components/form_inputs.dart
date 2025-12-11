library;

/// Form Input Widgets
///
/// Reusable form field components with consistent styling.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'design_system.dart';

/// A styled text form field with consistent Material 3 design
class FormInput extends StatelessWidget {
  /// Label text
  final String label;

  /// Hint text
  final String? hint;

  /// Initial value
  final String? initialValue;

  /// Controller
  final TextEditingController? controller;

  /// Validator function
  final String? Function(String?)? validator;

  /// On changed callback
  final void Function(String)? onChanged;

  /// On saved callback
  final void Function(String?)? onSaved;

  /// Leading icon
  final IconData? leadingIcon;

  /// Trailing icon
  final Widget? suffixIcon;

  /// Keyboard type
  final TextInputType? keyboardType;

  /// Whether this is a password field
  final bool obscureText;

  /// Max lines (1 for single line, null for unlimited)
  final int? maxLines;

  /// Min lines
  final int? minLines;

  /// Whether this field is read-only
  final bool readOnly;

  /// Input formatters
  final List<TextInputFormatter>? inputFormatters;

  /// Whether this field is enabled
  final bool enabled;

  /// Focus node
  final FocusNode? focusNode;

  /// Text input action
  final TextInputAction? textInputAction;

  /// On field submitted callback
  final void Function(String)? onFieldSubmitted;

  const FormInput({
    super.key,
    required this.label,
    this.hint,
    this.initialValue,
    this.controller,
    this.validator,
    this.onChanged,
    this.onSaved,
    this.leadingIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.readOnly = false,
    this.inputFormatters,
    this.enabled = true,
    this.focusNode,
    this.textInputAction,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      readOnly: readOnly,
      inputFormatters: inputFormatters,
      enabled: enabled,
      focusNode: focusNode,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: leadingIcon != null ? Icon(leadingIcon) : null,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.input,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.danger,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}

/// A styled dropdown field with consistent Material 3 design
class DropdownField<T> extends StatelessWidget {
  /// Label text
  final String label;

  /// Hint text
  final String? hint;

  /// Current value
  final T? value;

  /// Available items
  final List<DropdownMenuItem<T>> items;

  /// On changed callback
  final void Function(T?)? onChanged;

  /// Validator function
  final String? Function(T?)? validator;

  /// Leading icon
  final IconData? leadingIcon;

  /// Whether this field is enabled
  final bool enabled;

  const DropdownField({
    super.key,
    required this.label,
    this.hint,
    required this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.leadingIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: leadingIcon != null ? Icon(leadingIcon) : null,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: AppRadius.input,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.danger,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.input,
          borderSide: BorderSide(
            color: colorScheme.danger,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      borderRadius: AppRadius.input,
      dropdownColor: colorScheme.surface,
    );
  }
}
