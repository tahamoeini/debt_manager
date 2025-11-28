import 'package:flutter/material.dart';

import '../../../core/db/database_helper.dart';
import '../../loans/models/installment.dart';
import '../../loans/models/loan.dart';
import '../../loans/models/counterparty.dart';
import '../../../core/utils/jalali_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> _loadData() async {
    final borrowed = await _db.getTotalOutstandingBorrowed();
    final lent = await _db.getTotalOutstandingLent();
    final net = lent - borrowed;

    final today = DateTime.now();
    final to = today.add(const Duration(days: 7));

    final upcoming = await _db.getUpcomingInstallments(today, to);

    // Fetch related loans and counterparties to show titles and names.
    final loanIds = upcoming.map((i) => i.loanId).toSet();
    final Map<int, Loan> loansById = {};
    for (final id in loanIds) {
      final loan = await _db.getLoanById(id);
      if (loan != null) loansById[id] = loan;
    }

    final cps = await _db.getAllCounterparties();
    final Map<int, Counterparty> cpById = {for (var c in cps) c.id ?? -1: c};

    return {
      'borrowed': borrowed,
      'lent': lent,
      'net': net,
      'upcoming': upcoming,
      'loansById': loansById,
      'counterparties': cpById,
    };
  }

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
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const Center(child: Text('خطا هنگام بارگذاری'));
        }

        final data = snapshot.data ?? {};
        final borrowed = data['borrowed'] as int? ?? 0;
        final lent = data['lent'] as int? ?? 0;
        final net = data['net'] as int? ?? 0;
        final upcoming = data['upcoming'] as List<Installment>? ?? [];
        final loansById = data['loansById'] as Map<int, Loan>? ?? {};
        final cpById = data['counterparties'] as Map<int, Counterparty>? ?? {};

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('بدهی‌های من', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(_formatCurrency(borrowed), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('طلب‌های من', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(_formatCurrency(lent), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('وضعیت خالص', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(_formatCurrency(net), style: Theme.of(context).textTheme.headlineSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('اقساط نزدیک', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            if (upcoming.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('اقساط نزدیکی یافت نشد'),
                ),
              ),
            if (upcoming.isNotEmpty)
              ...upcoming.map((inst) {
                final loan = loansById[inst.loanId];
                final loanTitle = loan?.title ?? 'بدون عنوان';
                final cp = loan != null ? cpById[loan.counterpartyId] : null;
                final cpName = cp?.name ?? '';
                final dueJalali = parseJalali(inst.dueDateJalali);
                final dueDisplay = formatJalaliForDisplay(dueJalali);

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loanTitle, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(cpName, style: Theme.of(context).textTheme.bodySmall),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(dueDisplay),
                            Text(_formatCurrency(inst.amount)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}
