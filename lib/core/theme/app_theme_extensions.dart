// Theme extensions for custom colors and semantic color meanings.
import 'package:flutter/material.dart';

// Extension on ColorScheme to provide semantic colors for success, warning, and danger states.
// These colors adapt to light and dark mode automatically.
extension AppColorScheme on ColorScheme {
  // Color for success states (e.g., positive balance, income, completed)
  Color get success => brightness == Brightness.light
      ? const Color(0xFF2E7D32) // Green 800
      : const Color(0xFF66BB6A); // Green 400

  // Color for warning states (e.g., budget approaching limit)
  Color get warning => brightness == Brightness.light
      ? const Color(0xFFF57C00) // Orange 800
      : const Color(0xFFFFB74D); // Orange 300

  // Color for danger/error states (e.g., overdue, negative balance, budget exceeded)
  Color get danger => brightness == Brightness.light
      ? const Color(0xFFD32F2F) // Red 700
      : const Color(0xFFEF5350); // Red 400

  // Color for income/positive amounts
  Color get income => success;

  // Color for expense/negative amounts
  Color get expense => danger;
}
