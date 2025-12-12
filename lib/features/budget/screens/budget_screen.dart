import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/widgets/budget_bar.dart';
import 'package:debt_manager/core/widgets/category_icon.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'package:debt_manager/core/providers/core_providers.dart';
import 'add_budget_screen.dart';
import 'add_budget_entry_screen.dart';
import 'package:debt_manager/features/budget/irregular_income_service.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  late Future<List<Budget>> _budgetsFuture;

  String _currentPeriod() {
    final j = dateTimeToJalali(DateTime.now());
    final y = j.year.toString().padLeft(4, '0');
    final m = j.month.toString().padLeft(2, '0');
    return '$y-$m';
  }

  @override
  void initState() {
    super.initState();
    final repo = ref.read(budgetsRepositoryProvider);
    _budgetsFuture = repo.getBudgetsByPeriod(_currentPeriod());
    _checkBudgetThresholds();
    _loadIncomeSuggestion();
  }

  int _incomeSuggestion = 0;

  Future<void> _loadIncomeSuggestion() async {
    try {
      final repo = ref.read(budgetsRepositoryProvider);
      final budgets = await repo.getBudgetsByPeriod(_currentPeriod());
      final totalBudgets = budgets.fold<int>(0, (s, b) => s + b.amount);
      final svc = IrregularIncomeService();
      final safe = await svc.suggestSafeExtra(months: 3, essentialBudget: totalBudgets, safetyFactor: 1.2);
      setState(() {
        _incomeSuggestion = safe;
      });
    } catch (_) {}
  }

  void _refresh() {
    setState(() {
      final repo = ref.read(budgetsRepositoryProvider);
      _budgetsFuture = repo.getBudgetsByPeriod(_currentPeriod());
    });
    _checkBudgetThresholds();
  }

  Future<void> _checkBudgetThresholds() async {
    try {
      final svc = ref.read(smartNotificationServiceProvider);
      await svc.checkBudgetThresholds(_currentPeriod());
    } catch (e) {
      // Silently fail - don't disrupt the UI if notifications fail
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بودجه‌ها')),
      body: SafeArea(
        child: FutureBuilder<List<Budget>>(
          future: _budgetsFuture,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return UIUtils.centeredLoading();
            }
            if (snap.hasError) {
              return UIUtils.asyncErrorWidget(snap.error);
            }
            final budgets = snap.data ?? [];
            if (budgets.isEmpty) {
              return UIUtils.animatedEmptyState(
                context: context,
                title: 'هیچ بودجه‌ای تعریف نشده',
                subtitle: 'برای شروع یک بودجه جدید اضافه کنید.',
              );
            }

            return ListView.separated(
              padding: AppConstants.paddingLarge,
              itemCount: budgets.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppConstants.spaceMedium),
              itemBuilder: (context, index) {
                final b = budgets[index];
                return Column(
                  children: [
                    Card(
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppConstants.borderRadiusSmall,
                  ),
                  child: InkWell(
                    onTap: () async {
                      // Edit
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddBudgetScreen(budget: b),
                      ));
                      _refresh();
                    },
                    child: Padding(
                      padding: AppConstants.cardPadding,
                      child: Row(
                        children: [
                          // Category icon
                          CategoryIcon(
                            category: b.category,
                            icon: Icons
                                .category, // Fallback, widget should handle category-specific icon
                            size: 40,
                          ),
                          const SizedBox(width: AppConstants.spaceMedium),
                          // Budget info and progress bar
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  b.category ?? 'عمومی',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                                const SizedBox(
                                    height: AppConstants.spaceXSmall),
                                FutureBuilder<int>(
                                  future: ref
                                      .read(budgetsRepositoryProvider)
                                      .computeUtilization(b),
                                  builder: (c, s) {
                                    final used = s.data ?? 0;
                                    return BudgetBar(
                                      current: used,
                                      limit: b.amount,
                                      showPercentage: true,
                                      showAmount: false,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
                    // Show override/entry buttons under each budget
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddBudgetEntryScreen(presetCategory: b.category, presetPeriod: b.period)));
                              if (res == true) _refresh();
                            },
                            icon: const Icon(Icons.edit_calendar),
                            label: const Text('Override / Override ماهانه'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () async {
                              final res = await Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddBudgetEntryScreen(presetCategory: b.category, )));
                              if (res == true) _refresh();
                            },
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: const Text('افزودن یک‌بار'),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_incomeSuggestion > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: FloatingActionButton.extended(
                onPressed: () {
                  UIUtils.showAppSnackBar(context, 'پیشنهاد: پرداخت اضافی ایمن ${_incomeSuggestion}');
                },
                icon: const Icon(Icons.savings),
                label: Text('پیشنهاد: ${_incomeSuggestion}'),
              ),
            ),
          FloatingActionButton.large(
            onPressed: () async {
              await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const AddBudgetScreen(),
              ));
              _refresh();
            },
            child: const Icon(Icons.add_outlined),
          ),
        ],
      ),
    );
  }
}
