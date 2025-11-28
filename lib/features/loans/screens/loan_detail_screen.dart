import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../loans/models/loan.dart';
import '../../loans/models/counterparty.dart';
import '../../loans/models/installment.dart';

class LoanDetailScreen extends StatefulWidget {
  const LoanDetailScreen({Key? key, required this.loanId}) : super(key: key);

  final int loanId;

  @override
  State<LoanDetailScreen> createState() => _LoanDetailScreenState();
}

class _LoanDetailScreenState extends State<LoanDetailScreen> {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> _loadAll() async {
    final loan = await _db.getLoanById(widget.loanId);
    if (loan == null) throw Exception('Loan not found');

    final cps = await _db.getAllCounterparties();
    final cp = cps.firstWhere((c) => c.id == loan.counterpartyId, orElse: () => Counterparty(id: null, name: '—'));

    final installments = await _db.getInstallmentsByLoanId(widget.loanId);

    return {
      'loan': loan,
      'counterparty': cp,
      'installments': installments,
    };
  }

  String _directionText(LoanDirection dir) {
    return dir == LoanDirection.borrowed ? 'من بدهکارم' : 'من طلبکارم';
  }

  String _statusText(InstallmentStatus s) {
    switch (s) {
      case InstallmentStatus.paid:
        return 'پرداخت شده';
      case InstallmentStatus.overdue:
        return 'عقب‌افتاده';
      case InstallmentStatus.pending:
      default:
        return 'در انتظار';
    }
  }

  String _toPersianDigits(int value) {
    final map = {'0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴', '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹'};
    final s = value.toString();
    return s.split('').map((c) => map[c] ?? c).join();
  }

  Future<void> _markPaid(Installment inst) async {
    if (inst.id == null) return;

    final updated = inst.copyWith(status: InstallmentStatus.paid, paidAt: DateTime.now().toIso8601String());
    await _db.updateInstallment(updated);

    if (inst.notificationId != null) {
      await NotificationService().cancelNotification(inst.notificationId!);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) return Scaffold(body: const Center(child: CircularProgressIndicator()));
        if (snapshot.hasError) return Scaffold(body: Center(child: Text('خطا: ${snapshot.error}')));

        final loan = snapshot.data!['loan'] as Loan;
        final cp = snapshot.data!['counterparty'] as Counterparty;
        final installments = snapshot.data!['installments'] as List<Installment>;

        return Scaffold(
          appBar: AppBar(title: Text(loan.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.title, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text(cp.name, style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 8),
                      Text(_directionText(loan.direction)),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('مبلغ اصلی: ${_toPersianDigits(loan.principalAmount)}'),
                          Text('تعداد اقساط: ${_toPersianDigits(loan.installmentCount)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('مبلغ قسط: ${_toPersianDigits(loan.installmentAmount)}'),
                      const SizedBox(height: 8),
                      Text('شروع: ${formatJalaliForDisplay(parseJalali(loan.startDateJalali))}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('اقساط', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ...installments.map((inst) {
                final due = formatJalaliForDisplay(parseJalali(inst.dueDateJalali));
                final paid = inst.status == InstallmentStatus.paid;
                return Card(
                  child: ListTile(
                    title: Text(due),
                    subtitle: Text(_statusText(inst.status) + (paid && inst.paidAt != null ? ' • ${inst.paidAt}' : '')),
                    trailing: Text(_toPersianDigits(inst.amount)),
                    leading: IconButton(
                      icon: Icon(paid ? Icons.check_circle : Icons.radio_button_unchecked, color: paid ? Colors.green : null),
                      onPressed: paid
                          ? null
                          : () async {
                              await _markPaid(inst);
                            },
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }
}
