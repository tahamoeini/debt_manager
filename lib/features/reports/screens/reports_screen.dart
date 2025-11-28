import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../../core/utils/jalali_utils.dart';
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

  Future<List<Map<String, dynamic>>> _loadFilteredInstallments() async {
    // Load all installments within date range and optional direction
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

  // Persian digit conversion is now handled by _formatCurrency; remove unused helper.
  
  String _formatCurrency(int value) {
    final s = value.abs().toString();
    final withSep = s.replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => ',');
    final persian = withSep.split('').map((c) {
      const map = {'0': '۰', '1': '۱', '2': '۲', '3': '۳', '4': '۴', '5': '۵', '6': '۶', '7': '۷', '8': '۸', '9': '۹', ',': '٬'};
      return map[c] ?? c;
    }).join();
    return '${value < 0 ? '-' : ''}$persian ریال';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        FutureBuilder<Map<String, dynamic>>(
          future: _loadSummary(),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('خطا هنگام بارگذاری'));
            final borrowed = snap.data?['borrowed'] as int? ?? 0;
            final lent = snap.data?['lent'] as int? ?? 0;
            final net = snap.data?['net'] as int? ?? 0;

            return Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('بدهی‌های معوق (جمع)'),
                        const SizedBox(height: 8),
                        Text(_formatCurrency(borrowed), style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        const Text('مجموع مبالغی که شما بدهکار هستید')
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('طلب‌های معوق (جمع)'),
                        const SizedBox(height: 8),
                        Text(_formatCurrency(lent), style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        const Text('مجموع مبالغی که دیگران به شما بدهکار هستند')
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('وضعیت خالص'),
                        const SizedBox(height: 8),
                        Text(_formatCurrency(net), style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 4),
                        const Text('تفاوت بین طلب و بدهی')
                      ]),
                    ),
                  ),
                ),
              ],
            );
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
            if (snap.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
            if (snap.hasError) return const Center(child: Text('خطا هنگام بارگذاری'));
            final rows = snap.data ?? [];
            if (rows.isEmpty) return const Center(child: Text('هیچ موردی یافت نشد'));

            return Column(
              children: rows.map((r) {
                final Installment inst = r['installment'] as Installment;
                final Loan loan = r['loan'] as Loan;
                return Card(
                  child: ListTile(
                    title: Text(loan.title.isNotEmpty ? loan.title : 'بدون عنوان'),
                    subtitle: Text('${formatJalaliForDisplay(parseJalali(inst.dueDateJalali))} · ${inst.status.name}'),
                    trailing: Text(_formatCurrency(inst.amount)),
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
