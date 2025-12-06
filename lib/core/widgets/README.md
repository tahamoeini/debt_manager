# Reusable UI Components

This directory contains reusable widgets and components for the Debt Manager app. All components follow Material 3 design principles and support both light and dark themes.

## Design System

### Theme Extensions

- **AppDimensions** (`core/theme/app_dimensions.dart`): Consistent spacing, padding, and border radius values
- **AppColors** (`core/theme/app_colors.dart`): Semantic color extensions for success, warning, danger, income, and expense

### Usage

Import all widgets at once:
```dart
import 'package:debt_manager/core/widgets/widgets.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
```

## Components

### DashboardCard
A card widget for displaying dashboard statistics with title, value, and optional subtitle and icon.

```dart
DashboardCard(
  title: 'موجودی کل',
  value: '۱۲۳٬۴۵۶ ریال',
  subtitle: 'دارایی‌ها منهای بدهی‌ها',
  icon: Icons.account_balance_wallet,
  color: Colors.blue,
  onTap: () => ...,
)
```

### StatCard
A compact card for displaying statistics, useful in overview sections.

```dart
StatCard(
  title: 'بودجه باقی‌مانده',
  value: '۵۰٬۰۰۰ ریال',
  color: Colors.green,
  icon: Icons.trending_up,
  onTap: () => ...,
)
```

### TransactionTile
A list tile for displaying transaction/installment information with proper color coding.

```dart
TransactionTile(
  title: 'خرید مواد غذایی',
  subtitle: '۱۴۰۲/۰۹/۱۵',
  amount: 50000,
  isExpense: true,
  category: 'food',
  leadingIcon: Icons.shopping_cart,
  onTap: () => ...,
)
```

### BudgetProgressBar
A progress bar for displaying budget utilization with automatic color thresholds:
- Green: < 60% used
- Orange: 60-90% used
- Red: > 90% used

```dart
BudgetProgressBar(
  current: 75000,
  limit: 100000,
  label: 'خرید مواد غذایی',
  showPercentage: true,
  showAmounts: true,
)
```

### CategoryIcon
An icon widget for displaying categories with consistent styling.

```dart
CategoryIcon(
  category: 'food',
  icon: Icons.restaurant,
  size: 40,
)

// Or use a simple badge
CategoryBadge(
  category: 'transport',
  size: 12,
)
```

### AppDialog
A reusable dialog wrapper with consistent Material 3 styling.

```dart
showDialog(
  context: context,
  builder: (context) => AppDialog(
    title: 'تایید حذف',
    content: Text('آیا مطمئن هستید؟'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('خیر'),
      ),
      ElevatedButton(
        onPressed: () => Navigator.pop(context, true),
        child: Text('بله'),
      ),
    ],
  ),
)

// Or use the confirmation dialog helper
final confirmed = await showConfirmationDialog(
  context,
  title: 'حذف حساب',
  message: 'این عمل قابل برگشت نیست',
  confirmText: 'حذف',
  cancelText: 'انصراف',
  isDangerous: true,
);
```

### FormInput
A styled text input field with consistent decoration.

```dart
FormInput(
  label: 'نام',
  icon: Icons.person,
  controller: nameController,
  validator: (value) => value?.isEmpty ?? true ? 'الزامی' : null,
  keyboardType: TextInputType.text,
)

// For numeric inputs
NumericFormInput(
  label: 'مبلغ',
  icon: Icons.attach_money,
  controller: amountController,
  hint: 'به ریال',
)
```

### DropdownField
A styled dropdown menu for consistent dropdowns.

```dart
DropdownField<String>(
  label: 'دسته‌بندی',
  icon: Icons.category,
  value: selectedCategory,
  items: categories.map((cat) => 
    DropdownMenuItem(value: cat, child: Text(cat))
  ).toList(),
  onChanged: (value) => setState(() => selectedCategory = value),
)

// Or use the category-specific dropdown
CategoryDropdownField(
  value: selectedCategory,
  categories: ['food', 'transport', 'utilities'],
  onChanged: (value) => ...,
)
```

## Design Guidelines

### Colors
- Use `colorScheme.success` for positive amounts and completed actions
- Use `colorScheme.danger` for negative amounts and overdue items
- Use `colorScheme.warning` for warnings and approaching limits
- Use `colorScheme.income` and `colorScheme.expense` for financial transactions

### Spacing
Use constants from `AppDimensions`:
- `spacingXs` (4px), `spacingS` (8px), `spacingM` (12px), `spacingL` (16px), `spacingXl` (20px), `spacingXxl` (24px)
- `pagePadding`, `cardPadding`, `listItemPadding`, `dialogPadding`

### Border Radius
Use constants from `AppDimensions`:
- `cardBorderRadius` (12px)
- `dialogBorderRadius` (16px)
- `buttonBorderRadius` (10px)
- `inputBorderRadius` (10px)

### Adaptability
All components:
- Reference theme values rather than fixed colors
- Support both light and dark modes
- Respond to text size changes
- Are tested on different screen sizes

## Testing

Widget tests are located in `test/widgets/` and cover:
- Component rendering
- Color logic (expense/income, budget thresholds)
- Theme adaptability
- Interaction behavior

Run tests with:
```bash
flutter test test/widgets/
```

## Adding New Components

When creating new reusable components:
1. Place them in this directory
2. Follow Material 3 design principles
3. Use theme values and AppDimensions constants
4. Support light/dark themes
5. Add to the exports in `widgets.dart`
6. Document usage in this README
7. Write widget tests
