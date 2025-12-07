# Debt Manager

A Flutter application for managing debts, loans, installments, and budgets with Persian (Jalali) calendar support.

## Features

- Track loans and debts (borrowed and lent)
- Manage installments with due dates
- Budget tracking and monitoring
- Persian (Shamsi/Jalali) calendar integration
- Notifications for overdue installments
- Dark mode support

## Design System

This project uses a comprehensive design system with reusable UI components. For detailed information about using the design system, see [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md).

### Quick Start with Components

```dart
// Import reusable widgets
import 'package:debt_manager/core/widgets/widgets.dart';
import 'package:debt_manager/core/theme/theme.dart';

// Use dashboard cards
DashboardCard(
  title: 'Balance',
  value: formatCurrency(balance),
  icon: Icons.account_balance_wallet,
)

// Use budget bars
BudgetBar(
  current: spent,
  limit: budgetLimit,
  label: 'Monthly Budget',
)

// Use app constants
Container(
  padding: AppConstants.pagePadding,
  decoration: BoxDecoration(
    borderRadius: AppConstants.borderRadiusMedium,
  ),
)
```
A Flutter application for managing debts, loans, budgets, and installments with a focus on Persian/Farsi localization.
A comprehensive Flutter application for managing debts, loans, budgets, and financial tracking with Persian (Jalali) calendar support.

## Features

### 💰 Financial Management
- **Loan Tracking**: Track loans and debts with installment schedules
- **Budget Management**: Set and monitor monthly budgets by category
- **Counterparty Management**: Manage relationships with lenders and borrowers
- **Payment Tracking**: Record and track payments with automatic status updates

### 🎨 Appearance & Personalization
- **Theme Options**: Light, Dark, and Auto (system) themes
- **Font Size Settings**: Small, Default, and Large text options for accessibility
- **Custom Categories**: Add, rename, and delete custom budget categories
- **Responsive Design**: Material 3 design with adaptive layouts

### 🌍 Localization & Calendar
- **Dual Calendar Support**: Switch between Gregorian and Jalali (Persian) calendars
- **Multi-language Ready**: Support for English and Persian (Farsi)
- **Jalali Date Handling**: Native support for Persian calendar dates

### 🔔 Smart Notifications
- **Bill Reminders**: Automatic reminders for upcoming installments
- **Budget Alerts**: Notifications when approaching budget limits
- **Flexible Controls**: Master toggle and individual notification preferences
- **Configurable Timing**: Set reminder offset (0, 1, 3, or 7 days before due date)

### ♿ Accessibility
- **Screen Reader Support**: Semantic labels for all interactive elements
- **Touch Target Compliance**: Minimum 48dp touch targets on all buttons
- **Tooltip Support**: Helpful tooltips on important actions
- **High Contrast**: Works well with system accessibility settings
- **Font Scaling**: Respects user font size preferences

### 🎉 Delightful Experience
- **Celebration Animations**: Confetti animation when completing a debt
- **Progress Tracking**: Visual indicators for budget utilization
- **Smooth Transitions**: Animated UI elements and state changes

### 📊 Data Management
- **Local Storage**: All data stored locally with SQLite
- **Backup & Restore**: Export and import data as JSON
- **Performance Optimized**: Database indices for fast queries
- **Offline First**: Works completely offline

## Technical Highlights

### Architecture
- **Clean Code**: Separation of concerns with feature-based organization
- **Repository Pattern**: Data access through repositories
- **State Management**: ValueNotifiers for reactive UI updates
- **Settings Management**: SharedPreferences for user preferences

### Performance
- **Database Indices**: Optimized queries for installments, loans, and budgets
- **Lazy Loading**: Efficient data loading and caching
- **Minimal Rebuilds**: ValueListenableBuilder for targeted updates

### Platform Support
- ✅ Android
- ✅ iOS
- ✅ Web (with fallback for native features)
- ✅ Desktop (Linux, macOS, Windows)

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- Dart SDK

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Development

- **Analyze code**: `flutter analyze`
- **Run tests**: `flutter test`
- **Format code**: `dart format .`
- Flutter SDK (version 3.10.1 or higher)
- Dart SDK (included with Flutter)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/tahamoeini/debt_manager.git
cd debt_manager
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## Project Structure

