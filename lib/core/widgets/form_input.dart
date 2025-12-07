import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

/// A reusable styled text input field with consistent Material 3 decoration.
/// Wraps TextFormField with app-wide styling.
/// 
/// Example usage:
/// ```dart
/// FormInput(
///   label: 'نام',
///   icon: Icons.person,
///   controller: nameController,
///   validator: (value) => value?.isEmpty ?? true ? 'الزامی' : null,
/// )
/// ```
class FormInput extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final int? minLines;
  final String? hint;
  final bool enabled;
  final void Function(String)? onChanged;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputAction? textInputAction;

  const FormInput({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.validator,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.minLines,
    this.hint,
    this.enabled = true,
    this.onChanged,
    this.inputFormatters,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: obscureText ? 1 : maxLines,
      minLines: minLines,
      enabled: enabled,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
      textInputAction: textInputAction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        filled: true,
        fillColor: theme.inputDecorationTheme.fillColor,
        border: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(
            color: theme.colorScheme.outline,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(
            color: theme.colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimensions.inputBorderRadius,
          borderSide: BorderSide(
            color: theme.colorScheme.error,
          ),
        ),
        floatingLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}

/// A numeric input field with Persian/Farsi digit support
class NumericFormInput extends StatelessWidget {
  final String label;
  final IconData? icon;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? hint;
  final bool enabled;
  final void Function(String)? onChanged;

  const NumericFormInput({
    super.key,
    required this.label,
    this.icon,
    this.controller,
    this.validator,
    this.hint,
    this.enabled = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return FormInput(
      label: label,
      icon: icon,
      controller: controller,
      validator: validator,
      keyboardType: TextInputType.number,
      hint: hint,
      enabled: enabled,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
    );
  }
}
