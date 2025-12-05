/// Reports screen: shows overall summaries and filtered installment lists.
import 'package:flutter/material.dart';

import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/shared/summary_cards.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
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
  // Status filter: default to Pending + Overdue
  Set<InstallmentStatus> _statusFilter = {
    InstallmentStatus.pending,
    InstallmentStatus.overdue,
  };

  // Counterparty filter: null = all
  int? _counterpartyFilter;
  String? _counterpartyTypeFilter;
  List<Counterparty> _counterparties = [];

  @override
  void initState() {
    super.initState();
    _loadCounterparties();
  }

  Future<void> _loadCounterparties() async {
    try {
      final cps = await _db.getAllCounterparties();
      setState(() => _counterparties = cps);
    } catch (_) {
      // ignore
    }
  }

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

      // If type filter set, look up the loan's counterparty and skip if mismatch
      if (_counterpartyTypeFilter != null) {
        final cp = _counterparties.firstWhere(
          (c) => c.id == loan.counterpartyId,
          orElse: () => Counterparty(id: null, name: 'نامشخص'),
        );
        if (cp.type != _counterpartyTypeFilter) continue;
      }

      // If counterparty filter is set and loan's counterparty doesn't match,
      // skip this loan entirely.
      if (_counterpartyFilter != null &&
          loan.counterpartyId != _counterpartyFilter)
        continue;

      final installments = await _db.getInstallmentsByLoanId(loan.id!);
      for (final inst in installments) {
        final due = inst.dueDateJalali; // yyyy-MM-dd

        var inRange = true;
        if (fromStr != null && due.compareTo(fromStr) < 0) inRange = false;
        if (toStr != null && due.compareTo(toStr) > 0) inRange = false;
        if (!inRange) continue;

        // Respect status filter: if the installment's status is not in the
        // selected set, skip it.
        if (_statusFilter.isNotEmpty && !_statusFilter.contains(inst.status))
          continue;

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

  /// Compute a simple monthly forecast for the next 12 months starting from
  /// today. Returns a list of maps containing year, month, label, outgoing,
  /// incoming and net totals for each month.
  Future<List<Map<String, dynamic>>> _computeMonthlyForecast() async {
    await _db.refreshOverdueInstallments(DateTime.now());

    final now = DateTime.now();
    final startJ = dateTimeToJalali(now);
    final startYear = startJ.year;
    final startMonth = startJ.month;

    // Prepare buckets for next 12 months
    final Map<int, Map<String, dynamic>> buckets = {};
    for (var i = 0; i < 12; i++) {
      var y = startYear + ((startMonth - 1 + i) ~/ 12);
      var m = ((startMonth - 1 + i) % 12) + 1;
      final key = y * 100 + m;
      buckets[key] = {
        'year': y,
        'month': m,
        'label': '$y/${m.toString().padLeft(2, '0')}',
        'outgoing': 0,
        'incoming': 0,
      };
    }

    // Load loans filtered by direction and counterparty as the list view does
    final loans = await _db.getAllLoans(direction: _directionFilter);

    for (final loan in loans) {
      if (loan.id == null) continue;
      if (_counterpartyFilter != null &&
          loan.counterpartyId != _counterpartyFilter)
        continue;

      final installments = await _db.getInstallmentsByLoanId(loan.id!);
      for (final inst in installments) {
        // Apply status filter as well
        if (_statusFilter.isNotEmpty && !_statusFilter.contains(inst.status))
          continue;

        // Parse due date and compute bucket
        try {
          final jal = parseJalali(inst.dueDateJalali);
          final key = jal.year * 100 + jal.month;
          if (!buckets.containsKey(key)) continue;

          if (loan.direction == LoanDirection.borrowed) {
            // I owe others -> outgoing
            buckets[key]!['outgoing'] =
                (buckets[key]!['outgoing'] as int) + inst.amount;
          } else {
            // Others owe me -> incoming
            buckets[key]!['incoming'] =
                (buckets[key]!['incoming'] as int) + inst.amount;
          }
        } catch (_) {
          // ignore parse errors
        }
      }
    }

    // Convert buckets map to ordered list
    final result = buckets.values.toList()
      ..sort((a, b) {
        final aKey = (a['year'] as int) * 100 + (a['month'] as int);
        final bKey = (b['year'] as int) * 100 + (b['month'] as int);
        return aKey.compareTo(bKey);
      });

    // Add net field
    for (final b in result) {
      b['net'] = (b['incoming'] as int) - (b['outgoing'] as int);
    }

    return result;
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

        // Status chips and counterparty filter
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilterChip(
                    label: const Text('همه'),
                    selected:
                        _statusFilter.length == InstallmentStatus.values.length,
                    onSelected: (v) => setState(() {
                      if (v) {
                        _statusFilter = InstallmentStatus.values.toSet();
                      } else {
                        _statusFilter = {
                          InstallmentStatus.pending,
                          InstallmentStatus.overdue,
                        };
                      }
                    }),
                  ),
                  FilterChip(
                    label: const Text('در انتظار'),
                    selected: _statusFilter.contains(InstallmentStatus.pending),
                    onSelected: (v) => setState(() {
                      if (v)
                        _statusFilter.add(InstallmentStatus.pending);
                      else
                        _statusFilter.remove(InstallmentStatus.pending);
                    }),
                  ),
                  FilterChip(
                    label: const Text('عقب‌افتاده'),
                    selected: _statusFilter.contains(InstallmentStatus.overdue),
                    onSelected: (v) => setState(() {
                      if (v)
                        _statusFilter.add(InstallmentStatus.overdue);
                      else
                        _statusFilter.remove(InstallmentStatus.overdue);
                    }),
                  ),
                  FilterChip(
                    label: const Text('پرداخت شده'),
                    selected: _statusFilter.contains(InstallmentStatus.paid),
                    onSelected: (v) => setState(() {
                      if (v)
                        _statusFilter.add(InstallmentStatus.paid);
                      else
                        _statusFilter.remove(InstallmentStatus.paid);
                    }),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 200,
              child: DropdownButton<int?>(
                value: _counterpartyFilter,
                isExpanded: true,
                items: [
                  const DropdownMenuItem(value: null, child: Text('همه')),
                  ..._counterparties.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ),
                ],
                onChanged: (v) => setState(() => _counterpartyFilter = v),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 160,
              child: DropdownButton<String?>(
                value: _counterpartyTypeFilter,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: null, child: Text('همه انواع')),
                  DropdownMenuItem(value: 'person', child: Text('شخص')),
                  DropdownMenuItem(value: 'bank', child: Text('بانک')),
                  DropdownMenuItem(value: 'company', child: Text('شرکت')),
                ],
                onChanged: (v) => setState(() => _counterpartyTypeFilter = v),
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

            // Compute simple analytics for the filtered rows
            final scheduledTotal = rows.fold<int>(0, (sum, r) {
              final inst = r['installment'] as Installment;
              return sum + inst.amount;
            });

            final paidTotal = rows.fold<int>(0, (sum, r) {
              final inst = r['installment'] as Installment;
              if (inst.status == InstallmentStatus.paid) {
                return sum + (inst.actualPaidAmount ?? inst.amount);
              }
              return sum;
            });

            final remainingTotal = scheduledTotal - paidTotal;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مجموع برنامه‌ریزی‌شده'),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(scheduledTotal),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('مجموع پرداخت‌شده'),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(paidTotal),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('باقی‌مانده'),
                            const SizedBox(height: 6),
                            Text(
                              formatCurrency(remainingTotal),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ...rows.map((r) {
                  final Installment inst = r['installment'] as Installment;
                  final Loan loan = r['loan'] as Loan;
                  final cp = _counterparties.firstWhere(
                    (c) => c.id == loan.counterpartyId,
                    orElse: () => Counterparty(id: null, name: 'نامشخص'),
                  );

                  // status color mapping
                  final cs = Theme.of(context).colorScheme;
                  Color statusColor;
                  switch (inst.status) {
                    case InstallmentStatus.paid:
                      statusColor = cs.primary;
                      break;
                    case InstallmentStatus.overdue:
                      statusColor = cs.error;
                      break;
                    case InstallmentStatus.pending:
                      statusColor = cs.secondary;
                      break;
                  }

                  return Card(
                    child: ListTile(
                      title: Text(
                        formatJalaliForDisplay(parseJalali(inst.dueDateJalali)),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${loan.direction == LoanDirection.borrowed ? 'گرفته‌ام' : 'داده‌ام'} · ${cp.name}${cp.type != null ? ' · ${cp.type}' : ''}${cp.tag != null ? ' · ${cp.tag}' : ''}',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _statusLabel(inst.status),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: statusColor),
                          ),
                        ],
                      ),
                      trailing: Text(
                        formatCurrency(inst.amount),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: _computeMonthlyForecast(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());
            if (snap.hasError) {
              debugPrint(
                'ReportsScreen _computeMonthlyForecast error: ${snap.error}',
              );
              return const SizedBox.shrink();
            }

            final months = snap.data ?? [];
            if (months.isEmpty) return const SizedBox.shrink();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  'پیش‌بینی ماهیانه',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      children: months.map<Widget>((m) {
                        final label = m['label'] as String;
                        final outgoing = m['outgoing'] as int? ?? 0;
                        final incoming = m['incoming'] as int? ?? 0;
                        final net = m['net'] as int? ?? 0;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(label)),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'خروجی: ${formatCurrency(outgoing)}',
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'ورودی: ${formatCurrency(incoming)}',
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('خالص: ${formatCurrency(net)}'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
