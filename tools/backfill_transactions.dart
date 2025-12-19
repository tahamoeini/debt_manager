import 'package:debt_manager/core/db/database_helper.dart';
import 'package:flutter/foundation.dart';

/// Simple backfill utility to create transactions for historical paid
/// installments. Run with `dart run tools/backfill_transactions.dart` from
/// the package root (requires access to the app database on the host).
Future<void> main() async {
  final db = DatabaseHelper.instance;
  try {
    final loans = await db.getAllLoans();
    int created = 0;
    for (final loan in loans) {
      final insts = await db.getInstallmentsByLoanId(loan.id ?? -1);
      for (final inst in insts) {
        if (inst.paidAt == null) continue;
        final existing =
            await db.getTransactionsByRelated('installment', inst.id ?? -1);
        if (existing.isNotEmpty) continue; // already recorded

        final amt = inst.actualPaidAmount ?? inst.amount;
        final txn = {
          'timestamp': inst.paidAt,
          'amount': amt,
          'direction': 'debit',
          'account_id': null,
          'related_type': 'installment',
          'related_id': inst.id,
          'description': 'Backfilled installment payment for loan ${loan.id}',
          'source': 'backfill',
        };
        await db.insertTransaction(txn);
        created++;
      }
    }
    debugPrint('Backfill complete. Transactions created: $created');
  } catch (e) {
    debugPrint('Backfill failed: $e');
  }
}
