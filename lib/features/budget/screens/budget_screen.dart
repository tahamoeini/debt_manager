import 'package:flutter/material.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
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
            padding: const EdgeInsets.all(12),
            itemCount: budgets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final b = budgets[index];
              return Card(
                child: ListTile(
                  title: Text(b.category ?? 'عمومی'),
                  subtitle: Text('${(b.amount / 100).toStringAsFixed(2)}'),
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FutureBuilder<int>(
                        future: _repo.computeUtilization(b),
                        builder: (c, s) {
                          final used = s.data ?? 0;
                          final pct = b.amount > 0 ? (used / b.amount).clamp(0, 1) : 0.0;
                          Color color;
                          if (pct < 0.6) color = Colors.green;
                          else if (pct < 0.9) color = Colors.orange;
                          else color = Colors.red;

                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 100,
                                child: LinearProgressIndicator(
                                  value: pct,
                                  color: color,
                                  backgroundColor: color.withOpacity(0.2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text('${(pct * 100).toStringAsFixed(0)}%')
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  onTap: () async {
                    // Edit
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => AddBudgetScreen(budget: b),
                    ));
                    _refresh();
                  },
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
