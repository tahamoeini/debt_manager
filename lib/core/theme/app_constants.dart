// Design system constants for consistent spacing, sizing, and styling.
import 'package:flutter/material.dart';

// App-wide design constants following Material 3 guidelines.
class AppConstants {
  // Spacing
  static const double spaceXSmall = 4.0;
  static const double spaceSmall = 8.0;
  static const double spaceMedium = 12.0;
  static const double spaceLarge = 16.0;
  static const double spaceXLarge = 20.0;
  static const double spaceXXLarge = 24.0;

  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;

  // Border radius objects for reuse
  static const BorderRadius borderRadiusSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius borderRadiusMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius borderRadiusLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius borderRadiusXLarge = BorderRadius.all(
    Radius.circular(radiusXLarge),
  );

  // Padding
  static const EdgeInsets paddingSmall = EdgeInsets.all(spaceSmall);
  static const EdgeInsets paddingMedium = EdgeInsets.all(spaceMedium);
  static const EdgeInsets paddingLarge = EdgeInsets.all(spaceLarge);
  static const EdgeInsets paddingXLarge = EdgeInsets.all(spaceXLarge);

  static const EdgeInsets paddingHorizontalSmall = EdgeInsets.symmetric(
    horizontal: spaceSmall,
  );
  static const EdgeInsets paddingHorizontalMedium = EdgeInsets.symmetric(
    horizontal: spaceMedium,
  );
  static const EdgeInsets paddingHorizontalLarge = EdgeInsets.symmetric(
    horizontal: spaceLarge,
  );

  static const EdgeInsets paddingVerticalSmall = EdgeInsets.symmetric(
    vertical: spaceSmall,
  );
  static const EdgeInsets paddingVerticalMedium = EdgeInsets.symmetric(
    vertical: spaceMedium,
  );
  static const EdgeInsets paddingVerticalLarge = EdgeInsets.symmetric(
    vertical: spaceLarge,
  );

  // Page padding - standard padding for screen content
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: spaceLarge,
    vertical: spaceMedium,
  );

  // Card padding - standard padding for card content
  static const EdgeInsets cardPadding = EdgeInsets.all(spaceMedium);

  // Icon sizes
  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  // Progress bar dimensions
  static const double progressBarHeight = 8.0;
  static const double progressBarWidth = 100.0;

  // Animation durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationMedium = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 600);

  // Budget thresholds for color coding
  static const double budgetWarningThreshold = 0.6; // 60% usage shows warning
  static const double budgetDangerThreshold = 0.9; // 90% usage shows danger

  // Support and bug reporting
  static const String supportEmail = 'support@debtmanager.app';

  AppConstants._(); // Private constructor to prevent instantiation
}
