# Design System Documentation

This document describes the reusable UI components and design patterns used throughout the Debt Manager app.

## Overview

The app uses a component-based design system built on Material 3 principles. All components are located in `lib/core/widgets/` and theme constants in `lib/core/theme/`.

## Theme System

### Color Extensions

The app extends Flutter's `ColorScheme` with semantic colors for consistent meaning across the UI:

- **Success/Income** (`colorScheme.success`, `colorScheme.income`) - Green color for positive states
- **Warning** (`colorScheme.warning`) - Orange color for warning states (e.g., budget approaching limit)
- **Danger/Expense** (`colorScheme.danger`, `colorScheme.expense`) - Red color for negative states or errors

These colors automatically adapt to light and dark themes.

**Usage:**
```dart
import 'package:debt_manager/core/theme/app_theme_extensions.dart';

Container(
  color: Theme.of(context).colorScheme.success,
)
```

### Design Constants

All spacing, sizing, and border radius values are defined in `AppConstants`:

- **Spacing**: `spaceXSmall` (4), `spaceSmall` (8), `spaceMedium` (12), `spaceLarge` (16), `spaceXLarge` (20), `spaceXXLarge` (24)
- **Border Radius**: `radiusSmall` (8), `radiusMedium` (12), `radiusLarge` (16), `radiusXLarge` (20)
- **Padding**: Pre-defined EdgeInsets for common patterns (`paddingSmall`, `paddingMedium`, `paddingLarge`, `pagePadding`, `cardPadding`)
- **Icons**: Standard sizes (`iconSizeSmall`, `iconSizeMedium`, `iconSizeLarge`)
- **Animations**: Standard durations (`animationFast`, `animationMedium`, `animationSlow`)
- **Budget Thresholds**: Color change thresholds for budget indicators

**Usage:**
```dart
import 'package:debt_manager/core/theme/app_constants.dart';

Padding(
  padding: AppConstants.pagePadding,
  child: Container(
    decoration: BoxDecoration(
      borderRadius: AppConstants.borderRadiusMedium,
    ),
  ),
)
```

## Reusable Widgets

### DashboardCard

A card widget for displaying statistics and metrics on dashboards.

**Features:**
- Elevated container with rounded corners
- Optional icon
- Title, value, and subtitle
- Customizable accent color

**Usage:**
```dart
DashboardCard(
  title: 'Total Balance',
  value: '۱٬۲۳۴٬۵۶۷ ریال',
  subtitle: 'As of today',
  icon: Icons.account_balance_wallet,
  color: Theme.of(context).colorScheme.primary,
)
```

### TransactionTile

A list tile for displaying transaction items with consistent formatting.

**Features:**
- Color-coded by transaction type (green for income, red for expense)
- Icon indicator
- Title, subtitle, and amount
- Optional trailing widget
- Tap callback support

**Usage:**
```dart
TransactionTile(
  title: 'Grocery Shopping',
  subtitle: '1402/09/15',
  amount: 150000,
  type: TransactionType.expense,
  category: 'food',
  onTap: () => showDetails(),
)
```

### BudgetBar

A progress bar widget for displaying budget utilization with color-coded thresholds.

**Features:**
- Linear progress indicator with rounded ends
- Automatic color changes: green (<60%), orange (<90%), red (>=90%)
- Optional percentage and amount display
- Customizable dimensions

**Usage:**
```dart
BudgetBar(
  current: 450000,
  limit: 500000,
  label: 'Food Budget',
  showPercentage: true,
  showAmount: true,
)
```

### CategoryIcon

A circular icon for representing categories visually.

**Features:**
- Color-coded by category (from `category_colors.dart`)
- Category-specific icons
- Consistent circular style
- Optional label variant

**Usage:**
```dart
CategoryIcon(
  category: 'food',
  size: 40,
)

// With label
CategoryIconWithLabel(
  category: 'food',
  label: 'Food & Dining',
)
```

**Available Categories:**
- food, utilities, transport, shopping, rent, entertainment, health, education, savings, general

### AppDialog & ConfirmDialog

Base dialog widgets with consistent Material 3 styling.

**Features:**
- Rounded corners
- Optional icon at top
- Title, content, and action buttons
- Confirmation dialog variant for yes/no actions

