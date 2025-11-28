import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

// On web we must initialize the sqflite web database factory.
// `sqflite_web` provides `databaseFactoryWeb` which must be assigned
// to the global `databaseFactory` before calling `openDatabase`.
import 'package:sqflite_web/sqflite_web.dart' as sqflite_web;

import '../../features/loans/models/counterparty.dart';
import '../../features/loans/models/loan.dart';
import '../../features/loans/models/installment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static const _dbName = 'debt_manager.db';
  static const _dbVersion = 1;

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
      throw UnsupportedError('Database initialization is not supported on web; use in-memory stores.');
    }

    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE counterparties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT
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
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(counterparty_id) REFERENCES counterparties(id)
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
        notification_id INTEGER,
        FOREIGN KEY(loan_id) REFERENCES loans(id)
      )
    ''');
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
      rows.sort((a, b) => (a['name'] as String).toLowerCase().compareTo((b['name'] as String).toLowerCase());
      return rows.map((r) => Counterparty.fromMap(r)).toList();
    }

    final db = await database;
    final rows = await db.query('counterparties', orderBy: 'name COLLATE NOCASE');
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
    return await db.insert('loans', loan.toMap());
  }

  Future<List<Loan>> getAllLoans({LoanDirection? direction}) async {
    if (_isWeb) {
      var rows = List<Map<String, dynamic>>.from(_loanStore);
      if (direction != null) {
        final dirStr = direction == LoanDirection.borrowed ? 'borrowed' : 'lent';
        rows = rows.where((r) => r['direction'] == dirStr).toList();
      }
      rows.sort((a, b) => (b['created_at'] as String).compareTo(a['created_at'] as String));
      return rows.map((r) => Loan.fromMap(r)).toList();
    }

    final db = await database;
    List<Map<String, dynamic>> rows;
    if (direction == null) {
      rows = await db.query('loans', orderBy: 'created_at DESC');
    } else {
      final dirStr = direction == LoanDirection.borrowed ? 'borrowed' : 'lent';
      rows = await db.query('loans', where: 'direction = ?', whereArgs: [dirStr], orderBy: 'created_at DESC');
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
    final rows = await db.query('loans', where: 'id = ?', whereArgs: [id], limit: 1);
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
    return await db.insert('installments', installment.toMap());
  }

  Future<List<Installment>> getInstallmentsByLoanId(int loanId) async {
    if (_isWeb) {
      final rows = _installmentStore.where((r) => r['loan_id'] == loanId).toList()
        ..sort((a, b) => (a['due_date_jalali'] as String).compareTo(b['due_date_jalali'] as String));
      return rows.map((r) => Installment.fromMap(r)).toList();
    }

    final db = await database;
    final rows = await db.query('installments', where: 'loan_id = ?', whereArgs: [loanId], orderBy: 'due_date_jalali ASC');
    return rows.map((r) => Installment.fromMap(r)).toList();
  }

  Future<int> updateInstallment(Installment installment) async {
    if (installment.id == null) throw ArgumentError('Installment.id is null');
    if (_isWeb) {
      final idx = _installmentStore.indexWhere((r) => r['id'] == installment.id);
      if (idx == -1) throw ArgumentError('Installment not found');
      _installmentStore[idx] = installment.toMap();
      return 1;
    }

    final db = await database;
    return await db.update('installments', installment.toMap(), where: 'id = ?', whereArgs: [installment.id]);
  }

  // -----------------
  // Reporting / summaries
  // -----------------

  Future<int> getTotalOutstandingBorrowed() async {
    if (_isWeb) {
      int total = 0;
      for (final i in _installmentStore) {
        final loan = _loanStore.firstWhere((l) => l['id'] == i['loan_id'], orElse: () => {});
        if (loan.isNotEmpty && loan['direction'] == 'borrowed' && i['status'] != 'paid') {
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
        final loan = _loanStore.firstWhere((l) => l['id'] == i['loan_id'], orElse: () => {});
        if (loan.isNotEmpty && loan['direction'] == 'lent' && i['status'] != 'paid') {
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

  Future<List<Installment>> getUpcomingInstallments(DateTime from, DateTime to) async {
    final db = await database;
    String fmt(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final fromStr = fmt(from);
    final toStr = fmt(to);

    if (_isWeb) {
      final rows = _installmentStore.where((r) {
        final statusOk = r['status'] == 'pending';
        final due = r['due_date_jalali'] as String;
        return statusOk && due.compareTo(fromStr) >= 0 && due.compareTo(toStr) <= 0;
      }).toList()
        ..sort((a, b) => (a['due_date_jalali'] as String).compareTo(b['due_date_jalali'] as String));

      return rows.map((r) => Installment.fromMap(r)).toList();
    }

    final rows = await db.query(
      'installments',
      where: "status = ? AND due_date_jalali BETWEEN ? AND ?",
      whereArgs: ['pending', fromStr, toStr],
      orderBy: 'due_date_jalali ASC',
    );

    return rows.map((r) => Installment.fromMap(r)).toList();
  }
}
