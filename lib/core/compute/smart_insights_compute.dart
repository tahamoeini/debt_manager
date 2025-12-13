import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:shamsi_date/shamsi_date.dart';

// Top-level compute functions for SmartInsights. Return plain Maps so
// they can be reconstructed on the main isolate.

List<Map<String, dynamic>> computeDetectSubscriptions(
    List<Map<String, dynamic>> loans, List<Map<String, dynamic>> installments) {
  final results = <Map<String, dynamic>>[];

  // Build payments by payee/title using loans and installments
  final paymentsByPayee = <String, List<Map<String, dynamic>>>{};
  for (final loan in loans) {
    final title = (loan['title'] as String?)?.trim() ?? 'ناشناس';
    final lid = loan['id'] is int
        ? loan['id'] as int
        : int.tryParse(loan['id'].toString()) ?? -1;

    final related = installments.where((i) {
      final iid = i['loan_id'] is int
          ? i['loan_id'] as int
          : int.tryParse(i['loan_id'].toString()) ?? -1;
      return iid == lid && (i['paid_at'] as String? ?? '').isNotEmpty;
    }).toList();

    for (final p in related) {
      final amt = p['actual_paid_amount'] is int
          ? p['actual_paid_amount'] as int
          : (p['amount'] is int
              ? p['amount'] as int
              : int.tryParse(p['amount'].toString()) ?? 0);
      final paidAt = p['paid_at'] as String? ?? '';
      paymentsByPayee
          .putIfAbsent(title, () => [])
          .add({'amount': amt, 'paid_at': paidAt});
    }
  }

  // For each payee, detect recurring monthly patterns
  for (final entry in paymentsByPayee.entries) {
    final payee = entry.key;
    final list = entry.value;
    if (list.length < 3) continue;

    // Group amounts by rounded value (allow small variance)
    final groups = <int, int>{};
    for (final p in list) {
      final a = p['amount'] as int;
      // Normalize by rounding to nearest 1000 for grouping
      final key = (a / 1000).round() * 1000;
      groups[key] = (groups[key] ?? 0) + 1;
    }

    // Find groups with 3+ occurrences and roughly monthly spacing
    for (final g in groups.entries) {
      if (g.value < 3) continue;
      results.add({
        'payee': payee,
        'amount': g.key,
        'occurrences': g.value,
        'description':
            'پرداخت تکراری ${formatCurrency(g.key)} برای ${g.value} دوره (تشخیص اشتراک احتمالی)'
      });
    }
  }

  return results;
}

List<Map<String, dynamic>> computeDetectBillChanges(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> installments,
  String currentPeriod,
  String prevPeriod,
) {
  final results = <Map<String, dynamic>>[];

  for (final loan in loans) {
    final lid = loan['id'] is int
        ? loan['id'] as int
        : int.tryParse(loan['id'].toString()) ?? -1;
    final insts = installments
        .where((i) =>
            (i['loan_id'] is int
                ? i['loan_id'] as int
                : int.tryParse(i['loan_id'].toString()) ?? -1) ==
            lid)
        .toList();

    final current = insts
        .where((i) => (i['paid_at'] as String? ?? '').startsWith(currentPeriod))
        .toList();
    final prev = insts
        .where((i) => (i['paid_at'] as String? ?? '').startsWith(prevPeriod))
        .toList();

    if (current.isNotEmpty && prev.isNotEmpty) {
      final currentAmount = current.first['actual_paid_amount'] is int
          ? current.first['actual_paid_amount'] as int
          : (current.first['amount'] as int? ??
              int.tryParse(current.first['amount'].toString()) ??
              0);
      final prevAmount = prev.first['actual_paid_amount'] is int
          ? prev.first['actual_paid_amount'] as int
          : (prev.first['amount'] as int? ??
              int.tryParse(prev.first['amount'].toString()) ??
              0);
      if (prevAmount > 0) {
        final change = ((currentAmount - prevAmount) / prevAmount) * 100;
        if (change > 20) {
          results.add({
            'payee': loan['title'] as String? ?? 'ناشناس',
            'previousAmount': prevAmount,
            'currentAmount': currentAmount,
            'percentageChange': change,
            'description':
                '${loan['title']} ${change.toStringAsFixed(1)}٪ نسبت به ماه قبل افزایش یافت',
          });
        }
      }
    }
  }

  return results;
}

List<Map<String, dynamic>> computeDetectAnomalies(
  List<Map<String, dynamic>> loans,
  List<Map<String, dynamic>> installments,
  String currentPeriod,
  int monthsBack,
) {
  final results = <Map<String, dynamic>>[];

  // Compute category averages over the previous monthsBack months

  for (final inst in installments) {
    final paidAt = inst['paid_at'] as String?;
    if (paidAt == null || !paidAt.startsWith(currentPeriod.substring(0, 7))) {
      continue;
    }
  }

  // For simplicity, reuse loan titles as categories
  for (final loan in loans) {
    final lid = loan['id'] is int
        ? loan['id'] as int
        : int.tryParse(loan['id'].toString()) ?? -1;
    final title = (loan['title'] as String?)?.trim() ?? 'ناشناس';
    final insts = installments.where((i) {
      final iid = i['loan_id'] is int
          ? i['loan_id'] as int
          : int.tryParse(i['loan_id'].toString()) ?? -1;
      return iid == lid && (i['paid_at'] as String? ?? '').isNotEmpty;
    }).toList();

    // Build monthly sums for the last monthsBack months
    final now = DateTime.now();
    final nowJ = Jalali.fromDateTime(now);
    final monthlySums = <int>[];
    for (var m = 0; m < monthsBack; m++) {
      var targetYear = nowJ.year;
      var targetMonth = nowJ.month - m;
      while (targetMonth <= 0) {
        targetMonth += 12;
        targetYear -= 1;
      }
      final prefix =
          '${targetYear.toString().padLeft(4, '0')}-${targetMonth.toString().padLeft(2, '0')}';
      var sum = 0;
      for (final inst in insts) {
        final paidAt = inst['paid_at'] as String? ?? '';
        if (paidAt.startsWith(prefix)) {
          sum += inst['actual_paid_amount'] is int
              ? inst['actual_paid_amount'] as int
              : (inst['amount'] as int? ??
                  int.tryParse(inst['amount'].toString()) ??
                  0);
        }
      }
      monthlySums.add(sum);
    }

    if (monthlySums.isEmpty) continue;
    final avg = monthlySums.reduce((a, b) => a + b) / monthlySums.length;
    final current = monthlySums.first.toDouble();
    if (avg > 0 && current > avg * 3.0) {
      results.add({
        'category': title,
        'average': avg.round(),
        'current': current.round(),
        'multiplier': (current / avg),
        'description':
            'هزینه در $title بیش از 3× میانگین $monthsBack ماه گذشته است',
      });
    }
  }

  return results;
}

List<Map<String, dynamic>> billChangeEntry(Map<String, dynamic> input) {
  return computeDetectBillChanges(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['current'] as String,
    input['prev'] as String,
  );
}
