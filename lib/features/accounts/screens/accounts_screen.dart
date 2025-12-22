import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/features/loans/loan_list_notifier.dart';

class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(loanListProvider(LoanDirection.lent));
    final debts = ref.watch(loanListProvider(LoanDirection.borrowed));

    Widget buildList(List<LoanSummary> items) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        children: items
            .map((s) => _buildLoanTile(context, s, ref: ref))
            .toList(growable: false),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('حساب‌ها', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (assets.isNotEmpty) ...[
          Text('دارایی‌ها', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          buildList(assets),
          const SizedBox(height: 12),
        ],
        if (debts.isNotEmpty) ...[
          Text('بدهی‌ها', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          buildList(debts),
        ],
        if (assets.isEmpty && debts.isEmpty)
          Center(
            child: Text(
              'هیچ حساب یا بدهی‌ای یافت نشد',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
      ],
    );
  }

  Widget _buildLoanTile(
    BuildContext context,
    LoanSummary s, {
    required WidgetRef ref,
  }) {
    final loan = s.loan;
    final total = loan.installmentCount <= 0 ? 1 : loan.installmentCount;
    final ratio = total == 0 ? 0.0 : (1 - (s.remainingCount / total));
    final remaining = s.remainingAmount;
    final color = colorForCategory(
      loan.title,
      brightness: Theme.of(context).brightness,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: CircleAvatar(backgroundColor: color, radius: 20),
        title: Text(
          loan.title.isNotEmpty ? loan.title : 'بدون عنوان',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              '${toPersianDigits((ratio * 100).round())}% پرداخت شده · باقی‌مانده: ${formatCurrency(remaining)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () async {
          if (loan.id != null) {
            // Use GoRouter named route to navigate to loan detail
            final router = GoRouter.of(context);
            router.pushNamed(
              'loanDetail',
              pathParameters: {'loanId': loan.id!.toString()},
            );
          }
        },
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart_outlined),
          tooltip: 'افزودن تراکنش مرتبط با این وام',
          onPressed: () {
            // Pre-fill category with loan title to help user
            context.pushNamed('transactionAdd', extra: {
              'presetAccountId': null,
              'presetCategoryName': loan.title,
            });
          },
        ),
      ),
    );
  }
}
