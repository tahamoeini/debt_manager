import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/ledger/models/ledger_entry.dart';

class LedgerRepository {
  final _db = DatabaseHelper.instance;

  Future<int> upsert(LedgerEntry entry) => _db.upsertLedgerEntry(entry);

  Future<int> deleteByRef(String refType, int refId) =>
      _db.deleteLedgerEntryByRef(refType, refId);

  Future<int> balance({int initialBalance = 0}) =>
      _db.getLedgerBalance(initialBalance: initialBalance);

  Future<List<LedgerEntry>> entriesBetween(String start, String end) =>
      _db.getLedgerEntriesBetween(start, end);
}

final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});
