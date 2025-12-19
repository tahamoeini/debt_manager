import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/features/loans/loan_repository.dart';
import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

@Tags(['integration', 'db'])
@Retry(3)
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ledger integration', () {
    late DatabaseHelper dbHelper;
    late LoanRepository repo;

    setUpAll(() async {
      // Mock platform channels used by SecureStorage and SharedPreferences
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
        (MethodCall call) async => null,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/shared_preferences'),
        (MethodCall call) async {
          if (call.method == 'getAll') return <String, dynamic>{};
          return true;
        },
      );

      // Use ffi for sqlite in tests
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;

      dbHelper = DatabaseHelper.instance;
      repo = LoanRepository();

      // Retry logic for database access to handle concurrent test runs
      int retryCount = 0;
      while (retryCount < 5) {
        try {
          // Open DB to create schema
          await dbHelper.database;
          break;
        } catch (e) {
          if (e.toString().contains('database is locked') && retryCount < 4) {
            retryCount++;
            // Wait with exponential backoff
            await Future.delayed(Duration(milliseconds: 100 * retryCount));
          } else {
            rethrow;
          }
        }
      }

      // Disable notifications in tests to avoid plugin interactions
      await SettingsRepository().setNotificationsEnabled(false);
    });

    tearDownAll(() async {
      // Close database to free resources
      try {
        final db = await dbHelper.database;
        await db.close();
      } catch (_) {}
    });

    test('insertTransaction and account balance', () async {
      final txn = {
        'timestamp': DateTime.now().toIso8601String(),
        'amount': 12345,
        'direction': 'credit',
        'account_id': 1,
        'related_type': null,
        'related_id': null,
        'description': 'Test credit',
        'source': 'test',
      };

      final id = await dbHelper.insertTransaction(txn);
      expect(id, greaterThan(0));

      final rows = await dbHelper.getTransactionsByAccount(1);
      expect(rows, isNotEmpty);
      expect(await dbHelper.getAccountBalance(1), equals(12345));
    });

    test('disburseLoan creates transaction', () async {
      final cpId =
          await dbHelper.insertCounterparty(Counterparty(name: 'Lender'));
      final loan = Loan(
        counterpartyId: cpId,
        title: 'Loan A',
        direction: LoanDirection.lent,
        principalAmount: 50000,
        installmentCount: 2,
        installmentAmount: 25000,
        startDateJalali: '1400-01-01',
        createdAt: DateTime.now().toIso8601String(),
      );

      final loanId = await repo.disburseLoan(loan, accountId: 2);
      expect(loanId, greaterThan(0));

      final txns = await dbHelper.getTransactionsByRelated('loan', loanId);
      expect(txns, isNotEmpty);
      expect(await dbHelper.getAccountBalance(2), equals(50000));
    });

    test('recordInstallmentPayment updates installment and creates txn',
        () async {
      final cpId = await dbHelper.insertCounterparty(Counterparty(name: 'CP2'));
      final loan = Loan(
        counterpartyId: cpId,
        title: 'Loan B',
        direction: LoanDirection.lent,
        principalAmount: 30000,
        installmentCount: 3,
        installmentAmount: 10000,
        startDateJalali: '1400-01-01',
        createdAt: DateTime.now().toIso8601String(),
      );
      final loanId = await repo.insertLoan(loan);
      final inst = Installment(
        loanId: loanId,
        dueDateJalali: '1400-02-01',
        amount: 10000,
        status: InstallmentStatus.pending,
      );
      final instId = await repo.insertInstallment(inst);
      final fetched = (await repo.getInstallmentsByLoanId(loanId))
          .firstWhere((i) => i.id == instId);

      final txnId = await repo.recordInstallmentPayment(fetched,
          accountId: 3, paidAmount: 10000);
      expect(txnId, greaterThan(0));

      final txns =
          await dbHelper.getTransactionsByRelated('installment', fetched.id!);
      expect(txns, isNotEmpty);

      final updated = (await repo.getInstallmentsByLoanId(loanId))
          .firstWhere((i) => i.id == instId);
      expect(updated.status, equals(InstallmentStatus.paid));
      expect(updated.actualPaidAmount, equals(10000));
    });
  });
}
