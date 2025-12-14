import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

// A reusable styled dropdown field for consistent dropdown menus.
//
// Example usage:
// ```dart
// DropdownField<String>(
//   label: 'دسته‌بندی',
//   icon: Icons.category,
//   value: selectedCategory,
//   items: categories.map((cat) =>
//     DropdownMenuItem(value: cat, child: Text(cat))
//   ).toList(),
//   onChanged: (value) => setState(() => selectedCategory = value),
// )
// ```
class DropdownField<T> extends StatelessWidget {
  final String label;
  final IconData? icon;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?)? onChanged;
  final String? Function(T?)? validator;
  final String? hint;
  final bool enabled;

  const DropdownField({
    super.key,
    required this.label,
    this.icon,
    this.value,
    required this.items,
    this.onChanged,
    this.validator,
    this.hint,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: enabled ? onChanged : null,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: const OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: theme.colorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        floatingLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      dropdownColor: theme.cardColor,
      borderRadius: AppDimensions.inputBorderRadius,
    );
  }
}

// A category dropdown specifically for budget/transaction categories
class CategoryDropdownField extends StatelessWidget {
  final String? value;
  final List<String> categories;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const CategoryDropdownField({
    super.key,
    this.value,
    required this.categories,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownField<String>(
      label: 'دسته‌بندی',
      icon: Icons.category,
      value: value,
      items: categories
          .map(
            (category) => DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      hint: 'انتخاب دسته‌بندی',
      enabled: enabled,
    );
  }
}
