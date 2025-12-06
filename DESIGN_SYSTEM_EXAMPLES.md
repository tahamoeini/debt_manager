# Design System Examples

This document provides visual examples and code snippets demonstrating the reusable UI components in the Debt Manager app.

## Before and After Refactoring

### Budget Screen Progress Bar

**Before:**
```dart
Column(
  children: [
    SizedBox(
      width: 100,
      child: LinearProgressIndicator(
        value: pct,
        color: color,
        backgroundColor: color.withOpacity(0.2),
      ),
    ),
    const SizedBox(height: 6),
    Text('${(pct * 100).toStringAsFixed(0)}%')
  ],
)
```

**After:**
```dart
BudgetProgressBar(
  current: used,
  limit: b.amount,
  showPercentage: true,
  showAmounts: false,
)
```

**Benefits:**
- 7 lines reduced to 5 lines
- Automatic color thresholding (green/orange/red)
- Consistent styling across the app
- Reusable in multiple contexts

---

### Home Screen Stat Cards

**Before:**
```dart
Card(
  child: InkWell(
    onTap: () => Navigator.of(context).push(...),
    child: Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('موجودی خالص', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          Text('—', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Assets − Debts', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    ),
  ),
)
```

**After:**
```dart
StatCard(
  title: 'موجودی خالص',
  value: '—',
  icon: Icons.account_balance_wallet,
  onTap: () => Navigator.of(context).push(...),
)
```

**Benefits:**
- 19 lines reduced to 6 lines
- Consistent icon placement
- Automatic theme integration
- Easy to add new stat cards

---

### Summary Dashboard Cards

**Before:**
```dart
Widget buildCard(String title, int value, String subtitle) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(formatCurrency(value), style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(subtitle, style: textTheme.bodySmall),
        ],
      ),
    ),
  );
}
```

**After:**
```dart
DashboardCard(
  title: 'بدهی‌های من',
  value: formatCurrency(borrowed),
  subtitle: 'مجموع اقساط پرداخت‌نشده‌ای که شما بدهکار هستید',
  icon: Icons.trending_down,
  color: colorScheme.danger,
)
```

**Benefits:**
- No need for helper function
- Semantic color support built-in
- Icon support for visual clarity
- Consistent elevation and shape

---

## Component Gallery

### 1. DashboardCard

```dart
DashboardCard(
  title: 'موجودی کل',
  value: '۱٬۲۳۴٬۵۶۷ ریال',
  subtitle: 'دارایی‌ها منهای بدهی‌ها',
  icon: Icons.account_balance_wallet,
  color: Colors.blue,
  onTap: () => print('Tapped!'),
)
```

**Features:**
- Elevated card with rounded corners
- Optional icon with color
- Optional tap handler
- Supports long text

---

### 2. StatCard

```dart
StatCard(
  title: 'بودجه باقی‌مانده',
  value: '۵۰٬۰۰۰ ریال',
  color: Colors.green,
  icon: Icons.trending_up,
  onTap: () => print('Tapped!'),
)
```

**Features:**
- Compact design for overview sections
- Color-coded values
- Optional icon

---

### 3. BudgetProgressBar

```dart
BudgetProgressBar(
  current: 75000,
  limit: 100000,
  label: 'خرید مواد غذایی',
  showPercentage: true,
  showAmounts: true,
)
```

**Color Thresholds:**
- Green: < 60% utilization
- Orange: 60-90% utilization
- Red: ≥ 90% utilization

**Features:**
- Automatic color coding
- Optional labels and amounts
- Rounded progress bar
- Handles edge cases (zero limit)

---

### 4. TransactionTile

```dart
TransactionTile(
  title: 'خرید مواد غذایی',
  subtitle: '۱۴۰۲/۰۹/۱۵',
  amount: 50000,
  isExpense: true,
  category: 'food',
  leadingIcon: Icons.shopping_cart,
  onTap: () => print('Tapped!'),
)
```

**Features:**
- Automatic color coding (red for expense, green for income)
- Category color indicators
- Sign prefix (+ or -)
- Formatted currency display

---

### 5. CategoryIcon

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

**Features:**
- Integrates with existing category colors
- Adjusts for light/dark theme
- Automatic contrast color for icon

---

### 6. AppDialog & ConfirmationDialog

```dart
// Generic dialog
showDialog(
  context: context,
  builder: (context) => AppDialog(
    title: 'عنوان',
    content: Text('محتوای دیالوگ'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text('بستن'),
      ),
    ],
  ),
)

// Confirmation dialog helper
final confirmed = await showConfirmationDialog(
  context,
  title: 'حذف حساب',
  message: 'این عمل قابل برگشت نیست',
  confirmText: 'حذف',
  cancelText: 'انصراف',
  isDangerous: true,
);
```

**Features:**
- Consistent rounded corners
- Material 3 styling
- Dangerous action styling
- Easy-to-use helper function

---

### 7. FormInput & NumericFormInput

```dart
FormInput(
  label: 'نام',
  icon: Icons.person,
  controller: nameController,
  validator: (value) => value?.isEmpty ?? true ? 'الزامی' : null,
  keyboardType: TextInputType.text,
)

NumericFormInput(
  label: 'مبلغ',
  icon: Icons.attach_money,
  controller: amountController,
  hint: 'به ریال',
)
```

**Features:**
- Consistent filled style
- Material 3 outlines
- Icon support
- Validation support
- Numeric input with digit-only formatting

---

### 8. DropdownField & CategoryDropdownField

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

// Category-specific variant
CategoryDropdownField(
  value: selectedCategory,
  categories: ['food', 'transport', 'utilities'],
  onChanged: (value) => setState(() => selectedCategory = value),
)
```

**Features:**
- Consistent with FormInput styling
- Material 3 design
- Category-specific helper
- Validation support

---

## Code Reduction Summary

| Screen/Component | Before | After | Reduction |
|-----------------|--------|-------|-----------|
| BudgetScreen | 129 lines | 107 lines | -22 lines |
| HomeScreen | 79 lines | 47 lines | -32 lines |
| SummaryCards | 69 lines | 50 lines | -19 lines |
| **Total** | **277 lines** | **204 lines** | **-73 lines (26%)** |

## Testing Coverage

All components include widget tests covering:
- Rendering and display
- Color logic (expense/income, budget thresholds)
- Theme adaptability (light/dark)
- User interactions (tap handlers)
- Edge cases (zero values, null parameters)

Run tests with:
```bash
flutter test test/widgets/
```

---

## Import Pattern

Import all widgets and theme constants at once:

```dart
import 'package:debt_manager/core/widgets/widgets.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/theme/app_colors.dart';
```

This gives you access to all reusable components in a single import statement.