**Usage:**
```dart
// Basic dialog
showDialog(
  context: context,
  builder: (context) => AppDialog(
    title: 'Delete Item',
    content: Text('Are you sure?'),
    actions: [
      TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
      ElevatedButton(onPressed: onDelete, child: Text('Delete')),
    ],
  ),
);

// Confirmation dialog
final result = await showDialog<bool>(
  context: context,
  builder: (context) => ConfirmDialog(
    title: 'Delete Item',
    message: 'This action cannot be undone.',
    confirmText: 'Delete',
    cancelText: 'Cancel',
    isDestructive: true,
  ),
);
```

### FormInput & DropdownField

Styled form input widgets with consistent appearance.

**Features:**
- Material 3 outlined style
- Optional leading icon
- Validation support
- Filled background with theme colors
- Keyboard type support
- Input formatters

**Usage:**
```dart
FormInput(
  label: 'Amount',
  icon: Icons.attach_money,
  keyboardType: TextInputType.number,
  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
)

DropdownField<String>(
  label: 'Category',
  icon: Icons.category,
  value: selectedCategory,
  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
  onChanged: (value) => setState(() => selectedCategory = value),
)
```

## Guidelines

### Component Usage

1. **Always use theme values** - Don't hardcode colors, sizes, or spacing. Use `Theme.of(context)` and `AppConstants`.

2. **Prefer reusable components** - Before creating custom UI, check if a reusable component exists or can be extended.

3. **Maintain consistency** - When creating new components, follow the patterns established in existing widgets:
   - Use `AppConstants` for spacing and sizing
   - Support theme colors (light/dark mode)
   - Include proper documentation
   - Use semantic naming

4. **Test components** - Write widget tests for new components, especially for:
   - Color changes based on state
   - Theme adaptation (light/dark mode)
   - Edge cases (null values, empty strings, etc.)

### Adding New Components

When adding new reusable components:

1. Create the widget in `lib/core/widgets/`
2. Export it from `lib/core/widgets/widgets.dart`
3. Add comprehensive documentation with usage examples
4. Write widget tests in `test/widgets/`
5. Update this design guide

### Extending Categories

To add new categories:

1. Add the category icon to `_categoryIcons` map in `category_icon.dart`
2. Add the category color to `_categoryMap` in `core/utils/category_colors.dart`
3. Use the category name consistently across the app

## Import Shortcuts

For convenience, you can import all widgets at once:

```dart
// Import all widgets
import 'package:debt_manager/core/widgets/widgets.dart';

// Import theme system
import 'package:debt_manager/core/theme/theme.dart';
```

## Examples

### Creating a Dashboard Screen

```dart
ListView(
  padding: AppConstants.pagePadding,
  children: [
    Row(
      children: [
        Expanded(
          child: DashboardCard(
            title: 'Balance',
            value: formatCurrency(balance),
            icon: Icons.account_balance_wallet,
          ),
        ),
        SizedBox(width: AppConstants.spaceMedium),
        Expanded(
          child: DashboardCard(
            title: 'Budget Left',
            value: formatCurrency(budgetLeft),
            icon: Icons.savings,
          ),
        ),
      ],
    ),
  ],
)
```

### Creating a Budget List

```dart
BudgetBar(
  current: spent,
  limit: budgetLimit,
  label: 'Monthly Budget',
  showPercentage: true,
)
```

### Creating a Transaction List

```dart
ListView.builder(
  itemBuilder: (context, index) {
    final txn = transactions[index];
    return TransactionTile(
      title: txn.description,
      subtitle: formatDate(txn.date),
      amount: txn.amount,
      type: txn.amount > 0 ? TransactionType.income : TransactionType.expense,
      onTap: () => showTransactionDetail(txn),
    );
  },
)
```

## Future Enhancements

Planned improvements to the design system:

1. **State Management Integration** - Provider/Riverpod for shared data
2. **Animation Components** - Reusable animated transitions
3. **Chart Widgets** - Standard charts for reports
4. **Empty State Variants** - Different empty states for various contexts
5. **Loading Indicators** - Skeleton screens and shimmer effects
6. **Responsive Layouts** - Adaptive layouts for tablet/desktop

## Maintenance

When making changes to the design system:

1. Keep this documentation up to date
2. Ensure backward compatibility or provide migration guides
3. Test changes across light and dark themes
4. Test on different screen sizes if possible
5. Update widget tests as needed

---

For questions or suggestions about the design system, please open an issue or discussion on GitHub.
# Design System Implementation Summary

## Overview

