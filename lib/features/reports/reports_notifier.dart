import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/reports/reports_repository.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';

class ReportsState {
  final LoanDirection? direction;
  final DateTime? from;
  final DateTime? to;
  final Set<InstallmentStatus> statusFilter;
  final int? counterpartyFilter;
  final String? counterpartyTypeFilter;
  final List<Counterparty> counterparties;
  final Map<String, dynamic>? summary;
  final List<Map<String, dynamic>> rows;
  final bool loadingSummary;
  final bool loadingRows;

  ReportsState({
    this.direction,
    this.from,
    this.to,
    Set<InstallmentStatus>? statusFilter,
    this.counterpartyFilter,
    this.counterpartyTypeFilter,
    List<Counterparty>? counterparties,
    this.summary,
    List<Map<String, dynamic>>? rows,
    this.loadingSummary = false,
    this.loadingRows = false,
  })  : statusFilter = statusFilter ?? {InstallmentStatus.pending, InstallmentStatus.overdue},
        counterparties = counterparties ?? [],
        rows = rows ?? [];

  ReportsState copyWith({
    LoanDirection? direction,
    DateTime? from,
    DateTime? to,
    Set<InstallmentStatus>? statusFilter,
    int? counterpartyFilter,
    String? counterpartyTypeFilter,
    List<Counterparty>? counterparties,
    Map<String, dynamic>? summary,
    List<Map<String, dynamic>>? rows,
    bool? loadingSummary,
    bool? loadingRows,
  }) {
    return ReportsState(
      direction: direction ?? this.direction,
      from: from ?? this.from,
      to: to ?? this.to,
      statusFilter: statusFilter ?? this.statusFilter,
      counterpartyFilter: counterpartyFilter ?? this.counterpartyFilter,
      counterpartyTypeFilter: counterpartyTypeFilter ?? this.counterpartyTypeFilter,
      counterparties: counterparties ?? this.counterparties,
      summary: summary ?? this.summary,
      rows: rows ?? this.rows,
      loadingSummary: loadingSummary ?? this.loadingSummary,
      loadingRows: loadingRows ?? this.loadingRows,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ReportsRepository _repo;
  final Ref ref;

  ReportsNotifier(this.ref) : _repo = ReportsRepository(ref.read), super(ReportsState()) {
    _init();
  }

  Future<void> _init() async {
    await loadCounterparties();
    await refreshAll();
  }

  Future<void> loadCounterparties() async {
    try {
      final cps = await _repo.getAllCounterparties();
      state = state.copyWith(counterparties: cps);
    } catch (_) {}
  }

  Future<void> refreshAll() async {
    await Future.wait([refreshSummary(), refreshRows()]);
  }

  Future<void> refreshSummary() async {
    try {
      state = state.copyWith(loadingSummary: true);
      await _repo.refreshOverdueInstallments(DateTime.now());
      final borrowed = await _repo.getTotalOutstandingBorrowed();
      final lent = await _repo.getTotalOutstandingLent();
      final net = lent - borrowed;
      state = state.copyWith(summary: {'borrowed': borrowed, 'lent': lent, 'net': net}, loadingSummary: false);
    } catch (e) {
      state = state.copyWith(loadingSummary: false);
    }
  }

  Future<void> refreshRows() async {
    try {
      state = state.copyWith(loadingRows: true);

      await _repo.refreshOverdueInstallments(DateTime.now());

      final fromStr = state.from != null ? _formatJ(state.from!) : null;
      final toStr = state.to != null ? _formatJ(state.to!) : null;

      final loans = await _repo.getAllLoans(direction: state.direction);

      final List<Map<String, dynamic>> rows = [];
      for (final loan in loans) {
        if (loan.id == null) continue;

        if (state.counterpartyTypeFilter != null) {
          final cp = state.counterparties.firstWhere((c) => c.id == loan.counterpartyId, orElse: () => const Counterparty(id: null, name: 'نامشخص'));
          if (cp.type != state.counterpartyTypeFilter) continue;
        }

        if (state.counterpartyFilter != null && loan.counterpartyId != state.counterpartyFilter) continue;

        final installments = await _repo.getInstallmentsByLoanId(loan.id!);
        for (final inst in installments) {
          var inRange = true;
          if (fromStr != null && inst.dueDateJalali.compareTo(fromStr) < 0) inRange = false;
          if (toStr != null && inst.dueDateJalali.compareTo(toStr) > 0) inRange = false;
          if (!inRange) continue;

          if (state.statusFilter.isNotEmpty && !state.statusFilter.contains(inst.status)) continue;

          rows.add({'installment': inst, 'loan': loan});
        }
      }

      rows.sort((a, b) {
        final aDue = (a['installment'] as Installment).dueDateJalali;
        final bDue = (b['installment'] as Installment).dueDateJalali;
        return aDue.compareTo(bDue);
      });

      state = state.copyWith(rows: rows, loadingRows: false);
    } catch (e) {
      state = state.copyWith(loadingRows: false);
    }
  }

  String _formatJ(DateTime dt) {
    // Format to yyyy-MM-dd Jalali string via existing util
    // Keep simple fallback to Gregorian yyyy-MM-dd if conversion not available at compile-time
    try {
      // import would be necessary; avoid dependency here by delegating to repo where needed
      final j = dateTimeToJalali(dt);
      return formatJalali(j);
    } catch (_) {
      return dt.toIso8601String().split('T').first;
    }
  }

  // Filter setters
  void setDirection(LoanDirection? d) {
    state = state.copyWith(direction: d);
    refreshRows();
  }

  void setFrom(DateTime? d) {
    state = state.copyWith(from: d);
    refreshRows();
  }

  void setTo(DateTime? d) {
    state = state.copyWith(to: d);
    refreshRows();
  }

  void toggleStatus(InstallmentStatus s, bool enable) {
    final copy = {...state.statusFilter};
    if (enable) copy.add(s); else copy.remove(s);
    state = state.copyWith(statusFilter: copy);
    refreshRows();
  }

  void setCounterpartyFilter(int? id) {
    state = state.copyWith(counterpartyFilter: id);
    refreshRows();
  }

  void setCounterpartyTypeFilter(String? t) {
    state = state.copyWith(counterpartyTypeFilter: t);
    refreshRows();
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  return ReportsNotifier(ref);
});