```
lib/
├── core/
│   ├── db/              # Database layer (SQLite)
│   ├── theme/           # Theme system and constants
│   ├── widgets/         # Reusable UI components
│   ├── utils/           # Utility functions
│   ├── notifications/   # Notification service
│   ├── backup/          # Backup service
│   └── settings/        # Settings repository
├── features/
│   ├── loans/           # Loan management
│   ├── budget/          # Budget tracking
│   ├── accounts/        # Account management
│   ├── reports/         # Reports and analytics
│   └── settings/        # App settings
├── app.dart             # App widget
├── app_shell.dart       # Main navigation shell
└── main.dart            # Entry point
```

## Contributing

When contributing to this project:

1. Follow the established design system (see DESIGN_SYSTEM.md)
2. Use reusable components from `lib/core/widgets/`
3. Use design constants from `lib/core/theme/`
4. Write tests for new features
5. Run `flutter analyze` before committing
6. Ensure tests pass with `flutter test`

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Material 3 Design](https://m3.material.io/)
- [Shamsi Date Package](https://pub.dev/packages/shamsi_date) for Persian calendar support
├── app.dart                    # Main app configuration
├── app_shell.dart             # Navigation shell
├── main.dart                  # Entry point
├── core/
│   ├── backup/               # Backup and restore services
│   ├── categories/           # Category management
│   ├── db/                   # Database helper and queries
│   ├── notifications/        # Notification services
│   ├── settings/            # Settings repository
│   └── utils/               # Utility functions
└── features/
    ├── accounts/            # Account management screens
    ├── budget/              # Budget management
    ├── categories/          # Category management UI
    ├── home/                # Home screen
    ├── loans/               # Loan and installment management
    ├── reports/             # Financial reports
    ├── settings/            # Settings UI
    └── shared/              # Shared widgets
```

## Key Technologies

- **Flutter**: Cross-platform UI framework
- **SQLite**: Local database (via sqflite package)
- **shamsi_date**: Jalali calendar support
- **flutter_local_notifications**: Notification scheduling
- **shared_preferences**: Settings storage
- **Material 3**: Modern design system

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Design System

This project implements a comprehensive design system for consistency and maintainability. All new features should use these reusable components.

### Core Theme

- **AppDimensions** (`lib/core/theme/app_dimensions.dart`): Consistent spacing, padding, and border radius
- **AppColors** (`lib/core/theme/app_colors.dart`): Semantic color extensions for success, warning, danger, income, and expense

### Reusable Components

The app includes 8 reusable widget components in `lib/core/widgets/`:

1. **DashboardCard** - Cards for dashboard statistics
2. **StatCard** - Compact cards for overview displays
3. **TransactionTile** - Consistent transaction/installment list items
4. **BudgetProgressBar** - Progress bars with automatic color thresholds
5. **CategoryIcon** - Standardized category icons and badges
6. **AppDialog** - Consistent dialog wrapper
7. **FormInput** - Styled text input fields
8. **DropdownField** - Styled dropdown menus

### Usage

Import all widgets at once:
```dart
import 'package:debt_manager/core/widgets/widgets.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
```

For detailed documentation and examples, see [lib/core/widgets/README.md](lib/core/widgets/README.md).

### Design Guidelines

**Colors:**
- Use `colorScheme.success` for positive amounts and completed actions
- Use `colorScheme.danger` for negative amounts and overdue items
- Use `colorScheme.warning` for warnings and approaching limits

**Spacing:**
Use constants from `AppDimensions`:
- `spacingXs` (4px), `spacingS` (8px), `spacingM` (12px), `spacingL` (16px), `spacingXl` (20px)
- `pagePadding`, `cardPadding`, `listItemPadding`, `dialogPadding`

**Border Radius:**
- `cardBorderRadius` (12px), `dialogBorderRadius` (16px), `buttonBorderRadius` (10px), `inputBorderRadius` (10px)

## Testing

Run all tests:
```bash
flutter test
```

Run widget tests only:
```bash
flutter test test/widgets/
```

## Contributing

When adding new features:
1. Use existing reusable components where possible
2. Follow the design system guidelines
3. Add widget tests for new components
4. Document component usage in code comments
- Persian calendar implementation using shamsi_date package
- Material 3 design guidelines
- Flutter team for the excellent framework
