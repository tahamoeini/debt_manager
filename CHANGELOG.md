# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Smart Features (Latest)
- Added intelligent bill and payment reminders with configurable notification timing
- Implemented budget threshold alerts (90% and 100% warnings)
- Added month-end budget performance summaries
- Created smart subscription detection (identifies recurring payments)
- Implemented bill amount change detection (alerts for >20% increases)
- Added automation rules for auto-categorization of transactions
- Built-in payee dictionary for common categories (Transportation, Dining, Utilities, etc.)
- Added comprehensive help screen explaining all smart features
- Integrated budget checking with transaction flow
- Added smart insights widget on home screen
- All features work offline and are battery-optimized
- Database schema updated to version 5 (added automation_rules table)

### Settings & Configuration
- Added toggles for all smart features:
  - Budget Alerts
  - Smart Suggestions
  - Finance Coach hints
  - Month-End Summary
- Added automation rules management screen
- Added help/about screen for user education
- All settings persisted and configurable

### Material 3 Theming
- Adopted Material 3 theming with light and dark color schemes.
- Added user-selectable theme mode (Auto / Light / Dark) persisted in settings.
- Improved typography and spacing for better readability (larger base font sizes).
- Updated form inputs to use outlined textfields and consistent button styling.
- Introduced category color accents with dark-mode adjustments.
- Replaced many icons with outlined Material variants for a cohesive modern look.
- Added a subtle animated empty-state helper (no extra assets required).
- Added `lib/core/utils/category_colors.dart` and UI enhancements in loans lists/details.

## Notes
- Smart features are enabled by default but can be toggled off
- All processing is local and privacy-respecting
- No new external dependencies required
- Database automatically migrates to version 5 on upgrade
