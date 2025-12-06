# debt_manager

A Flutter application for managing debts, loans, budgets, and installments with a focus on Persian/Farsi localization.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

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
