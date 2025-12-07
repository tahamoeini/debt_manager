import 'package:flutter/material.dart';

import 'features/home/home_screen.dart';
import 'features/accounts/screens/accounts_screen.dart';
import 'features/budget/screens/budget_screen.dart';
import 'features/loans/screens/add_loan_screen.dart';
import 'features/budget/screens/add_budget_screen.dart';
import 'features/reports/screens/reports_screen.dart';
import 'features/settings/screens/settings_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;
  static const _titles = ['خانه', 'حساب‌ها', 'بودجه', 'گزارش‌ها', 'تنظیمات'];

  static final List<Widget> _pages = [
    const HomeScreen(),
    const AccountsScreen(),
    const BudgetScreen(),
    const ReportsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Allow system back when at root (no pages to pop), intercept when there are pages
    final hasPagesToPop = Navigator.of(context).canPop();
    return PopScope(
      canPop: !hasPagesToPop,
      onPopInvoked: (bool didPop) {
        // If pop was not performed (canPop was false), and there are pages, pop them
        if (!didPop && hasPagesToPop) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
        ),
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              label: 'خانه',
              tooltip: 'Home screen',
            ),
            NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              label: 'حساب‌ها',
              tooltip: 'Accounts and loans',
            ),
            NavigationDestination(
              icon: Icon(Icons.pie_chart_outline),
              label: 'بودجه',
              tooltip: 'Budget management',
            ),
            NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              label: 'گزارش‌ها',
              tooltip: 'Reports and analytics',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              label: 'تنظیمات',
              tooltip: 'Settings',
            ),
          ],
        ),
        floatingActionButton: _buildFabForIndex(_selectedIndex),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget? _buildFabForIndex(int index) {
    // Provide a primary FAB on Accounts (index 1) and Budget (index 2)
    switch (index) {
      case 1: // Accounts: add account/loan
        return FloatingActionButton.large(
          onPressed: () async {
            final res = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const AddLoanScreen()));
            if (res == true) setState(() {});
          },
          tooltip: 'Add new loan or account',
          child: const Semantics(
            label: 'Add new loan button',
            child: Icon(Icons.add_outlined),
          ),
        );
      case 2: // Budget: add budget
        return FloatingActionButton.large(
          onPressed: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            );
            if (res == true) setState(() {});
          },
          tooltip: 'Add new budget',
          child: const Semantics(
            label: 'Add new budget button',
            child: Icon(Icons.add_outlined),
          ),
        );
      default:
        return null;
    }
  }
}
