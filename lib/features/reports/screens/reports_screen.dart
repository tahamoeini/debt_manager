/// Reports screen: shows overall summaries and filtered installment lists.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/core/utils/debug_utils.dart';

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
    // Refresh overdue installments before computing totals to ensure
    // totals reflect the latest statuses.
    await _db.refreshOverdueInstallments(DateTime.now());
    if (kDebugLogging)
      debugLog('ReportsScreen: refreshed overdue installments for summary');

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
    // 1) Refresh overdue statuses once up-front so subsequent queries
    //    observe the latest installment states.
    await _db.refreshOverdueInstallments(DateTime.now());
    if (kDebugLogging)
      debugLog(
        'ReportsScreen: refreshed overdue installments for filtered list',
      );

    // 2) Prepare date range filters as Jalali yyyy-MM-dd strings (or null).
    final fromStr = _from != null
        ? formatJalali(dateTimeToJalali(_from!))
        : null;
    final toStr = _to != null ? formatJalali(dateTimeToJalali(_to!)) : null;

    // 3) Load loans filtered by direction (null = all). This keeps behavior
    //    simple and avoids constructing complex SQL for now.
    final loans = await _db.getAllLoans(direction: _directionFilter);
    if (kDebugLogging)
      debugLog(
        'ReportsScreen: loans loaded count=${loans.length} direction=$_directionFilter',
      );

    // 4) Iterate loans and collect installments that fall within the date range.
    //    This is intentionally straightforward: for each loan we fetch its
    //    installments and apply the date filters in-memory.
    final List<Map<String, dynamic>> rows = [];
    for (final loan in loans) {
      // Defensive: skip loans without an id
      if (loan.id == null) continue;

      final installments = await _db.getInstallmentsByLoanId(loan.id!);
      for (final inst in installments) {
        final due = inst.dueDateJalali; // yyyy-MM-dd

        var inRange = true;
        if (fromStr != null && due.compareTo(fromStr) < 0) inRange = false;
        if (toStr != null && due.compareTo(toStr) > 0) inRange = false;
        if (!inRange) continue;

        rows.add({'installment': inst, 'loan': loan});
      }
    }

    // 5) Sort by due date to present results chronologically.
    rows.sort((a, b) {
      final aDue = (a['installment'] as Installment).dueDateJalali;
      final bDue = (b['installment'] as Installment).dueDateJalali;
      return aDue.compareTo(bDue);
    });

    if (kDebugLogging)
      debugLog('ReportsScreen: filtered installments count=${rows.length}');

    // TODO: For larger datasets consider a single SQL query joining loans and
    // installments with WHERE clauses for direction and due_date_jalali to avoid
    // loading all loans/installments into memory.

    return rows;
  }

  Future<void> _pickFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _from = picked);
  }

  Future<void> _pickTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
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
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
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
        Row(
          children: [
            Expanded(
              child: DropdownButton<LoanDirection?>(
                value: _directionFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('همه')),
                  DropdownMenuItem(
                    value: LoanDirection.borrowed,
                    child: Text('گرفته‌ام'),
                  ),
                  DropdownMenuItem(
                    value: LoanDirection.lent,
                    child: Text('داده‌ام'),
                  ),
                ],
                onChanged: (v) => setState(() => _directionFilter = v),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: _pickFrom,
              child: Text(
                _from == null
                    ? 'از تاریخ'
                    : formatJalaliForDisplay(dateTimeToJalali(_from!)),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _pickTo,
              child: Text(
                _to == null
                    ? 'تا تاریخ'
                    : formatJalaliForDisplay(dateTimeToJalali(_to!)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _loadFilteredInstallments(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              debugPrint(
                'ReportsScreen _loadFilteredInstallments error: ${snap.error}',
              );
              return const Center(child: Text('خطا در بارگذاری داده‌ها'));
            }
            final rows = snap.data ?? [];
            if (rows.isEmpty)
              return const Center(child: Text('هیچ موردی یافت نشد'));

            return Column(
              children: rows.map((r) {
                final Installment inst = r['installment'] as Installment;
                final Loan loan = r['loan'] as Loan;
                return Card(
                  child: ListTile(
                    title: Text(
                      loan.title.isNotEmpty ? loan.title : 'بدون عنوان',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '${formatJalaliForDisplay(parseJalali(inst.dueDateJalali))} · ${_statusLabel(inst.status)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    trailing: Text(
                      formatCurrency(inst.amount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}
