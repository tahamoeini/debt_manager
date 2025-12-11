import 'package:debt_manager/core/utils/format_utils.dart';

// Top-level compute functions for SmartInsights. Return plain Maps so
// they can be reconstructed on the main isolate.

List<Map<String, dynamic>> computeDetectSubscriptions(
    List<Map<String, dynamic>> loans) {
  final results = <Map<String, dynamic>>[];

  final loansByCounterparty = <int, List<Map<String, dynamic>>>{};
  for (final loan in loans) {
    final cp = loan['counterparty_id'] is int
        ? loan['counterparty_id'] as int
        : int.tryParse(loan['counterparty_id'].toString()) ?? -1;
    loansByCounterparty.putIfAbsent(cp, () => []).add(loan);
  }

  for (final entry in loansByCounterparty.entries) {
    final counterpartyLoans = entry.value;
    final amountCounts = <int, int>{};
    String commonPayee = counterpartyLoans.isNotEmpty
        ? (counterpartyLoans.first['title'] as String? ?? 'ناشناس')
        : 'ناشناس';

    for (final loan in counterpartyLoans) {
      final amount = loan['installment_amount'] is int
          ? loan['installment_amount'] as int
          : int.tryParse(loan['installment_amount'].toString()) ?? 0;
      amountCounts[amount] = (amountCounts[amount] ?? 0) + 1;
    }

    for (final amtEntry in amountCounts.entries) {
      if (amtEntry.value >= 3) {
        results.add({
          'payee': commonPayee,
          'amount': amtEntry.key,
          'occurrences': amtEntry.value,
          'description':
              'پرداخت تکراری ${formatCurrency(amtEntry.key)} برای ${amtEntry.value} ماه',
        });
      }
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

List<Map<String, dynamic>> billChangeEntry(Map<String, dynamic> input) {
  return computeDetectBillChanges(
    List<Map<String, dynamic>>.from(input['loans'] as List),
    List<Map<String, dynamic>>.from(input['insts'] as List),
    input['current'] as String,
    input['prev'] as String,
  );
}
