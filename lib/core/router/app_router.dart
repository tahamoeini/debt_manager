import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'package:debt_manager/app_shell.dart';
import 'package:debt_manager/features/loans/screens/home_screen.dart';
import 'package:debt_manager/features/loans/screens/loans_list_screen.dart';
import 'package:debt_manager/features/loans/screens/loan_detail_screen.dart';
import 'package:debt_manager/features/loans/screens/add_loan_screen.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/reports/screens/reports_screen.dart';
import 'package:debt_manager/features/reports/screens/advanced_reports_screen.dart';
import 'package:debt_manager/features/reports/screens/debt_payoff_projection_screen.dart';
import 'package:debt_manager/features/budget/screens/budget_screen.dart';
import 'package:debt_manager/features/budget/screens/add_budget_screen.dart';
import 'package:debt_manager/features/budget/screens/add_budget_entry_screen.dart';
import 'package:debt_manager/features/budget/screens/budget_comparison_screen.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/insights/smart_insights_widget.dart';
import 'package:debt_manager/features/settings/screens/settings_screen.dart';
import 'package:debt_manager/features/help/help_screen.dart';
import 'package:debt_manager/features/categories/screens/manage_categories_screen.dart';
import 'package:debt_manager/features/automation/screens/automation_rules_screen.dart';
import 'package:debt_manager/features/data_transfer/qr_sender_screen.dart';
import 'package:debt_manager/features/data_transfer/qr_receiver_screen.dart';
import 'package:debt_manager/features/automation/screens/can_i_afford_this_screen.dart';
import 'package:debt_manager/features/achievements/screens/progress_screen.dart';
import 'package:debt_manager/core/security/lock_screen.dart';
import 'package:debt_manager/core/router/invalid_id_error_page.dart';
import 'package:debt_manager/features/transactions/add_transaction_screen.dart';

// Error messages for invalid route parameters
const String _kInvalidLoanIdMessage = 'شناسه وام نامعتبر است';
const String _kReturnToLoansButtonText = 'بازگشت به لیست وام‌ها';

// Redirect helper: returns the path to navigate to, or null to stay.
String? lockRedirect({
  required bool appLockEnabled,
  required bool unlocked,
  required String location,
}) {
  final onLock = location == '/lock';
  if (appLockEnabled && !unlocked) {
    return onLock ? null : '/lock';
  }
  if (!appLockEnabled || unlocked) {
    return onLock ? '/' : null;
  }
  return null;
}