This document summarizes the reusable components and design system created for the Debt Manager application. The implementation provides a comprehensive set of widgets and utilities that ensure UI consistency, reduce code duplication, and establish a solid foundation for future development.

## What Was Implemented

### 1. Design System Foundation (`lib/components/design_system.dart`)

**Constants and Standards:**
- **Spacing**: Standardized spacing values (xs: 4px, sm: 8px, md: 12px, lg: 16px, xl: 24px, xxl: 32px)
- **Border Radius**: Consistent corner rounding (sm: 8px, md: 12px, lg: 16px, xl: 20px)
- **Icon Sizes**: Standard icon dimensions (sm: 16px, md: 24px, lg: 32px, xl: 48px)
- **Elevation**: Shadow depths for Material Design

**Theme Extensions:**
- Custom semantic colors: success, warning, danger, info, income, expense, neutral
- Automatic dark/light mode adaptation
- Easy access via `Theme.of(context).successColor`, etc.

### 2. Reusable Widget Components

#### Dashboard Cards (`dashboard_card.dart`)
- **DashboardCard**: Versatile card for displaying stats and metrics
- **StatCard**: Simplified version for quick stat display
- Features: icons, subtitles, loading states, tap handling, accent colors

#### Budget Components (`budget_bar.dart`)
- **BudgetBar**: Color-coded progress bar for budget visualization
- **BudgetProgressCard**: Full card with category, amounts, and progress
- Auto-color based on thresholds: green (<60%), orange (60-90%), red (>90%)

#### Category Components (`category_icon.dart`, `category_icons.dart`)
- **CategoryIcon**: Consistent category icon display with multiple styles (icon, circle, square, dot)
- **CategoryChip**: Category label with icon (selectable)
- **CategoryIcons**: Centralized mapping of 15+ categories to icons and colors

#### Transaction Components (`transaction_tile.dart`)
- **TransactionTile**: Complete transaction list item
- Features: income/expense color coding, category icons, swipe actions (delete/edit)
- Automatic subtitle generation from date/payee/category

#### Form Components (`form_inputs.dart`)
- **FormInput**: Styled text input with Material 3 design
- **DropdownField**: Styled dropdown selector
- Features: validators, icons, hints, keyboard types, formatters

#### Dialog Components (`dialogs.dart`)
- **AppDialog**: Base dialog with consistent styling
- **ConfirmDialog**: Confirmation dialog with destructive variant
- **MessageDialog**: Simple message/info dialog
- **LoadingDialog**: Non-dismissible loading overlay

### 3. Documentation

- **Design System Guide** (`lib/components/README.md`): Comprehensive documentation with examples and best practices
- **Components Demo** (`lib/components/components_demo.dart`): Interactive demo of all components
- **Inline Documentation**: Every component has detailed code comments

### 4. Testing

Widget tests implemented for core components:
- `test/components/dashboard_card_test.dart`: 7 test cases
- `test/components/budget_bar_test.dart`: 9 test cases
- `test/components/transaction_tile_test.dart`: 10 test cases
- `test/components/category_icon_test.dart`: 9 test cases

Total: 35+ test cases covering:
- Component rendering
- User interactions
- Edge cases
- State management
- Theme adaptation

### 5. Integration with Existing Code

Updated screens to use new components:
- **HomeScreen**: Now uses DashboardCard for stats
- **BudgetScreen**: Now uses BudgetProgressCard with CategoryIcons
- **LoansListScreen**: Now uses CategoryIcon for visual indicators
- **SummaryCards**: Refactored to use DashboardCard

Code reduction:
- HomeScreen: Reduced from 79 to 53 lines (-33%)
- BudgetScreen: Reduced from 129 to 101 lines (-22%)
- SummaryCards: Reduced from 69 to 52 lines (-25%)

## Benefits

### 1. Consistency
- All UI elements follow the same design language
- Spacing, colors, and typography are standardized
- Components automatically adapt to theme changes

### 2. Maintainability
- Single source of truth for design constants
- Changes propagate across the entire app
- Easy to update styling globally

### 3. Developer Experience
- Simple, intuitive API for all components
- Comprehensive documentation and examples
- Type-safe with clear property names
- Reduced boilerplate code

### 4. Quality
- Thoroughly tested components
- Handles edge cases (null values, empty states, etc.)
- Accessible and responsive

### 5. Scalability
- Easy to add new components following established patterns
- Modular structure supports growth
- Foundation for future features

## File Structure

