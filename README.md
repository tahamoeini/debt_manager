# debt_manager

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
