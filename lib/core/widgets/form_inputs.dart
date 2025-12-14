// Reusable form input widgets with consistent styling.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

// A styled text form field with consistent Material 3 appearance.
//
// Features:
// - Consistent decoration following app theme
// - Optional leading icon
// - Optional helper text and error handling
// - Support for various input types (text, number, multiline)
//
// Example usage:
// ```dart
// FormInput(
//   label: 'Amount',
//   icon: Icons.attach_money,
//   keyboardType: TextInputType.number,
//   validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
// )
// ```
class FormInput extends StatelessWidget {
  // Label text for the field
  final String label;

  // Optional hint text
  final String? hint;

  // Optional icon displayed at the start
  final IconData? icon;

  // Text controller
  final TextEditingController? controller;

  // Initial value
  final String? initialValue;

  // Keyboard type
  final TextInputType? keyboardType;

  // Input formatters
  final List<TextInputFormatter>? inputFormatters;

  // Validator function
  final String? Function(String?)? validator;

  // On changed callback
  final void Function(String)? onChanged;

  // Whether field is enabled
  final bool enabled;

  // Maximum lines (use >1 for multiline text)
  final int maxLines;

  // Minimum lines for multiline text
  final int? minLines;

  // Whether to obscure text (for passwords)
  final bool obscureText;

  // Optional suffix widget
  final Widget? suffix;

  // Optional prefix widget
  final Widget? prefix;

  const FormInput({
    super.key,
    required this.label,
    this.hint,
    this.icon,
    this.controller,
    this.initialValue,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.suffix,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      enabled: enabled,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : prefix,
        suffixIcon: suffix,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
    );
  }
}

// A dropdown field with consistent styling.
//
// Example usage:
// ```dart
// DropdownField<String>(
//   label: 'Category',
//   icon: Icons.category,
//   value: selectedCategory,
//   items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
//   onChanged: (value) => setState(() => selectedCategory = value),
// )
// ```
class DropdownField<T> extends StatelessWidget {
  // Label text for the field
  final String label;

  // Optional icon displayed at the start
  final IconData? icon;

  // Current selected value
  final T? value;

  // List of dropdown items
  final List<DropdownMenuItem<T>> items;

  // On changed callback
  final void Function(T?)? onChanged;

  // Whether field is enabled
  final bool enabled;

  // Validator function
  final String? Function(T?)? validator;

  const DropdownField({
    super.key,
    required this.label,
    this.icon,
    required this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.validator,
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
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: enabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
          borderSide: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppConstants.borderRadiusSmall,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
      ),
    );
  }
}