```
lib/components/
├── README.md                  # Comprehensive documentation
├── components.dart            # Barrel file for easy importing
├── design_system.dart         # Design constants and theme extensions
├── category_icons.dart        # Category icon/color mappings
├── dashboard_card.dart        # Dashboard stat cards
├── budget_bar.dart            # Budget progress components
├── category_icon.dart         # Category icon widgets
├── transaction_tile.dart      # Transaction list items
├── form_inputs.dart           # Form field components
├── dialogs.dart               # Dialog layouts
└── components_demo.dart       # Interactive demo

test/components/
├── dashboard_card_test.dart   # DashboardCard tests
├── budget_bar_test.dart       # BudgetBar tests
├── transaction_tile_test.dart # TransactionTile tests
└── category_icon_test.dart    # CategoryIcon tests
```

## Usage Examples

### Quick Start

```dart
// Import all components
import 'package:debt_manager/components/components.dart';

// Use design constants
padding: AppSpacing.pagePadding,
borderRadius: AppRadius.card,

// Use theme colors
color: Theme.of(context).successColor,

// Use components
DashboardCard(
  title: 'Balance',
  value: '1,234',
  icon: Icons.wallet,
)
```

### Example: Building a Dashboard

```dart
ListView(
  padding: AppSpacing.pagePadding,
  children: [
    // Stats row
    Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Income',
            value: '5,000',
            color: theme.incomeColor,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: StatCard(
            title: 'Expense',
            value: '3,000',
            color: theme.expenseColor,
          ),
        ),
      ],
    ),
    SizedBox(height: AppSpacing.lg),
    
    // Budget progress
    BudgetProgressCard(
      category: 'Food',
      current: 750,
      limit: 1000,
      icon: Icons.restaurant,
    ),
    
    SizedBox(height: AppSpacing.lg),
    
    // Recent transactions
    TransactionTile(
      title: 'Grocery Shopping',
      amount: 125,
      type: TransactionType.expense,
      category: 'food',
    ),
  ],
)
```

## Testing the Components

### Run All Tests
```bash
flutter test test/components/
```

### View Demo
The `ComponentsDemo` widget showcases all components. You can add it to your app for testing:

```dart
// Add to navigation or debug menu
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ComponentsDemo(),
  ),
);
```

## Best Practices

1. **Always use design constants**: Never hardcode spacing, colors, or radii
2. **Reference theme values**: Use `Theme.of(context)` for colors and typography
3. **Use semantic colors**: Prefer `successColor` over `Colors.green`
4. **Keep components simple**: Single responsibility principle
5. **Test components**: Write widget tests for custom components
6. **Document usage**: Add examples in code comments

## Future Enhancements

Potential additions to the design system:
- State management integration (Provider/Riverpod patterns)
- Advanced animations and transitions
- Chart and graph components
- Advanced form components (date/time pickers, sliders)
- Empty state and error state widgets
- Skeleton loading states
- Pull-to-refresh components
- Custom bottom sheets and modals

## Maintenance

### Adding New Components
1. Create file in `lib/components/`
2. Use design constants from `design_system.dart`
3. Reference theme values
4. Add widget tests in `test/components/`
5. Document in `README.md`
6. Export in `components.dart`

### Updating Design Constants
When design requirements change:
1. Update values in `design_system.dart`
2. Changes propagate automatically
3. Test affected screens
4. Update documentation if needed

## Migration Guide for Existing Code

To migrate existing screens to use the design system:

1. **Import components**: `import 'package:debt_manager/components/components.dart';`
2. **Replace hardcoded values**: Use `AppSpacing.*` and `AppRadius.*`
3. **Replace Cards**: Use `DashboardCard` instead of custom `Card` widgets
4. **Replace Lists**: Use `TransactionTile` for transaction items
5. **Replace Dialogs**: Use `ConfirmDialog`, `MessageDialog` instead of custom dialogs
6. **Replace Form Fields**: Use `FormInput` and `DropdownField`
7. **Test**: Verify functionality and appearance

## Conclusion

This design system implementation provides a solid foundation for building consistent, maintainable, and scalable UI in the Debt Manager app. By following the established patterns and using the reusable components, developers can build new features faster while maintaining the app's cohesive look and feel.

The investment in this design system will pay dividends in:
- Faster feature development
- Easier maintenance and updates
- Better user experience through consistency
- Higher code quality through reuse and testing
- Smoother collaboration among team members

---

**Note**: For detailed usage instructions and API documentation, refer to `lib/components/README.md`.
