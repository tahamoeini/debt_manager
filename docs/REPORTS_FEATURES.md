# Reports and Analytics Features

This document describes the reports and analytics features added to the Debt Manager app.

## Features Overview

### 1. Advanced Reports Screen
Access via: Reports tab → "گزارش‌های پیشرفته" button

The advanced reports screen provides comprehensive visual insights including:

#### Spending by Category Pie Chart
- Shows spending breakdown by counterparty type for a selected month
- Displays percentages for each category
- Interactive legend with color-coded categories
- Helpful for understanding where money is being spent

#### Spending Over Time Bar Chart
- Visualizes total spending per month for the last 6 or 12 months
- Helps identify spending trends over time
- Toggle between 6 and 12 month views
- Values shown in thousands of Tomans

#### Net Worth Over Time Line Chart
- Tracks net worth (assets - debts) monthly
- Shows progression of financial health
- Useful for visualizing debt reduction progress
- Emphasizes the private, offline nature of tracking

#### Monthly Insights
- Auto-generated financial insights based on spending patterns
- Compares current month to previous month
- Identifies top spending categories
- Provides actionable recommendations

### 2. Budget vs Actual Comparison
Access via: Advanced Reports → "مقایسه بودجه" button

- Compare budgeted amounts vs actual spending for each category
- Visual bar chart showing budget and actual side-by-side
- Color-coded progress indicators:
  - Green: Under 80% of budget (good)
  - Orange: 80-99% of budget (warning)
  - Red: At or over budget (alert)
- Detailed breakdown per budget category
- Period selector for different months

### 3. Debt Payoff Projection
Access via: Advanced Reports → "پیش‌بینی بدهی" button

- Visualize debt payoff timeline for borrowed loans
- Interactive loan selector
- Optional extra payment calculator
- Line chart showing balance decrease over time
- Summary statistics:
  - Current balance
  - Number of remaining installments
  - Total payments required
  - Impact of extra payments
- Helps users understand the effect of additional payments

### 4. Data Export Features

#### CSV Export
- Export installments/transactions as CSV files
- Includes all transaction details (date, amount, counterparty, status, etc.)
- Date range filtering supported
- CSV can be opened in Excel, Google Sheets, etc.
- Share via email or other apps

#### Backup & Restore
Access via: Settings screen

- **Export JSON**: View and copy full database backup as JSON
- **Share Backup**: Create and share a timestamped backup file
- **Import JSON**: Restore data from JSON backup
- Includes counterparties, loans, installments, and budgets

#### Data Reset
Access via: Settings screen → "مدیریت داده‌ها"

- Complete data wipe option
- Confirmation dialog to prevent accidental deletion
- Removes all loans, installments, and budgets
- Useful for starting fresh or clearing test data

## Implementation Details

### New Dependencies
- `fl_chart: ^0.69.0` - Chart visualization library
- `csv: ^6.0.0` - CSV export functionality
- `pdf: ^3.11.1` - PDF generation (for future enhancements)
- `path_provider: ^2.1.4` - File system access
- `share_plus: ^10.1.2` - Share functionality

### New Files
- `lib/core/export/export_service.dart` - CSV export service
- `lib/features/reports/reports_repository.dart` - Analytics computation
- `lib/features/reports/screens/advanced_reports_screen.dart` - Main reports screen
- `lib/features/budget/screens/budget_comparison_screen.dart` - Budget comparison
- `lib/features/reports/screens/debt_payoff_projection_screen.dart` - Debt projection

### Data Privacy
All data processing happens locally on the device. No data is sent to external servers. The app works completely offline, ensuring user privacy and data security.

## Usage Tips

1. **Regular Review**: Check the monthly insights regularly to stay informed about spending patterns
2. **Budget Tracking**: Use the budget comparison feature to ensure you stay within your financial goals
3. **Debt Planning**: Utilize the payoff projection to plan extra payments and reduce interest
4. **Backup Often**: Export backups regularly, especially before major changes
5. **Export Data**: Use CSV exports for detailed analysis in spreadsheet applications

## Future Enhancements

Potential future additions:
- PDF report generation with charts
- More detailed filters in reports (by counterparty, account, etc.)
- Email integration for automatic backups
- Custom date ranges for all charts
- Multi-currency support
- Scheduled report generation
