/// Loans list screen: displays loans grouped by direction and supports add/open.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'add_loan_screen.dart';
import 'loan_detail_screen.dart';

class LoansListScreen extends StatefulWidget {
  const LoansListScreen({super.key});

  @override
  State<LoansListScreen> createState() => _LoansListScreenState();
}

class _LoanSummary {
  final Loan loan;
  final String counterpartyName;
  final int remainingCount;
  final int remainingAmount;

  _LoanSummary({
    required this.loan,
    required this.counterpartyName,
    required this.remainingCount,
    required this.remainingAmount,
  });
}

class _LoansListScreenState extends State<LoansListScreen> {
  final _db = DatabaseHelper.instance;

  Future<List<_LoanSummary>> _loadLoanSummaries(
    LoanDirection? direction,
  ) async {
    await _db.refreshOverdueInstallments(DateTime.now());
    final loans = await _db.getAllLoans(direction: direction);
    final cps = await _db.getAllCounterparties();
    final cpMap = {for (var c in cps) c.id ?? -1: c.name};

    final List<_LoanSummary> result = [];

    // Extract loan IDs and fetch installments grouped by loan id in a single call
    final loanIds = loans.where((l) => l.id != null).map((l) => l.id!).toList();
    final grouped = loanIds.isNotEmpty
        ? await _db.getInstallmentsGroupedByLoanId(loanIds)
        : <int, List<Installment>>{};

    for (final loan in loans) {
      if (loan.id == null) continue;
      final installments = grouped[loan.id] ?? const <Installment>[];
      final unpaid = installments
          .where((i) => i.status != InstallmentStatus.paid)
          .toList();
      final remainingCount = unpaid.length;
      final remainingAmount = unpaid.fold<int>(0, (s, i) => s + i.amount);
      final cpName = cpMap[loan.counterpartyId] ?? '';

      result.add(
        _LoanSummary(
          loan: loan,
          counterpartyName: cpName,
          remainingCount: remainingCount,
          remainingAmount: remainingAmount,
        ),
      );
    }

    return result;
  }

  String _directionLabel(LoanDirection dir) {
    return dir == LoanDirection.borrowed ? 'گرفته‌ام' : 'داده‌ام';
  }

  Widget _buildTabView(LoanDirection? filter) {
    return FutureBuilder<List<_LoanSummary>>(
      future: _loadLoanSummaries(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          debugPrint(
            'LoansListScreen _loadLoanSummaries error: ${snapshot.error}',
          );
          return const Center(child: Text('خطا در بارگذاری داده‌ها'));
        }
        final items = snapshot.data ?? [];
        if (items.isEmpty)
          return const Center(child: Text('هیچ موردی یافت نشد'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = items[index];
            return Card(
              child: ListTile(
                title: Text(
                  s.loan.title.isNotEmpty ? s.loan.title : 'بدون عنوان',
                ),
                subtitle: Text(
                  '${s.counterpartyName.isNotEmpty ? s.counterpartyName : 'نامشخص'} · ${_directionLabel(s.loan.direction)}',
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${toPersianDigits(s.remainingCount)} اقساط'),
                    const SizedBox(height: 4),
                    Text(formatCurrency(s.remainingAmount)),
                  ],
                ),
                onTap: () async {
                  if (s.loan.id != null) {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LoanDetailScreen(loanId: s.loan.id!),
                      ),
                    );
                    setState(() {}); // Refresh after returning
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildTabView(null),
                  _buildTabView(LoanDirection.borrowed),
                  _buildTabView(LoanDirection.lent),
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
              setState(() {});
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