// Provide a GoRouter configured for the app. The router watches the
// [AuthNotifier] for refreshes so that redirects can react to auth changes.
final goRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authNotifierProvider);

  // refreshListenable watches auth changes (unlock/lock)
  return GoRouter(
    debugLogDiagnostics: false,
    refreshListenable: auth,
    initialLocation: '/',
    redirect: (context, state) {
      return lockRedirect(
        appLockEnabled: auth.appLockEnabled,
        unlocked: auth.unlocked,
        location: state.uri.path,
      );
    },
    routes: [
      // Public route(s) outside of the shell
      GoRoute(
        name: 'lock',
        path: '/lock',
        pageBuilder: (context, state) =>
            const MaterialPage(fullscreenDialog: true, child: LockScreen()),
      ),
      // Private routes inside the shell
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          GoRoute(
            name: 'home',
            path: '/',
            pageBuilder: (context, state) =>
                const MaterialPage(child: HomeScreen()),
          ),
          GoRoute(
            name: 'loans',
            path: '/loans',
            pageBuilder: (context, state) =>
                const MaterialPage(child: LoansListScreen()),
            routes: [
              GoRoute(
                name: 'loanAdd',
                path: 'add',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: AddLoanScreen()),
              ),
              GoRoute(
                name: 'loanDetail',
                path: 'loan/:loanId',
                pageBuilder: (context, state) {
                  final idStr = state.pathParameters['loanId'] ?? '';
                  final id = int.tryParse(idStr);

                  // If loanId is invalid, show error UI instead of crashing
                  if (id == null) {
                    return const MaterialPage(
                      child: InvalidIdErrorPage(
                        title: 'خطا',
                        message: _kInvalidLoanIdMessage,
                        returnRoute: '/loans',
                        returnButtonText: _kReturnToLoansButtonText,
                      ),
                    );
                  }

                  return MaterialPage(child: LoanDetailScreen(loanId: id));
                },
              ),
              GoRoute(
                name: 'loanEdit',
                path: 'loan/:loanId/edit',
                pageBuilder: (context, state) {
                  final idStr = state.pathParameters['loanId'] ?? '';
                  final id = int.tryParse(idStr);

                  // If loanId is invalid, show error UI instead of crashing
                  if (id == null) {
                    return const MaterialPage(
                      child: InvalidIdErrorPage(
                        title: 'خطا',
                        message: _kInvalidLoanIdMessage,
                        returnRoute: '/loans',
                        returnButtonText: _kReturnToLoansButtonText,
                      ),
                    );
                  }

                  Loan? loan;
                  Counterparty? counterparty;
                  final extra = state.extra;
                  if (extra is Map<String, dynamic>) {
                    loan = extra['loan'] as Loan?;
                    counterparty = extra['counterparty'] as Counterparty?;
                  }
                  return MaterialPage(
                    child: AddLoanScreen(
                      existingLoan: loan,
                      existingCounterparty: counterparty,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: 'budgets',
            path: '/budgets',
            pageBuilder: (context, state) =>
                const MaterialPage(child: BudgetScreen()),
            routes: [
              GoRoute(
                name: 'budgetAdd',
                path: 'add',
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  final budget = extra is Budget ? extra : null;
                  return MaterialPage(child: AddBudgetScreen(budget: budget));
                },
              ),
              GoRoute(
                name: 'budgetEntryAdd',
                path: 'entry/add',
                pageBuilder: (context, state) {
                  final extra = state.extra;
                  String? presetCategory;
                  String? presetPeriod;
                  if (extra is Map<String, dynamic>) {
                    presetCategory = extra['presetCategory'] as String?;
                    presetPeriod = extra['presetPeriod'] as String?;
                  }
                  return MaterialPage(
                    child: AddBudgetEntryScreen(
                      presetCategory: presetCategory,
                      presetPeriod: presetPeriod,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            name: 'reports',
            path: '/reports',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ReportsScreen()),
            routes: [
              GoRoute(
                name: 'advancedReports',
                path: 'advanced',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: AdvancedReportsScreen()),
                routes: [
                  GoRoute(
                    name: 'budgetComparison',
                    path: 'budget-comparison',
                    pageBuilder: (context, state) =>
                        const MaterialPage(child: BudgetComparisonScreen()),
                  ),
                  GoRoute(
                    name: 'debtPayoffProjection',
                    path: 'debt-payoff-projection',
                    pageBuilder: (context, state) => const MaterialPage(
                      child: DebtPayoffProjectionScreen(),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            name: 'insights',
            path: '/insights',
            pageBuilder: (context, state) => MaterialPage(
              child: Scaffold(
                appBar: AppBar(title: const Text('پیشنهادها')),
                body: const SafeArea(child: SmartInsightsWidget()),
              ),
            ),
          ),
          GoRoute(
            name: 'settings',
            path: '/settings',
            pageBuilder: (context, state) =>
                const MaterialPage(child: SettingsScreen()),
            routes: [
              GoRoute(
                name: 'help',
                path: 'help',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: HelpScreen()),
              ),
              GoRoute(
                name: 'manageCategories',
                path: 'categories',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: ManageCategoriesScreen()),
              ),
              GoRoute(
                name: 'automationRules',
                path: 'automation-rules',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: AutomationRulesScreen()),
              ),
              GoRoute(
                name: 'qrSend',
                path: 'transfer/send',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: QrSenderScreen()),
              ),
              GoRoute(
                name: 'qrReceive',
                path: 'transfer/receive',
                pageBuilder: (context, state) =>
                    const MaterialPage(child: QrReceiverScreen()),
              ),
            ],
          ),
          GoRoute(
            name: 'afford',
            path: '/afford',
            pageBuilder: (context, state) =>
                const MaterialPage(child: CanIAffordThisScreen()),
          ),
          GoRoute(
            name: 'progress',
            path: '/progress',
            pageBuilder: (context, state) =>
                const MaterialPage(child: ProgressScreen()),
          ),
          GoRoute(
            name: 'transactionAdd',
            path: '/transaction/add',
            pageBuilder: (context, state) {
              final extra = state.extra;
              int? presetAccountId;
              int? presetCategoryId;
              String? presetCategoryName;
              if (extra is Map<String, dynamic>) {
                presetAccountId = extra['presetAccountId'] as int?;
                presetCategoryId = extra['presetCategoryId'] as int?;
                presetCategoryName = extra['presetCategoryName'] as String?;
              }
              return MaterialPage(
                child: AddTransactionScreen(
                  presetAccountId: presetAccountId,
                  presetCategoryId: presetCategoryId,
                  presetCategoryName: presetCategoryName,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
});
