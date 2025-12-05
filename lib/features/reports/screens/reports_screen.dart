import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../../core/utils/format_utils.dart';
import '../../../core/utils/jalali_utils.dart';
import '../../shared/summary_cards.dart';
import '../../loans/models/installment.dart';
import '../../loans/models/loan.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _db = DatabaseHelper.instance;

  LoanDirection? _directionFilter; // null = all
  DateTime? _from;
  DateTime? _to;

  Future<Map<String, dynamic>> _loadSummary() async {
    final borrowed = await _db.getTotalOutstandingBorrowed();
    final lent = await _db.getTotalOutstandingLent();
    final net = lent - borrowed;
    return {'borrowed': borrowed, 'lent': lent, 'net': net};
  }

  String _statusLabel(InstallmentStatus s) {
    switch (s) {
      case InstallmentStatus.paid:
        return 'پرداخت شده';
      case InstallmentStatus.overdue:
        return 'عقب‌افتاده';
      case InstallmentStatus.pending:
        return 'در انتظار';
    }
  }

  Future<List<Map<String, dynamic>>> _loadFilteredInstallments() async {
    // Refresh overdue installments, then load all installments within date range and optional direction
    await _db.refreshOverdueInstallments(DateTime.now());
    final fromStr = _from != null ? formatJalali(dateTimeToJalali(_from!)) : null;
    final toStr = _to != null ? formatJalali(dateTimeToJalali(_to!)) : null;

    // Get all loans (filtered by direction if provided) and build map
    final loans = await _db.getAllLoans(direction: _directionFilter);

    // For simplicity, query installments by iterating loans and fetching installments
    final List<Map<String, dynamic>> rows = [];
    for (final loan in loans) {
      final installments = await _db.getInstallmentsByLoanId(loan.id!);
      for (final inst in installments) {
        final due = inst.dueDateJalali; // yyyy-MM-dd
        var inRange = true;
        if (fromStr != null && due.compareTo(fromStr) < 0) inRange = false;
        if (toStr != null && due.compareTo(toStr) > 0) inRange = false;
        if (!inRange) continue;

        rows.add({
          'installment': inst,
          'loan': loan,
        });
      }
    }

    // Sort by due date
    rows.sort((a, b) {
      final aDue = (a['installment'] as Installment).dueDateJalali;
      final bDue = (b['installment'] as Installment).dueDateJalali;
      return aDue.compareTo(bDue);
    });

    return rows;
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5));
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(context: context, initialDate: now, firstDate: DateTime(now.year - 5), lastDate: DateTime(now.year + 5));
    if (picked != null) setState(() => _to = picked);
  }



  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _loadSummary(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              debugPrint('ReportsScreen _loadSummary error: ${snap.error}');
              return const Center(child: Text('خطا در بارگذاری داده‌ها'));
            }
            final borrowed = snap.data?['borrowed'] as int? ?? 0;
            final lent = snap.data?['lent'] as int? ?? 0;
            final net = snap.data?['net'] as int? ?? 0;

            return SummaryCards(borrowed: borrowed, lent: lent, net: net);
          },
        ),

        const SizedBox(height: 20),
        const Text('فیلترها', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: DropdownButton<LoanDirection?>(
              value: _directionFilter,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: null, child: Text('همه')),
                DropdownMenuItem(value: LoanDirection.borrowed, child: Text('گرفته‌ام')),
                DropdownMenuItem(value: LoanDirection.lent, child: Text('داده‌ام')),
              ],
              onChanged: (v) => setState(() => _directionFilter = v),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(onPressed: _pickFrom, child: Text(_from == null ? 'از تاریخ' : formatJalaliForDisplay(dateTimeToJalali(_from!)))),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _pickTo, child: Text(_to == null ? 'تا تاریخ' : formatJalaliForDisplay(dateTimeToJalali(_to!)))),
        ]),

        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadFilteredInstallments(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              debugPrint('ReportsScreen _loadFilteredInstallments error: ${snap.error}');
              return const Center(child: Text('خطا در بارگذاری داده‌ها'));
            }
            final rows = snap.data ?? [];
            if (rows.isEmpty) return const Center(child: Text('هیچ موردی یافت نشد'));

            return Column(
              children: rows.map((r) {
                final Installment inst = r['installment'] as Installment;
                final Loan loan = r['loan'] as Loan;
                return Card(
                  child: ListTile(
                    title: Text(loan.title.isNotEmpty ? loan.title : 'بدون عنوان', style: Theme.of(context).textTheme.titleMedium),
                    subtitle: Text('${formatJalaliForDisplay(parseJalali(inst.dueDateJalali))} · ${_statusLabel(inst.status)}', style: Theme.of(context).textTheme.bodyMedium),
                    trailing: Text(formatCurrency(inst.amount), style: Theme.of(context).textTheme.bodyMedium),
                  ),
                );
              }).toList(),
            );
          },
        )
      ],
    );
  }
}
