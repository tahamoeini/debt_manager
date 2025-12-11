// Database helper: CRUD and reporting utilities for counterparties, loans and installments.
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/db/installment_dao.dart';
import 'package:debt_manager/core/smart_insights/smart_insights_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static const _dbName = 'debt_manager.db';
  static const _dbVersion = 5;

  Database? _db;
  // In-memory fallback stores for web builds (sqflite is not available on web).
  final bool _isWeb = kIsWeb;
  final List<Map<String, dynamic>> _cpStore = [];
  final List<Map<String, dynamic>> _loanStore = [];
  final List<Map<String, dynamic>> _installmentStore = [];
  int _cpId = 0;
  int _loanId = 0;
  int _installmentId = 0;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (_isWeb) {
      // Web: we don't have sqflite available. The in-memory stores will be used
      // by the CRUD methods directly, so just throw to avoid accidental calls
      // to sqflite APIs from here.
      throw UnsupportedError(
        'Database initialization is not supported on web; use in-memory stores.',
      );
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE counterparties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        tag TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE loans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        counterparty_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        direction TEXT NOT NULL,
        principal_amount INTEGER NOT NULL,
        installment_count INTEGER NOT NULL,
        installment_amount INTEGER NOT NULL,
        start_date_jalali TEXT NOT NULL,
        interest_rate REAL,
        monthly_payment INTEGER,
        term_months INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(counterparty_id) REFERENCES counterparties(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE budgets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        amount INTEGER NOT NULL,
        period TEXT NOT NULL, -- stored as yyyy-MM
        rollover INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE installments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        loan_id INTEGER NOT NULL,
        due_date_jalali TEXT NOT NULL,
        amount INTEGER NOT NULL,
        status TEXT NOT NULL,
        paid_at TEXT,
        actual_paid_amount INTEGER,
        notification_id INTEGER,
        FOREIGN KEY(loan_id) REFERENCES loans(id)
      )
    ''');

    // Create indices for better query performance
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_installments_loan_id ON installments(loan_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_installments_due_date ON installments(due_date_jalali)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_installments_status ON installments(status)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_loans_counterparty ON loans(counterparty_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budgets_period ON budgets(period)',
    );
    await db.execute('''
      CREATE TABLE automation_rules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        rule_type TEXT NOT NULL,
        pattern TEXT NOT NULL,
        action TEXT NOT NULL,
        action_value TEXT NOT NULL,
        enabled INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add the actual_paid_amount column to installments. Use a try/catch
      // to tolerate existing databases where the column may already exist.
      try {
        await db.execute(
          'ALTER TABLE installments ADD COLUMN actual_paid_amount INTEGER',
        );
      } catch (_) {
        // ignore
      }
    }

    if (oldVersion < 3) {
      // Add the optional tag column to counterparties.
      try {
        await db.execute('ALTER TABLE counterparties ADD COLUMN tag TEXT');
      } catch (_) {
        // ignore if it already exists
      }
    }

    if (oldVersion < 4) {
      // Add loan financial columns and create budgets table for upgrades
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN interest_rate REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN monthly_payment INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN term_months INTEGER');
      } catch (_) {}

      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS budgets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount INTEGER NOT NULL,
            period TEXT NOT NULL,
            rollover INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }

    // Add indices for better query performance (safe to run multiple times)
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_installments_loan_id ON installments(loan_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_installments_due_date ON installments(due_date_jalali)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_installments_status ON installments(status)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_loans_counterparty ON loans(counterparty_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_budgets_period ON budgets(period)',
      );
    } catch (_) {
      // Indices creation errors are non-fatal
    }
    if (oldVersion < 5) {
      // Add automation_rules table for smart features
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS automation_rules (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            rule_type TEXT NOT NULL,
            pattern TEXT NOT NULL,
            action TEXT NOT NULL,
            action_value TEXT NOT NULL,
            enabled INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL
          )
        ''');
      } catch (_) {}
    }
  }

  // -----------------
  // Counterparty CRUD
  // -----------------

  Future<int> insertCounterparty(Counterparty counterparty) async {
    if (_isWeb) {
      _cpId++;
      final map = counterparty.toMap();
      map['id'] = _cpId;
      _cpStore.add(map);
      return _cpId;
    }

    final db = await database;
    return await db.insert('counterparties', counterparty.toMap());
  }

  Future<List<Counterparty>> getAllCounterparties() async {
    if (_isWeb) {
      final rows = List<Map<String, dynamic>>.from(_cpStore);
      rows.sort(
        (a, b) => (a['name'] as String).toLowerCase().compareTo(
          (b['name'] as String).toLowerCase(),
        ),
      );
      return rows.map((r) => Counterparty.fromMap(r)).toList();
    }

    final db = await database;
    final rows = await db.query(
      'counterparties',
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map((r) => Counterparty.fromMap(r)).toList();
  }

  // -----------------
  // Loan CRUD
  // -----------------

  Future<int> insertLoan(Loan loan) async {
    if (_isWeb) {
      _loanId++;
      final map = loan.toMap();
      map['id'] = _loanId;
      _loanStore.add(map);
      return _loanId;
    }

    final db = await database;
    final id = await db.insert('loans', loan.toMap());
    // Re-run insights and reschedule notifications when a loan is added.
    final settings = SettingsRepository();
    await settings.init();
    if (settings.smartInsightsEnabled) {
      await SmartInsightsService().runInsights(notify: false);
    }
    await NotificationService().rebuildScheduledNotifications();
    return id;
  }

  Future<List<Loan>> getAllLoans({LoanDirection? direction}) async {
    if (_isWeb) {
      var rows = List<Map<String, dynamic>>.from(_loanStore);
      if (direction != null) {
        final dirStr = direction == LoanDirection.borrowed
            ? 'borrowed'
            : 'lent';
        rows = rows.where((r) => r['direction'] == dirStr).toList();
      }
      rows.sort(
        (a, b) =>
            (b['created_at'] as String).compareTo(a['created_at'] as String),
      );
      return rows.map((r) => Loan.fromMap(r)).toList();
    }

    final db = await database;
    List<Map<String, dynamic>> rows;
    if (direction == null) {
      rows = await db.query('loans', orderBy: 'created_at DESC');
    } else {
      final dirStr = direction == LoanDirection.borrowed ? 'borrowed' : 'lent';
      rows = await db.query(
        'loans',
        where: 'direction = ?',
        whereArgs: [dirStr],
        orderBy: 'created_at DESC',
      );
    }
    return rows.map((r) => Loan.fromMap(r)).toList();
  }

  Future<Loan?> getLoanById(int id) async {
    if (_isWeb) {
      final rows = _loanStore.where((r) => r['id'] == id).toList();
      if (rows.isEmpty) return null;
      return Loan.fromMap(rows.first);
    }

    final db = await database;
    final rows = await db.query(
      'loans',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Loan.fromMap(rows.first);
  }

  // -----------------
  // Installment CRUD
  // -----------------

  Future<int> insertInstallment(Installment installment) async {
    if (_isWeb) {
      _installmentId++;
      final map = installment.toMap();
      map['id'] = _installmentId;
      _installmentStore.add(map);
      return _installmentId;
    }
    final db = await database;
    final id = await db.insert('installments', installment.toMap());
    try {
      final smartEnabled = await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) {
        await SmartInsightsService().runInsights(notify: true);
      }
    } catch (_) {}
    await NotificationService().rebuildScheduledNotifications();
    return id;
  }

  /// Delete all installments for a given loan id.
  Future<int> deleteInstallmentsByLoanId(int loanId) async {
    if (_isWeb) {
      _installmentStore.removeWhere((r) => r['loan_id'] == loanId);
      return 1;
    }

    final db = await database;
    final res = await db.delete('installments', where: 'loan_id = ?', whereArgs: [loanId]);
    try {
      final smartEnabled = await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) await SmartInsightsService().runInsights(notify: true);
    } catch (_) {}
    await NotificationService().rebuildScheduledNotifications();
    return res;
  }

  Future<List<Installment>> getInstallmentsByLoanId(int loanId) async {
    if (_isWeb) {
      final rows =
          _installmentStore.where((r) => r['loan_id'] == loanId).toList()..sort(
            (a, b) => (a['due_date_jalali'] as String).compareTo(
              b['due_date_jalali'] as String,
            ),
          );
      return rows.map((r) => Installment.fromMap(r)).toList();
    }

    final db = await database;
    return await InstallmentDao.getInstallmentsByLoanId(db, loanId);
  }

  Future<int> updateInstallment(Installment installment) async {
    if (installment.id == null) throw ArgumentError('Installment.id is null');
    if (_isWeb) {
      final idx = _installmentStore.indexWhere(
        (r) => r['id'] == installment.id,
      );
      if (idx == -1) throw ArgumentError('Installment not found');
      _installmentStore[idx] = installment.toMap();
      return 1;
    }

    final db = await database;
    final res = await db.update('installments', installment.toMap(), where: 'id = ?', whereArgs: [installment.id]);
    try {
      final smartEnabled = await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) {
        await SmartInsightsService().runInsights(notify: true);
      }
    } catch (_) {}
    await NotificationService().rebuildScheduledNotifications();
    return res;

  /// Update an existing loan row. Requires loan.id to be non-null.
  Future<int> updateLoan(Loan loan) async {
    if (loan.id == null) throw ArgumentError('Loan.id is null');
    if (_isWeb) {
      final idx = _loanStore.indexWhere((r) => r['id'] == loan.id);
      if (idx == -1) throw ArgumentError('Loan not found');
      _loanStore[idx] = loan.toMap();
      return 1;
    }

    final db = await database;
    return await db.update(
      'loans',
      loan.toMap(),
      where: 'id = ?',
      whereArgs: [loan.id],
    );
  }

  /// Delete a loan row by id.
  Future<int> deleteLoan(int loanId) async {
    if (_isWeb) {
      _loanStore.removeWhere((r) => r['id'] == loanId);
      return 1;
    }

    final db = await database;
    return await db.delete('loans', where: 'id = ?', whereArgs: [loanId]);
  }

  /// Delete a loan and all its installments. This method will cancel any
  /// scheduled notifications associated with the installments before deleting
  /// them and the loan itself.
  Future<void> deleteLoanWithInstallments(int loanId) async {
    // Fetch installments to cancel notifications
    final installments = await getInstallmentsByLoanId(loanId);

    for (final inst in installments) {
      if (inst.notificationId != null) {
        try {
          await NotificationService().cancelNotification(inst.notificationId!);
        } catch (_) {
          // ignore cancellation errors
        }
      }
    }

    // Delete installments first, then the loan
    await deleteInstallmentsByLoanId(loanId);
    await deleteLoan(loanId);
  }

  Future<Map<int, List<Installment>>> getInstallmentsGroupedByLoanId(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return {};

    if (_isWeb) {
      final filtered =
          _installmentStore
              .where((r) => loanIds.contains(r['loan_id'] as int))
              .toList()
            ..sort(
              (a, b) => (a['due_date_jalali'] as String).compareTo(
                b['due_date_jalali'] as String,
              ),
            );

      final Map<int, List<Installment>> map = {};
      for (final row in filtered) {
        final lid = row['loan_id'] as int;
        map.putIfAbsent(lid, () => []).add(Installment.fromMap(row));
      }
      return map;
    }

    final db = await database;
    return await InstallmentDao.getInstallmentsGroupedByLoanId(db, loanIds);
=======
    final res = await db.update('installments', installment.toMap(), where: 'id = ?', whereArgs: [installment.id]);
    final settings = SettingsRepository();
    await settings.init();
    if (settings.smartInsightsEnabled) {
      await SmartInsightsService().runInsights(notify: true);
    }
    await NotificationService().rebuildScheduledNotifications();
    return res;
>>>>>>> 6b5512b (Implement localization support, onboarding flow, and notification enhancements; refactor app structure for improved settings management)
  }

  // -----------------
  // Reporting / summaries
  // -----------------

  Future<int> getTotalOutstandingBorrowed() async {
    if (_isWeb) {
      int total = 0;
      for (final i in _installmentStore) {
        final loan = _loanStore.firstWhere(
          (l) => l['id'] == i['loan_id'],
          orElse: () => {},
        );
        if (loan.isNotEmpty &&
            loan['direction'] == 'borrowed' &&
            i['status'] != 'paid') {
          total += (i['amount'] as int);
        }
      }
      return total;
    }

    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(i.amount), 0) as total
      FROM installments i
      JOIN loans l ON i.loan_id = l.id
      WHERE l.direction = 'borrowed' AND i.status != 'paid'
    ''');
    final value = result.first['total'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<int> getTotalOutstandingLent() async {
    if (_isWeb) {
      int total = 0;
      for (final i in _installmentStore) {
        final loan = _loanStore.firstWhere(
          (l) => l['id'] == i['loan_id'],
          orElse: () => {},
        );
        if (loan.isNotEmpty &&
            loan['direction'] == 'lent' &&
            i['status'] != 'paid') {
          total += (i['amount'] as int);
        }
      }
      return total;
    }

    final db = await database;
    final result = await db.rawQuery('''
      SELECT COALESCE(SUM(i.amount), 0) as total
      FROM installments i
      JOIN loans l ON i.loan_id = l.id
      WHERE l.direction = 'lent' AND i.status != 'paid'
    ''');
    final value = result.first['total'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Future<List<Installment>> getUpcomingInstallments(
    DateTime from,
    DateTime to,
  ) async {
    if (_isWeb) {
      // Convert the provided Gregorian datetimes to Jalali yyyy-MM-dd strings
      final fromJ = dateTimeToJalali(from);
      final toJ = dateTimeToJalali(to);
      final fromStr = formatJalali(fromJ);
      final toStr = formatJalali(toJ);

      // Do not touch sqflite on web; use in-memory store and compare Jalali strings
      final rows =
          _installmentStore.where((r) {
            final statusOk = (r['status'] as String?) == 'pending';
            final due = r['due_date_jalali'] as String?;
            if (!statusOk || due == null) return false;
            return due.compareTo(fromStr) >= 0 && due.compareTo(toStr) <= 0;
          }).toList()
            ..sort(
              (a, b) => (a['due_date_jalali'] as String).compareTo(
                b['due_date_jalali'] as String,
              ),
            );

      return rows.map((r) => Installment.fromMap(r)).toList();
    }

    final db = await database;
    return await InstallmentDao.getUpcomingInstallments(db, from, to);
  }

  /// Refresh installments that are overdue based on a provided Gregorian `now`.
  /// Converts `now` to Jalali and updates installments whose `due_date_jalali` < today.
  Future<void> refreshOverdueInstallments(DateTime now) async {
    if (_isWeb) {
      final todayJ = dateTimeToJalali(now);
      final todayStr = formatJalali(todayJ);
      for (var i = 0; i < _installmentStore.length; i++) {
        final row = _installmentStore[i];
        final status = row['status'] as String?;
        final due = row['due_date_jalali'] as String?;
        if (status == 'pending' && due != null && due.compareTo(todayStr) < 0) {
          row['status'] = 'overdue';
          _installmentStore[i] = row;
        }
      }
      return;
    }

    final db = await database;
    await InstallmentDao.refreshOverdueInstallments(db, now);
  }
}
