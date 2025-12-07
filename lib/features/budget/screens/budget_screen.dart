import 'package:flutter/material.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/components/components.dart';
import 'package:debt_manager/core/notifications/smart_notification_service.dart';
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
    _checkBudgetThresholds();
  }

  void _refresh() {
    setState(() {
      _budgetsFuture = _repo.getBudgetsByPeriod(_currentPeriod());
    });
    _checkBudgetThresholds();
  }

  Future<void> _checkBudgetThresholds() async {
    try {
      await SmartNotificationService.instance.checkBudgetThresholds(_currentPeriod());
    } catch (e) {
      // Silently fail - don't disrupt the UI if notifications fail
    }
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
            padding: AppSpacing.listItemPadding,
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final b = budgets[index];
              return FutureBuilder<int>(
                future: _repo.computeUtilization(b),
                builder: (c, s) {
                  final used = s.data ?? 0;
                  return BudgetProgressCard(
                    category: b.category ?? 'عمومی',
                    current: used,
                    limit: b.amount,
                    icon: CategoryIcons.getIcon(b.category),
                    onTap: () async {
                      // Edit
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => AddBudgetScreen(budget: b),
                      ));
                      _refresh();
                    },
                  );
                },
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
