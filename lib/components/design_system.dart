// Component: Design system constants
/// Design System Constants
///
/// This file contains all design constants used throughout the app to maintain
/// visual consistency. All widgets should reference these values rather than
/// hardcoded values.

import 'package:flutter/material.dart';

/// Spacing constants for consistent padding and margins
class AppSpacing {
  AppSpacing._();

  /// Extra small spacing (4px)
  static const double xs = 4.0;

  /// Small spacing (8px)
  static const double sm = 8.0;

  /// Medium spacing (12px)
  static const double md = 12.0;

  /// Large spacing (16px)
  static const double lg = 16.0;

  /// Extra large spacing (24px)
  static const double xl = 24.0;

  /// Extra extra large spacing (32px)
  static const double xxl = 32.0;

  /// Standard page padding (horizontal: 16, vertical: 8)
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );

  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(md);

  /// Standard list item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: sm,
  );
}

/// Border radius constants for consistent rounded corners
class AppRadius {
  AppRadius._();

  /// Small radius (8px)
  static const double sm = 8.0;

  /// Medium radius (12px) - default for cards
  static const double md = 12.0;

  /// Large radius (16px)
  static const double lg = 16.0;

  /// Extra large radius (20px)
  static const double xl = 20.0;

  /// Standard card border radius
  static const BorderRadius card = BorderRadius.all(Radius.circular(md));

  /// Standard button border radius
  static const BorderRadius button = BorderRadius.all(Radius.circular(sm));

  /// Standard dialog border radius
  static const BorderRadius dialog = BorderRadius.all(Radius.circular(lg));

  /// Standard input field border radius
  static const BorderRadius input = BorderRadius.all(Radius.circular(sm));
}

/// Icon size constants
class AppIconSize {
  AppIconSize._();

  /// Small icon size (16px)
  static const double sm = 16.0;

  /// Medium icon size (24px)
  static const double md = 24.0;

  /// Large icon size (32px)
  static const double lg = 32.0;

  /// Extra large icon size (48px)
  static const double xl = 48.0;
}

/// Extension on ColorScheme to add custom semantic colors
extension AppColorScheme on ColorScheme {
  /// Success color (typically green)
  Color get success => brightness == Brightness.light
      ? const Color(0xFF2E7D32)
      : const Color(0xFF66BB6A);

  /// Warning color (typically orange/amber)
  Color get warning => brightness == Brightness.light
      ? const Color(0xFFF57C00)
      : const Color(0xFFFFB74D);

  /// Danger/Error color (typically red)
  Color get danger => brightness == Brightness.light
      ? const Color(0xFFD32F2F)
      : const Color(0xFFEF5350);

  /// Info color (typically blue)
  Color get info => brightness == Brightness.light
      ? const Color(0xFF1976D2)
      : const Color(0xFF42A5F5);

  /// Income color (typically green, same as success)
  Color get income => success;

  /// Expense color (typically red, same as danger)
  Color get expense => danger;

  /// Neutral/disabled color
  Color get neutral => brightness == Brightness.light
      ? const Color(0xFF9E9E9E)
      : const Color(0xFF757575);
}

/// Extension on ThemeData for quick access to custom colors
extension AppThemeData on ThemeData {
  /// Quick access to custom color scheme extensions
  Color get successColor => colorScheme.success;
  Color get warningColor => colorScheme.warning;
  Color get dangerColor => colorScheme.danger;
  Color get infoColor => colorScheme.info;
  Color get incomeColor => colorScheme.income;
  Color get expenseColor => colorScheme.expense;
  Color get neutralColor => colorScheme.neutral;
}

/// Elevation constants for consistent shadows
class AppElevation {
  AppElevation._();

  /// No elevation
  static const double none = 0.0;

  /// Low elevation (1px)
  static const double low = 1.0;

  /// Medium elevation (2px)
  static const double medium = 2.0;

  /// High elevation (4px)
  static const double high = 4.0;

  /// Extra high elevation (8px)
  static const double extraHigh = 8.0;
}
