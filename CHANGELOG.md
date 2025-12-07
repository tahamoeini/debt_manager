# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Phase 6: Settings & Personalization (Latest)
- **Theme & Display Settings**
  - Added font size options (Small, Default, Large) with live preview
  - Font scaling applies globally to all text elements
  - Theme toggle (Light/Dark/Auto) with persistent storage

- **Localization & Calendar**
  - Added language setting (English/Persian) for future localization
  - Calendar type setting (Gregorian/Jalali) to switch date formats
  - All dates can be displayed in either calendar system

- **Notifications Settings**
  - Master "Enable All Notifications" toggle
  - Individual toggles for bill reminders and budget alerts
  - Notification scheduling respects user preferences
  - Cancel all notifications when master toggle is disabled
  - Added loading indicator during bulk notification cancellation

- **Category Management**
  - New "Manage Categories" screen accessible from Settings
  - Add custom categories beyond the default set
  - Rename custom categories
  - Delete custom categories with warnings if used by budgets
  - Visual indicators for default vs. custom categories

- **Accessibility Improvements**
  - Semantic labels on all interactive elements (FAB, navigation)
  - Tooltips added to important buttons
  - Minimum 48px touch targets enforced globally via theme
  - MaterialTapTargetSize.padded for better accessibility
  - Screen reader friendly navigation

- **Performance Optimizations**
  - Database indices on installments (loan_id, due_date, status)
  - Database indices on loans (counterparty_id)
  - Database indices on budgets (period)
  - Optimized category duplicate checking using sets
  - Improved query performance for common operations

- **Delightful Elements**
  - Celebratory confetti animation when all loan installments are paid
  - Success feedback for important actions
  - Smooth transitions and animations

- **Code Quality**
  - Extracted magic numbers to named constants
  - Improved error handling for edge cases
  - Better performance for category operations
  - Settings stored using SharedPreferences with ValueNotifiers for reactive updates

### Previous Changes
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
- No breaking changes to database schema or persisted data formats.
- All new features are backward compatible with existing data.
- Settings are stored in SharedPreferences and won't affect existing installations.
- Smart features are enabled by default but can be toggled off
- All processing is local and privacy-respecting
- No new external dependencies required
- Database automatically migrates to version 5 on upgrade
