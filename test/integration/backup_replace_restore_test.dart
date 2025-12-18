import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:debt_manager/features/settings/backup_restore_service.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/models/backup_payload.dart';

/// Ensure the test database contains the columns we expect for key tables.
Future<void> _assertDbSchema(dynamic db) async {
  Future<Set<String>> cols(String table) async {
    final rows = await db.rawQuery("PRAGMA table_info('$table')");
    final s = <String>{};
    for (final r in rows) {
      final n = r['name'] as String?;
      if (n != null) s.add(n);
    }
    return s;
  }

  final loanCols = await cols('loans');
  final requiredLoan = {
    'id',
    'counterparty_id',
    'title',
    'direction',
    'principal_amount',
    'installment_count',
    'installment_amount',
    'start_date_jalali',
    'created_at',
  };
  final missingLoan = requiredLoan.difference(loanCols);
  if (missingLoan.isNotEmpty) {
    throw Exception('Test DB missing loan columns: ${missingLoan.join(', ')}');
  }

  final instCols = await cols('installments');
  final requiredInst = {'id', 'loan_id', 'due_date_jalali', 'amount', 'status'};
  final missingInst = requiredInst.difference(instCols);
  if (missingInst.isNotEmpty) {
    throw Exception('Test DB missing installment columns: ${missingInst.join(', ')}');
  }

  final cpCols = await cols('counterparties');
  final requiredCp = {'id', 'name'};
  final missingCp = requiredCp.difference(cpCols);
  if (missingCp.isNotEmpty) {
    throw Exception('Test DB missing counterparty columns: ${missingCp.join(', ')}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Backup replace-mode integration', () {
    late DatabaseHelper dbHelper;
    late BackupRestoreService backupService;
    late String tempDirPath;

    setUpAll(() async {
      // Mock Flutter Secure Storage platform channel to avoid plugin errors in tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async {
          switch (call.method) {
            case 'read':
              return null;
            case 'write':
            case 'delete':
            case 'deleteAll':
              return null;
            default:
              return null;
          }
        },
      );

      // Mock SharedPreferences platform channel for settings access in services
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall call) async {
          switch (call.method) {
            case 'getAll':
              return <String, dynamic>{};
            case 'setString':
            case 'setBool':
            case 'setInt':
            case 'setDouble':
            case 'remove':
            case 'clear':
              return true;
            default:
              return null;
          }
        },
      );

      // Initialize ffi database factory for tests (desktop)
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      tempDirPath = (await Directory.systemTemp.createTemp('dm_test')).path;

      // Ensure any existing ffi test DB is removed so onCreate runs with latest schema
      try {
        final dbFile = File(p.join('.dart_tool', 'sqflite_common_ffi', 'databases', 'debt_manager.db'));
        if (await dbFile.exists()) await dbFile.delete(recursive: true);
      } catch (_) {}
      dbHelper = DatabaseHelper.instance;
      backupService = BackupRestoreService();

      // Open DB and assert schema matches expectations for integration tests
      final db = await dbHelper.database;
      await _assertDbSchema(db);
    });

    tearDownAll(() async {
      // Close the underlying database connection
      try {
        final db = await dbHelper.database;
        await db.close();
      } catch (_) {}
      // clean temp
    });

    test('export then replace-restore restores original counts', () async {
      // Prepare DB with sample data
      // Wipe existing tables
      final db = await dbHelper.database;
      await db.delete('installments');
      await db.delete('loans');
      await db.delete('counterparties');

      // Insert sample counterparties, loans and installments
      final cpId = await dbHelper.insertCounterparty(
        Counterparty(name: 'Test CP'),
      );

      // Insert loan directly to avoid including optional DB columns that
      // may be missing in test DB schema (e.g., compounding_frequency).
      final loanId = await db.insert('loans', {
        'counterparty_id': cpId,
        'title': 'Test Loan',
        'direction': 'lent',
        'principal_amount': 100000,
        'installment_count': 2,
        'installment_amount': 50000,
        'start_date_jalali': '1400-01-01',
        'created_at': DateTime.now().toIso8601String(),
      });
      await db.insert('installments', {
        'loan_id': loanId,
        'due_date_jalali': '1400-02-01',
        'amount': 50000,
        'status': 'pending',
      });

      // Snapshot counts
      final loans = await dbHelper.getAllLoans();
      final cps = await dbHelper.getAllCounterparties();
      final loanIds = loans.map((l) => l.id).whereType<int>().toList();
      final installmentsMap = loanIds.isNotEmpty
          ? await dbHelper.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};
      final installmentCount = installmentsMap.values.fold<int>(0, (s, v) => s + v.length);

      final beforeLoans = loans.length;
      final beforeCps = cps.length;
      final beforeInst = installmentCount;

      // final exportPath = p.join(tempDirPath, 'backup_export.zip');
      final password = 'test-password-123';

      // Export backup (encrypted)
      final backupFilePath = await backupService.exportData(backupDirectory: tempDirPath, password: password);

      // Mutate DB (delete everything)
      await db.delete('installments');
      await db.delete('loans');
      await db.delete('counterparties');

      final loansEmpty = await dbHelper.getAllLoans();
      expect(loansEmpty.length, equals(0));

      // No test-only schema tweaks: rely on fresh test DB schema created on setup.

      // Import with replace mode
      await backupService.importData(backupFilePath, mode: BackupMergeMode.replace, password: password);

      // Verify counts equal original
      final loansAfter = await dbHelper.getAllLoans();
      final cpsAfter = await dbHelper.getAllCounterparties();
      final loanIdsAfter = loansAfter.map((l) => l.id).whereType<int>().toList();
      final installmentsMapAfter = loanIdsAfter.isNotEmpty
          ? await dbHelper.getInstallmentsGroupedByLoanId(loanIdsAfter)
          : <int, List<Installment>>{};
      final afterInst = installmentsMapAfter.values.fold<int>(0, (s, v) => s + v.length);

      expect(loansAfter.length, equals(beforeLoans));
      expect(cpsAfter.length, equals(beforeCps));
      expect(afterInst, equals(beforeInst));
    });
  });

}
