import 'package:flutter/material.dart';

/// Extension on ColorScheme to provide custom semantic colors for the app.
/// These colors respect dark/light mode and provide consistent colors for
/// success, warning, danger, and budget status indicators.
extension AppColors on ColorScheme {
  /// Success color (positive amounts, completed actions)
  Color get success => brightness == Brightness.light
      ? const Color(0xFF2E7D32) // Green 800
      : const Color(0xFF66BB6A); // Green 400

  /// Warning color (budget approaching limit)
  Color get warning => brightness == Brightness.light
      ? const Color(0xFFF57C00) // Orange 700
      : const Color(0xFFFFB74D); // Orange 300

  /// Danger/Error color (negative amounts, overdue, budget exceeded)
  Color get danger => brightness == Brightness.light
      ? const Color(0xFFD32F2F) // Red 700
      : const Color(0xFFEF5350); // Red 400

  /// Income color (positive cash flow)
  Color get income => success;

  /// Expense color (negative cash flow)
  Color get expense => danger;

  /// Budget status colors based on utilization percentage
  Color budgetStatusColor(double utilizationPercent) {
    if (utilizationPercent < 0.6) {
      return success;
    } else if (utilizationPercent < 0.9) {
      return warning;
    } else {
      return danger;
    }
  }

  /// Subtle background for cards and containers
  Color get cardBackground =>
      brightness == Brightness.light ? surface : surfaceContainerHighest;
}
