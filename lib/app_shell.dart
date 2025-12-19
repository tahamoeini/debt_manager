import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'core/debug/debug_logger.dart';

class AppShell extends StatefulWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _titles = ['خانه', 'حساب‌ها', 'بودجه', 'گزارش‌ها', 'تنظیمات'];
  static const _tabs = ['/', '/loans', '/budgets', '/reports', '/settings'];

  int _indexForLocation(String location) {
    if (location.startsWith('/loans')) return 1;
    if (location.startsWith('/budgets')) return 2;
    if (location.startsWith('/reports') || location.startsWith('/insights')) {
      return 3;
    }
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    final location = (router as dynamic).location;
    final selectedIndex = _indexForLocation(location);

    return PopScope(
      canPop: !(router as dynamic).canPop(),
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop && (router as dynamic).canPop()) {
          (router as dynamic).pop();
        }
      },
      child: Scaffold(
        extendBodyBehindAppBar: false,
        appBar: AppBar(
          title: Text(_titles[selectedIndex]),
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
        body: SafeArea(child: widget.child),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: (int index) {
            final target = _tabs[index];
            if ((router as dynamic).location != target) {
              (router as dynamic).go(target);
            }
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
        floatingActionButton: _buildFabForIndex(selectedIndex),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget? _buildFabForIndex(int index) {
    switch (index) {
      case 1:
        return FloatingActionButton.large(
          heroTag: 'app-shell-add-loan',
          onPressed: () => context.pushNamed('loanAdd'),
          tooltip: 'Add new loan or account',
          child: Semantics(
            label: 'Add new loan button',
            child: const Icon(Icons.add_outlined),
          ),
        );
      case 2:
        return FloatingActionButton.large(
          heroTag: 'app-shell-add-budget',
          onPressed: () => context.pushNamed('budgetAdd'),
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
