# Design System Documentation

This document describes the reusable UI components and design guidelines for the Debt Manager app. Following these guidelines ensures consistency and maintainability across the application.

## Overview

The design system consists of:
- **Design Constants**: Spacing, radius, colors, and elevation values
- **Reusable Components**: Pre-built widgets for common UI patterns
- **Theme Extensions**: Custom color schemes for semantic colors
- **Guidelines**: Best practices for using the components

## Design Constants

All design constants are defined in `lib/components/design_system.dart`.

### Spacing (`AppSpacing`)

Use these constants for consistent padding and margins:

```dart
AppSpacing.xs   // 4px - extra small
AppSpacing.sm   // 8px - small
AppSpacing.md   // 12px - medium
AppSpacing.lg   // 16px - large
AppSpacing.xl   // 24px - extra large
AppSpacing.xxl  // 32px - extra extra large

// Predefined EdgeInsets
AppSpacing.pagePadding     // Standard page padding
AppSpacing.cardPadding     // Standard card padding
AppSpacing.listItemPadding // Standard list item padding
```

### Border Radius (`AppRadius`)

Use these for consistent rounded corners:

```dart
AppRadius.sm  // 8px - small
AppRadius.md  // 12px - medium (default for cards)
AppRadius.lg  // 16px - large
AppRadius.xl  // 20px - extra large

// Predefined BorderRadius
AppRadius.card    // Standard card radius
AppRadius.button  // Standard button radius
AppRadius.dialog  // Standard dialog radius
AppRadius.input   // Standard input field radius
```

### Icon Sizes (`AppIconSize`)

```dart
AppIconSize.sm  // 16px - small
AppIconSize.md  // 24px - medium
AppIconSize.lg  // 32px - large
AppIconSize.xl  // 48px - extra large
```

### Custom Colors

Access semantic colors through theme extensions:

```dart
final colorScheme = Theme.of(context).colorScheme;

colorScheme.success  // Green - for positive states
colorScheme.warning  // Orange/Amber - for warning states
colorScheme.danger   // Red - for error/destructive states
colorScheme.info     // Blue - for informational states
colorScheme.income   // Green - for income amounts
colorScheme.expense  // Red - for expense amounts
colorScheme.neutral  // Grey - for disabled/neutral states

// Or use the ThemeData extension
final theme = Theme.of(context);
theme.successColor
theme.warningColor
theme.dangerColor
```

## Reusable Components

### 1. DashboardCard / StatCard

Use for displaying statistics and metrics on dashboard screens.

**Import:**
```dart
import 'package:debt_manager/components/dashboard_card.dart';
```

**Example:**
```dart
DashboardCard(
  title: 'موجودی کل',
  value: '۱٬۲۳۴٬۵۶۷ ریال',
  subtitle: 'مانده حساب‌ها',
  icon: Icons.account_balance_wallet,
  accentColor: theme.successColor,
  onTap: () {
    // Handle tap
  },
)

// Simplified version
StatCard(
  title: 'هزینه امروز',
  value: '۱۲۰٬۰۰۰ ریال',
  color: theme.expenseColor,
)
```

**Properties:**
- `title`: The label/title of the stat
- `value`: The main value to display
- `subtitle`: Optional subtitle text
- `icon`: Optional icon
- `accentColor`: Optional color for the card accent
- `onTap`: Optional tap handler
- `isLoading`: Show loading indicator instead of value

### 2. BudgetBar

Use for displaying budget progress with color-coded thresholds.

**Import:**
```dart
import 'package:debt_manager/components/budget_bar.dart';
```

**Example:**
```dart
BudgetBar(
  current: 750000,
  limit: 1000000,
  showPercentage: true,
  showAmount: true,
)

// Or use the full card version
BudgetProgressCard(
  category: 'خرید',
  current: 750000,
  limit: 1000000,
  icon: Icons.shopping_bag_outlined,
  onTap: () {
    // Handle tap
  },
)
```

