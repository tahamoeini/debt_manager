import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'core/debug/debug_logger.dart';

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
    return PopScope(
      canPop: !Navigator.of(context).canPop(),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(_titles[_selectedIndex]),
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Theme.of(context).brightness == Brightness.dark
                ? Brightness.dark
                : Brightness.light,
          ),
          actions: [
            if (kDebugMode)
              GestureDetector(
                onLongPress: () {
                  // Toggle overlay
                  DebugLogger.overlayEnabled.value =
                      !DebugLogger.overlayEnabled.value;
                },
                child: IconButton(
                  icon: const Icon(Icons.bug_report_outlined),
                  tooltip: 'Show debug logs (long-press to toggle overlay)',
                  onPressed: () {
                    final logger = DebugLogger();
                    final lines = logger.recent(200).join('\n');
                    showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Debug logs'),
                        content: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable: DebugLogger.overlayEnabled,
                                    builder: (context, val, _) =>
                                        SwitchListTile(
                                      title: const Text('SafeArea overlay'),
                                      value: val,
                                      onChanged: (v) =>
                                          DebugLogger.overlayEnabled.value = v,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable:
                                        DebugLogger.showBoundsEnabled,
                                    builder: (context, val, _) =>
                                        SwitchListTile(
                                      title: const Text(
                                        'Show widget bounds',
                                      ),
                                      value: val,
                                      onChanged: (v) => DebugLogger
                                          .showBoundsEnabled.value = v,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              const SizedBox(height: 8),
                              Text(lines),
                            ],
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
        body: SafeArea(child: _pages[_selectedIndex]),
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
    switch (index) {
      case 1:
        return FloatingActionButton.large(
          onPressed: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddLoanScreen()),
            );
            if (res == true) setState(() {});
          },
          tooltip: 'Add new loan or account',
          child: Semantics(
            label: 'Add new loan button',
            child: const Icon(Icons.add_outlined),
          ),
        );
      case 2:
        return FloatingActionButton.large(
          onPressed: () async {
            final res = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
            );
            if (res == true) setState(() {});
          },
          tooltip: 'Add new budget',
          child: Semantics(
            label: 'Add new budget button',
            child: const Icon(Icons.add_outlined),
          ),
        );
      default:
        return null;
    }
  }
}
