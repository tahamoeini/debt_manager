import 'dart:async';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static const _dbName = 'debt_manager.db';
  static const _dbVersion = 1;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
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
}
