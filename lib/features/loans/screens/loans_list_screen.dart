import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../loans/models/loan.dart';
import '../../loans/models/installment.dart';
import '../../loans/models/counterparty.dart';

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

  Future<List<_LoanSummary>> _loadLoanSummaries(LoanDirection? direction) async {
    final loans = await _db.getAllLoans(direction: direction);
    final cps = await _db.getAllCounterparties();
    final cpMap = {for (var c in cps) c.id ?? -1: c.name};

    final List<_LoanSummary> result = [];
    for (final loan in loans) {
      if (loan.id == null) continue;
      final installments = await _db.getInstallmentsByLoanId(loan.id!);
      final unpaid = installments.where((i) => i.status != InstallmentStatus.paid).toList();
      final remainingCount = unpaid.length;
      final remainingAmount = unpaid.fold<int>(0, (s, i) => s + i.amount);
      final cpName = cpMap[loan.counterpartyId] ?? '';

      result.add(_LoanSummary(
        loan: loan,
        counterpartyName: cpName,
        remainingCount: remainingCount,
        remainingAmount: remainingAmount,
      ));
    }

    return result;
  }

  String _directionLabel(LoanDirection dir) {
    return dir == LoanDirection.borrowed ? 'گرفته‌ام' : 'داده‌ام';
  }

  String _toPersianDigits(int value) {
    final map = {'0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴', '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹'};
    final s = value.toString();
    return s.split('').map((c) => map[c] ?? c).join();
  }

  Widget _buildTabView(LoanDirection? filter) {
    return FutureBuilder<List<_LoanSummary>>(
      future: _loadLoanSummaries(filter),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('خطا: ${snapshot.error}'));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const Center(child: Text('هیچ موردی یافت نشد'));

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = items[index];
            return Card(
              child: ListTile(
                title: Text(s.loan.title),
                subtitle: Text('${s.counterpartyName} · ${_directionLabel(s.loan.direction)}'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${_toPersianDigits(s.remainingCount)} اقساط'),
                    const SizedBox(height: 4),
                    Text(_toPersianDigits(s.remainingAmount)),
                  ],
                ),
                onTap: () {
                  if (s.loan.id != null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: s.loan.id!)));
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
                tabs: const [Tab(text: 'همه'), Tab(text: 'گرفته‌ام'), Tab(text: 'داده‌ام')],
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
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => AddLoanScreen()));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

