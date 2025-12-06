import 'package:flutter/material.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/features/loans/screens/loan_detail_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final _db = DatabaseHelper.instance;
  late Future<void> _loader;

  List<Loan> _assets = [];
  List<Loan> _debts = [];
  Map<int, List<Installment>> _installmentsByLoan = {};

  @override
  void initState() {
    super.initState();
    _loader = _loadAll();
  }

  Future<void> _loadAll() async {
    await _db.refreshOverdueInstallments(DateTime.now());
    final loans = await _db.getAllLoans();
    final loanIds = loans.where((l) => l.id != null).map((l) => l.id!).toList();
    final grouped = loanIds.isNotEmpty ? await _db.getInstallmentsGroupedByLoanId(loanIds) : <int, List<Installment>>{};

    _installmentsByLoan = grouped;
    _assets = loans.where((l) => l.direction == LoanDirection.lent).toList();
    _debts = loans.where((l) => l.direction == LoanDirection.borrowed).toList();
  }

  double _paidRatio(Loan loan) {
    final insts = _installmentsByLoan[loan.id] ?? [];
    if (insts.isEmpty) return 0.0;
    final paid = insts.where((i) => i.status == InstallmentStatus.paid).length;
    return paid / insts.length;
  }

  int _remainingAmount(Loan loan) {
    final insts = _installmentsByLoan[loan.id] ?? [];
    return insts.where((i) => i.status != InstallmentStatus.paid).fold<int>(0, (s, i) => s + i.amount);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loader,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('حساب‌ها', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (_assets.isNotEmpty) ...[
              Text('دارایی‌ها', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._assets.map((l) => _buildLoanTile(context, l, isAsset: true)),
              const SizedBox(height: 12),
            ],
            if (_debts.isNotEmpty) ...[
              Text('بدهی‌ها', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ..._debts.map((l) => _buildLoanTile(context, l, isAsset: false)),
            ],
            if (_assets.isEmpty && _debts.isEmpty)
              Center(child: Text('هیچ حساب یا بدهی‌ای یافت نشد', style: Theme.of(context).textTheme.bodyMedium)),
          ],
        );
      },
    );
  }

  Widget _buildLoanTile(BuildContext context, Loan loan, {required bool isAsset}) {
    final ratio = _paidRatio(loan);
    final remaining = _remainingAmount(loan);
    final color = colorForCategory(loan.title, brightness: Theme.of(context).brightness);

    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, radius: 16),
        title: Text(loan.title.isNotEmpty ? loan.title : 'بدون عنوان', style: Theme.of(context).textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            LinearProgressIndicator(value: ratio, minHeight: 6, color: Theme.of(context).colorScheme.primary, backgroundColor: Theme.of(context).colorScheme.surfaceVariant),
            const SizedBox(height: 6),
            Text('${toPersianDigits((ratio * 100).round())}% پرداخت شده · باقی‌مانده: ${formatCurrency(remaining)}', style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        onTap: () async {
          if (loan.id != null) {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => LoanDetailScreen(loanId: loan.id!)));
            setState(() {
              _loader = _loadAll();
            });
          }
        },
      ),
    );
  }
}
