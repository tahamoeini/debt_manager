import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/app_shell.dart';
import 'package:debt_manager/features/loans/screens/home_screen.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/loans/screens/loan_detail_screen.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/features/budget/screens/budget_screen.dart';
import 'package:debt_manager/features/insights/smart_insights_widget.dart';
import 'package:debt_manager/features/settings/screens/settings_screen.dart';
import 'package:debt_manager/core/security/lock_screen.dart';

/// Provide a GoRouter configured for the app. The router watches the
/// [AuthNotifier] for refreshes so that redirects can react to auth changes.
final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authNotifierProvider);

  // refreshListenable watches auth changes (unlock/lock)
  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: auth,
    initialLocation: '/',
    routes: [
      ShellRoute(
        builder: (context, state, child) => const AppShell(),
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            pageBuilder: (context, state) => const MaterialPage(child: HomeScreen()),
          ),
          GoRoute(
            name: 'loans',
            path: '/loans',
            pageBuilder: (context, state) => const MaterialPage(child: LoansListScreen()),
            routes: [
              GoRoute(
                name: 'loanDetail',
                path: 'loan/:loanId',
                pageBuilder: (context, state) {
                  final idStr = state.pathParameters['loanId'] ?? '';
                  final id = int.tryParse(idStr);
                  return MaterialPage(child: LoanDetailScreen(loanId: id ?? 0));
                },
              ),
            ],
          ),
          GoRoute(
            name: 'budgets',
            path: '/budgets',
            pageBuilder: (context, state) => const MaterialPage(child: BudgetScreen()),
            routes: [
              GoRoute(
                name: 'budgetAdd',
                path: 'add',
                pageBuilder: (context, state) => const MaterialPage(child: SizedBox()),
              ),
            ],
          ),
          GoRoute(
            name: 'reports',
            path: '/reports',
            pageBuilder: (context, state) => const MaterialPage(child: ReportsScreen()),
          ),
          GoRoute(
            name: 'insights',
            path: '/insights',
            pageBuilder: (context, state) => MaterialPage(child: Scaffold(appBar: AppBar(title: const Text('پیشنهادها')), body: const SmartInsightsWidget())),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            pageBuilder: (context, state) => const MaterialPage(child: SettingsScreen()),
          ),
          // Lock screen route - shown when auth is required
          GoRoute(
            name: 'lock',
            path: '/lock',
            pageBuilder: (context, state) => const MaterialPage(fullscreenDialog: true, child: LockScreen()),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // If not unlocked and trying to access guarded routes, go to /lock
      final unlocked = auth.unlocked;
      final accessingLock = state.location == '/lock';

      // Define guarded route prefixes (any route under these should require auth)
      const guardedPrefixes = ['/loans', '/budgets', '/reports', '/insights', '/backup', '/settings', '/export'];

      final wantsGuarded = guardedPrefixes.any((p) => state.location.startsWith(p));

      if (!unlocked && wantsGuarded && !accessingLock) {
        return '/lock';
      }

      // If unlocked and currently on lock, go home
      if (unlocked && accessingLock) return '/';

      return null;
    },
    
  );
});
