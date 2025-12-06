import 'package:flutter/material.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/core/widgets/budget_bar.dart';
import 'package:debt_manager/core/widgets/category_icon.dart';
import 'package:debt_manager/core/theme/app_constants.dart';
import 'add_budget_screen.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final _repo = BudgetsRepository();
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
    _budgetsFuture = _repo.getBudgetsByPeriod(_currentPeriod());
  }

  void _refresh() {
    setState(() {
      _budgetsFuture = _repo.getBudgetsByPeriod(_currentPeriod());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بودجه‌ها')),
      body: FutureBuilder<List<Budget>>(
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
            padding: AppConstants.paddingMedium,
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppConstants.spaceSmall),
            itemBuilder: (context, index) {
              final b = budgets[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.borderRadiusSmall,
                ),
                child: Padding(
                  padding: AppConstants.cardPadding,
                  child: InkWell(
                    onTap: () async {
                      // Edit
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddBudgetScreen(budget: b),
                      ));
                      _refresh();
                    },
                    child: Row(
                      children: [
                        // Category icon
                        CategoryIcon(
                          category: b.category,
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
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: AppConstants.spaceXSmall),
                              FutureBuilder<int>(
                                future: _repo.computeUtilization(b),
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
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const AddBudgetScreen(),
          ));
          _refresh();
        },
        child: const Icon(Icons.add_outlined),
      ),
    );
  }
}
