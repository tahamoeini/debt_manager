import 'package:flutter/material.dart';

// Design system constants for consistent spacing, padding, and border radius
// throughout the application. Using these constants ensures a cohesive UI.
class AppDimensions {
  // Prevent instantiation
  AppDimensions._();

  // Border Radius
  static const BorderRadius cardBorderRadius = BorderRadius.all(
    Radius.circular(12),
  );
  static const BorderRadius dialogBorderRadius = BorderRadius.all(
    Radius.circular(16),
  );
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(10),
  );
  static const BorderRadius inputBorderRadius = BorderRadius.all(
    Radius.circular(10),
  );

  static const double cardRadius = 12.0;
  static const double dialogRadius = 16.0;
  static const double buttonRadius = 10.0;
  static const double inputRadius = 10.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 20.0;
  static const double spacingXxl = 24.0;

  // Padding
  static const EdgeInsets pagePadding = EdgeInsets.all(16);
  static const EdgeInsets pageHorizontalPadding = EdgeInsets.symmetric(
    horizontal: 16,
  );
  static const EdgeInsets pageVerticalPadding = EdgeInsets.symmetric(
    vertical: 16,
  );
  static const EdgeInsets cardPadding = EdgeInsets.all(12);
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 8,
  );
  static const EdgeInsets dialogPadding = EdgeInsets.all(20);

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Category icon
  static const double categoryIconSize = 40.0;

  // Progress bar
  static const double progressBarHeight = 8.0;
  static const double progressBarHeightSmall = 6.0;
}
