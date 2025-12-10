// Loans list screen: displays loans grouped by direction and supports add/open.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/ui_utils.dart';
import 'package:debt_manager/components/components.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansListScreen extends ConsumerWidget {
  const LoansListScreen({super.key});

  String _directionLabel(LoanDirection dir) {
    return dir == LoanDirection.borrowed ? 'گرفته‌ام' : 'داده‌ام';
  }

  Widget _buildTabView(BuildContext context, WidgetRef ref, LoanDirection? filter) {
    final items = ref.watch(loanListProvider(filter));

    if (items.isEmpty) {
      return UIUtils.animatedEmptyState(
        context: context,
        title: 'هیچ موردی یافت نشد',
        subtitle: 'برای شروع می‌توانید یک مورد جدید اضافه کنید',
      );
    }

    return ListView.separated(
      padding: AppSpacing.pagePadding,
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final s = items[index];
        return Card(
          child: ListTile(
            contentPadding: AppSpacing.listItemPadding,
            leading: CategoryIcon(
              category: s.counterpartyTag,
              size: AppIconSize.sm,
            ),
            title: Text(
              s.loan.title.isNotEmpty ? s.loan.title : 'بدون عنوان',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            subtitle: Text(
              '${s.counterpartyName.isNotEmpty ? s.counterpartyName : 'نامشخص'}${s.counterpartyType != null ? ' · ${s.counterpartyType}' : ''}${s.counterpartyTag != null ? ' · ${s.counterpartyTag}' : ''} · ${_directionLabel(s.loan.direction)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${toPersianDigits(s.remainingCount)} اقساط',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  formatCurrency(s.remainingAmount),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            onTap: () async {
              if (s.loan.id != null) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => LoanDetailScreen(loanId: s.loan.id!),
                  ),
                );
                // Refresh the specific filtered list after returning
                await ref.read(loanListProvider(filter).notifier).refresh();
              }
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: Column(
          children: [
            Material(
              color: Colors.transparent,
              child: TabBar(
                labelColor: Theme.of(context).colorScheme.onSurface,
                tabs: const [
                  Tab(text: 'همه'),
                  Tab(text: 'گرفته‌ام'),
                  Tab(text: 'داده‌ام'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTabView(context, ref, null),
                  _buildTabView(context, ref, LoanDirection.borrowed),
                  _buildTabView(context, ref, LoanDirection.lent),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.of(context).push<bool>(
              MaterialPageRoute(builder: (_) => const AddLoanScreen()),
            );
            if (result == true) {
              // Refresh all three lists so UI updates without setState
              await ref.read(loanListProvider(null).notifier).refresh();
              await ref.read(loanListProvider(LoanDirection.borrowed).notifier).refresh();
              await ref.read(loanListProvider(LoanDirection.lent).notifier).refresh();
            }
          },
          child: const Icon(Icons.add_outlined),
        ),
      ),
    );
  }
}