**Properties:**
- `current`: Current amount spent
- `limit`: Budget limit
- `height`: Optional custom height (default: 8)
- `showPercentage`: Whether to show percentage label
- `showAmount`: Whether to show amount label
- `lowThreshold`: Threshold for green color (default: 0.6)
- `mediumThreshold`: Threshold for orange color (default: 0.9)

**Color Logic:**
- Green: < 60% of budget
- Orange: 60-90% of budget
- Red: > 90% of budget

### 3. CategoryIcon

Use for displaying category icons with consistent styling.

**Import:**
```dart
import 'package:debt_manager/components/category_icon.dart';
```

**Example:**
```dart
// Circle style (default)
CategoryIcon(
  category: 'food',
  style: CategoryIconStyle.circle,
  size: AppIconSize.lg,
)

// Icon only
CategoryIcon(
  category: 'transport',
  style: CategoryIconStyle.icon,
)

// Dot indicator
CategoryIcon(
  category: 'shopping',
  style: CategoryIconStyle.dot,
  size: 12,
)

// Category chip with label
CategoryChip(
  category: 'خوراکی',
  showIcon: true,
  isSelected: false,
  onTap: () {
    // Handle tap
  },
)
```

**Styles:**
- `CategoryIconStyle.icon`: Icon only, no background
- `CategoryIconStyle.circle`: Icon in circular avatar
- `CategoryIconStyle.square`: Icon in rounded square
- `CategoryIconStyle.dot`: Small colored dot

### 4. TransactionTile

Use for displaying transaction items in lists.

**Import:**
```dart
import 'package:debt_manager/components/transaction_tile.dart';
```

**Example:**
```dart
TransactionTile(
  title: 'خرید سوپرمارکت',
  amount: 125000,
  type: TransactionType.expense,
  date: '۱۴۰۲/۰۹/۱۵',
  payee: 'فروشگاه',
  category: 'groceries',
  onTap: () {
    // View details
  },
  onDelete: () {
    // Delete transaction
  },
  onEdit: () {
    // Edit transaction
  },
)
```

**Properties:**
- `title`: Transaction title/description
- `amount`: Transaction amount
- `type`: `TransactionType.income` or `TransactionType.expense`
- `date`: Optional date
- `payee`: Optional payee/payer name
- `category`: Optional category
- `subtitle`: Optional custom subtitle
- `onTap`: Tap handler
- `onDelete`: Swipe to delete handler (shows confirmation)
- `onEdit`: Swipe to edit handler
- `showCategoryIcon`: Whether to show category icon (default: true)

**Features:**
- Color-coded amounts (green for income, red for expense)
- Category icon support
- Swipe actions with confirmation dialog
- Automatic subtitle generation

### 5. Form Components

Use for consistent form inputs across the app.

**Import:**
```dart
import 'package:debt_manager/components/form_inputs.dart';
```

**Example:**
```dart
// Text input
FormInput(
  label: 'عنوان',
  hint: 'عنوان تراکنش را وارد کنید',
  leadingIcon: Icons.title,
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'لطفاً عنوان را وارد کنید';
    }
    return null;
  },
  onSaved: (value) {
    // Save value
  },
)

// Dropdown
DropdownField<String>(
  label: 'دسته‌بندی',
  value: selectedCategory,
  leadingIcon: Icons.category,
  items: categories.map((cat) {
    return DropdownMenuItem(
      value: cat,
      child: Text(cat),
    );
  }).toList(),
  onChanged: (value) {
    setState(() {
      selectedCategory = value;
    });
  },
)
```

**FormInput Properties:**
- `label`: Label text
- `hint`: Hint text
- `initialValue`: Initial value
- `controller`: Text controller
- `validator`: Validator function
- `leadingIcon`: Icon at the start
- `suffixIcon`: Widget at the end
- `keyboardType`: Keyboard type
- `obscureText`: Password field
- `maxLines`: Maximum lines
- `readOnly`: Read-only mode
- And more...

