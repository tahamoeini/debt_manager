library;

/// Component Examples and Demos
/// 
/// This file demonstrates how to use all the reusable components in the design system.
/// It can be used as a reference or as a visual test of all components.

// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:debt_manager/components/components.dart';

class ComponentsDemo extends StatefulWidget {
  const ComponentsDemo({super.key});

  @override
  State<ComponentsDemo> createState() => _ComponentsDemoState();
}

class _ComponentsDemoState extends State<ComponentsDemo> {
  String? selectedCategory = 'food';
  bool isSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Components Demo'),
      ),
      body: ListView(
        padding: AppSpacing.pagePadding,
        children: [
          _buildSection(
            'Dashboard Cards',
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DashboardCard(
                        title: 'Total Balance',
                        value: '۱٬۲۳۴٬۵۶۷ ریال',
                        subtitle: 'Available funds',
                        icon: Icons.account_balance_wallet,
                        accentColor: Theme.of(context).successColor,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: DashboardCard(
                        title: 'Monthly Expense',
                        value: '۵۶۷٬۸۹۰ ریال',
                        subtitle: 'This month',
                        icon: Icons.trending_up,
                        accentColor: Theme.of(context).dangerColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                StatCard(
                  title: 'Income',
                  value: '۲٬۰۰۰٬۰۰۰ ریال',
                  color: Theme.of(context).incomeColor,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(height: AppSpacing.md),
                const DashboardCard(
                  title: 'Loading Example',
                  value: 'Not shown',
                  isLoading: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Budget Bars',
            const Column(
              children: [
                Text('Low usage (< 60%):'),
                SizedBox(height: AppSpacing.sm),
                BudgetBar(
                  current: 500000,
                  limit: 1000000,
                  showPercentage: true,
                  showAmount: true,
                ),
                SizedBox(height: AppSpacing.lg),
                Text('Medium usage (60-90%):'),
                SizedBox(height: AppSpacing.sm),
                BudgetBar(
                  current: 750000,
                  limit: 1000000,
                  showPercentage: true,
                  showAmount: true,
                ),
                SizedBox(height: AppSpacing.lg),
                Text('High usage (> 90%):'),
                SizedBox(height: AppSpacing.sm),
                BudgetBar(
                  current: 950000,
                  limit: 1000000,
                  showPercentage: true,
                  showAmount: true,
                ),
                SizedBox(height: AppSpacing.lg),
                BudgetProgressCard(
                  category: 'Food & Dining',
                  current: 850000,
                  limit: 1000000,
                  icon: Icons.restaurant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Category Icons',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Icon Style:'),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    CategoryIcon(
                      category: 'food',
                      style: CategoryIconStyle.icon,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'transport',
                      style: CategoryIconStyle.icon,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'shopping',
                      style: CategoryIconStyle.icon,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Circle Style:'),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    CategoryIcon(
                      category: 'food',
                      style: CategoryIconStyle.circle,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'transport',
                      style: CategoryIconStyle.circle,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'shopping',
                      style: CategoryIconStyle.circle,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Square Style:'),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    CategoryIcon(
                      category: 'food',
                      style: CategoryIconStyle.square,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'transport',
                      style: CategoryIconStyle.square,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'shopping',
                      style: CategoryIconStyle.square,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Dot Style:'),
                const SizedBox(height: AppSpacing.sm),
                const Row(
                  children: [
                    CategoryIcon(
                      category: 'food',
                      style: CategoryIconStyle.dot,
                      size: AppIconSize.sm,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'transport',
                      style: CategoryIconStyle.dot,
                      size: AppIconSize.sm,
                    ),
                    SizedBox(width: AppSpacing.md),
                    CategoryIcon(
                      category: 'shopping',
                      style: CategoryIconStyle.dot,
                      size: AppIconSize.sm,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('Category Chips:'),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    CategoryChip(
                      category: 'Food',
                      isSelected: isSelected,
                      onTap: () => setState(() => isSelected = !isSelected),
                    ),
                    const CategoryChip(
                      category: 'Transport',
                      showIcon: true,
                    ),
                    const CategoryChip(
                      category: 'Shopping',
                      showIcon: false,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Transaction Tiles',
            Column(
              children: [
                TransactionTile(
                  title: 'Grocery Shopping',
                  amount: 125000,
                  type: TransactionType.expense,
                  date: '۱۴۰۲/۰۹/۱۵',
                  payee: 'Supermarket',
                  category: 'groceries',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Transaction tapped')),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                const TransactionTile(
                  title: 'Salary',
                  amount: 5000000,
                  type: TransactionType.income,
                  date: '۱۴۰۲/۰۹/۰۱',
                  category: 'salary',
                ),
                const SizedBox(height: AppSpacing.sm),
                const TransactionTile(
                  title: 'Taxi Ride',
                  amount: 50000,
                  type: TransactionType.expense,
                  category: 'transport',
                  showCategoryIcon: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Form Inputs',
            Column(
              children: [
                const FormInput(
                  label: 'Title',
                  hint: 'Enter title',
                  leadingIcon: Icons.title,
                ),
                const SizedBox(height: AppSpacing.md),
                const FormInput(
                  label: 'Amount',
                  hint: 'Enter amount',
                  leadingIcon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: AppSpacing.md),
                const FormInput(
                  label: 'Description',
                  hint: 'Enter description',
                  maxLines: 3,
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownField<String>(
                  label: 'Category',
                  value: selectedCategory,
                  leadingIcon: Icons.category,
                  items: ['food', 'transport', 'shopping', 'other']
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildSection(
            'Dialogs',
            Column(
              children: [
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Confirm Action',
                      message: 'Are you sure you want to proceed?',
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(confirmed ? 'Confirmed' : 'Cancelled'),
                      ),
                    );
                  },
                  child: const Text('Show Confirmation Dialog'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final confirmed = await ConfirmDialog.show(
                      context,
                      title: 'Delete Item',
                      message: 'This action cannot be undone.',
                      isDestructive: true,
                    );
                    if (!mounted) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(confirmed ? 'Deleted' : 'Cancelled'),
                      ),
                    );
                  },
                  child: const Text('Show Destructive Dialog'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () {
                    MessageDialog.show(
                      context,
                      title: 'Success',
                      message: 'Operation completed successfully!',
                      icon: Icons.check_circle,
                    );
                  },
                  child: const Text('Show Message Dialog'),
                ),
                const SizedBox(height: AppSpacing.sm),
                ElevatedButton(
                  onPressed: () async {
                    LoadingDialog.show(context, message: 'Loading...');
                    await Future.delayed(const Duration(seconds: 2));
                    if (!mounted) return;
                    LoadingDialog.dismiss(context);
                  },
                  child: const Text('Show Loading Dialog'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        child,
      ],
    );
  }
}