### 6. Dialogs

Use for consistent dialog layouts.

**Import:**
```dart
import 'package:debt_manager/components/dialogs.dart';
```

**Example:**
```dart
// Confirmation dialog
final confirmed = await ConfirmDialog.show(
  context,
  title: 'تأیید حذف',
  message: 'آیا مطمئن هستید؟',
  isDestructive: true,
);

if (confirmed) {
  // Proceed with action
}

// Message dialog
await MessageDialog.show(
  context,
  title: 'موفقیت',
  message: 'عملیات با موفقیت انجام شد',
  icon: Icons.check_circle_outlined,
);

// Loading dialog
LoadingDialog.show(context, message: 'در حال بارگذاری...');
// ... do async work ...
LoadingDialog.dismiss(context);

// Custom dialog
showDialog(
  context: context,
  builder: (context) => AppDialog(
    title: 'عنوان',
    icon: Icons.info_outlined,
    content: YourCustomContent(),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('بستن'),
      ),
    ],
  ),
);
```

## Category Icons and Colors

Category names are automatically mapped to icons and colors. Supported categories:

- `food`, `groceries` - Restaurant/Shopping cart icon, Green
- `utilities`, `bills` - Lightbulb/Receipt icon, Blue
- `transport` - Car icon, Orange
- `shopping` - Shopping bag icon, Purple
- `rent` - Home icon, Teal
- `entertainment` - Movie icon, Deep orange
- `health` - Hospital icon, Pink
- `education` - School icon, Indigo
- `travel` - Flight icon, Cyan
- `salary` - Money icon, Green
- `investment` - Trending up icon, Blue
- `gift` - Gift icon, Purple
- `other` - Category icon, Grey

## Best Practices

### 1. Always Use Design Constants

❌ **Don't:**
```dart
padding: EdgeInsets.all(12),
borderRadius: BorderRadius.circular(8),
```

✅ **Do:**
```dart
padding: AppSpacing.cardPadding,
borderRadius: AppRadius.card,
```

### 2. Use Theme Colors

❌ **Don't:**
```dart
color: Colors.green,
color: Color(0xFF00FF00),
```

✅ **Do:**
```dart
color: Theme.of(context).colorScheme.success,
color: Theme.of(context).successColor,
```

### 3. Use Reusable Components

❌ **Don't:**
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(12),
    child: Column(
      children: [
        Text('Total'),
        Text('1,000'),
      ],
    ),
  ),
)
```

✅ **Do:**
```dart
DashboardCard(
  title: 'Total',
  value: '1,000',
)
```

### 4. Respect Accessibility

- Always reference `Theme.of(context)` for colors
- Use semantic colors (success, warning, danger) appropriately
- Test components with different text scales
- Ensure sufficient color contrast

### 5. Keep Components Adaptable

- Components should adapt to dark/light mode automatically
- Use relative sizes from theme when possible
- Test on different screen sizes

## Adding New Components

When creating new reusable components:

1. Place them in `lib/components/`
2. Use design constants from `design_system.dart`
3. Reference theme values, not hardcoded values
4. Write clear documentation
5. Add widget tests in `test/components/`
6. Update this README

## File Structure

```
lib/components/
├── design_system.dart     # Design constants and theme extensions
├── category_icons.dart    # Category icon/color mappings
├── dashboard_card.dart    # Dashboard stat cards
├── budget_bar.dart        # Budget progress bars
├── category_icon.dart     # Category icon widget
├── transaction_tile.dart  # Transaction list tile
├── form_inputs.dart       # Form input components
└── dialogs.dart           # Dialog layouts
```

## Testing

Widget tests for components are located in `test/components/`. Run tests with:

```bash
flutter test test/components/
```

## Future Enhancements

Potential additions to the design system:
- Empty state widgets
- Error state widgets
- Skeleton loading states
- Animation utilities
- Chart components
- Advanced form widgets (date pickers, etc.)
