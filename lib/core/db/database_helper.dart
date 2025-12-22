// Database helper: CRUD and reporting utilities for counterparties, loans and installments.
import 'dart:async';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart' as plain;
import 'package:sqflite_sqlcipher/sqflite.dart' as cipher;

import 'package:debt_manager/features/loans/models/counterparty.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/ledger/models/ledger_entry.dart';
import 'package:debt_manager/features/finance/models/finance_models.dart';
import 'package:debt_manager/core/notifications/notification_service.dart';
import 'package:debt_manager/core/db/installment_dao.dart';
import 'package:debt_manager/core/smart_insights/smart_insights_service.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/features/automation/automation_rules_repository.dart';
import 'package:debt_manager/core/security/secure_storage_service.dart';
import 'package:debt_manager/core/security/security_service.dart';
// crypto/dart:convert not required here

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  DatabaseHelper._internal();
  factory DatabaseHelper() => instance;

  static const _dbName = 'debt_manager.db';
  static const _dbVersion = 10; // Bumped for ledger.category_id migration
  // bump DB version to add transactions table and paid_at_jalali/ledger and v9/v10 work
  static const _newDbVersion = 10;

  plain.Database? _db;
  // In-memory fallback stores for web builds (sqflite is not available on web).
  final bool _isWeb = kIsWeb;
  final List<Map<String, dynamic>> _cpStore = [];
  final List<Map<String, dynamic>> _loanStore = [];
  final List<Map<String, dynamic>> _installmentStore = [];
  final List<Map<String, dynamic>> _transactionStore = [];
  final List<Map<String, dynamic>> _ledgerStore = [];
  int _cpId = 0;
  int _loanId = 0;
  int _installmentId = 0;
  int _transactionId = 0;
  int _ledgerId = 0;

  Future<plain.Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<plain.Database> _initDatabase() async {
    if (_isWeb) {
      // Web: we don't have sqflite available. The in-memory stores will be used
      // by the CRUD methods directly, so just throw to avoid accidental calls
      // to sqflite APIs from here.
      throw UnsupportedError(
        'Database initialization is not supported on web; use in-memory stores.',
      );
    }

    final databasesPath = await plain.getDatabasesPath();
    final path = join(databasesPath, _dbName);

    // If DB marked as encrypted, require opening with a derived key via
    // `openWithKey` to avoid attempting to open an encrypted DB without
    // password and causing failures. Callers should call `openWithKey`.
    final encryptedFlag = await SecureStorageService.instance.read(
      'db_encrypted',
    );
    if (encryptedFlag == '1') {
      throw Exception(
        'Database is encrypted; open with key using openWithKey().',
      );
    }

    return plain.openDatabase(
      path,
      version: _newDbVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: _onOpen,
    );
  }

  /// Close any existing DB and open it using a provided encryption key.
  Future<void> openWithKey(String key) async {
    if (_isWeb) return;
    final databasesPath = await plain.getDatabasesPath();
    final path = join(databasesPath, _dbName);

    if (_db != null) {
      try {
        await _db!.close();
      } catch (_) {}
      _db = null;
    }

    final t = defaultTargetPlatform;
    final supportsCipher = !kIsWeb &&
        (t == TargetPlatform.android ||
            t == TargetPlatform.iOS ||
            t == TargetPlatform.macOS);
    if (supportsCipher) {
      _db = await cipher.openDatabase(
        path,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
        password: key,
      );
    } else {
      // Fallback: open without encryption (e.g., web/desktop unsupported)
      _db = await plain.openDatabase(
        path,
        version: _dbVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _onOpen,
      );
    }
  }

  /// This performs an in-place conversion using SQLCipher `PRAGMA rekey`.
  /// The PIN's derived key is not stored; only a salted hash is kept by
  /// the `SecurityService` for verification.
  Future<void> enableEncryptionWithPin(String pin) async {
    if (_isWeb) return;
    final db = await database; // ensure DB is open
    final ok = await SecurityService.instance.verifyPin(pin);
    if (!ok) throw Exception('Invalid PIN');
    final key = await SecurityService.instance.deriveKeyFromPin(pin);
    if (key == null) throw Exception('Unable to derive key');
    // Attempt to run PRAGMA rekey; if the platform supports SQLCipher this
    // will encrypt the database in-place. If the underlying sqflite does not
    // support SQLCipher, this call may throw.
    try {
      await db.execute("PRAGMA rekey = '$key';");
      await SecureStorageService.instance.write('db_encrypted', '1');
    } catch (e) {
      throw Exception('Failed to enable DB encryption: $e');
    }
  }

  /// Returns true if the DB was marked as encrypted locally.
  Future<bool> isDatabaseEncrypted() async {
    if (_isWeb) return false;
    final v = await SecureStorageService.instance.read('db_encrypted');
    return v == '1';
  }

  /// Disable encryption by rekeying to an empty key (platform dependent).
  Future<void> disableEncryptionWithPin(String pin) async {
    if (_isWeb) return;
    final ok = await SecurityService.instance.verifyPin(pin);
    if (!ok) throw Exception('Invalid PIN');
    final db = await database;
    try {
      // Rekey to empty string to remove encryption (SQLCipher behavior).
      await db.execute("PRAGMA rekey = '';");
      await SecureStorageService.instance.delete('db_encrypted');
    } catch (e) {
      throw Exception('Failed to disable DB encryption: $e');
    }
  }

  /// Configure database connection (enable foreign keys).
  /// This runs before onCreate/onUpgrade.
  FutureOr<void> _onConfigure(plain.Database db) async {
    // Enable foreign key constraints
    await db.execute('PRAGMA foreign_keys = ON');
    debugPrint('DatabaseHelper: Foreign keys enabled');
  }

  /// Ensure essential tables exist even on databases created before v9 when opened at v10.
  FutureOr<void> _onOpen(plain.Database db) async {
    await _ensureCoreTables(db);
  }

  FutureOr<void> _onCreate(plain.Database db, int version) async {
    await db.execute('''
      CREATE TABLE counterparties (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT,
        tag TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance INTEGER NOT NULL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        parent_id INTEGER,
        type TEXT,
        color TEXT,
        icon TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(parent_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS budget_lines (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER NOT NULL,
        amount INTEGER NOT NULL,
        period TEXT NOT NULL,
        start_date_jalali TEXT,
        rollover INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
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
        compounding_frequency TEXT,
        grace_period_days INTEGER,
        monthly_payment INTEGER,
        term_months INTEGER,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(counterparty_id) REFERENCES counterparties(id) ON DELETE CASCADE
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
      CREATE TABLE budget_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT,
        amount INTEGER NOT NULL,
        period TEXT, -- yyyy-MM; null for one-off entries with date_jalali
        date_jalali TEXT, -- for one-off entries exact date (yyyy-MM-dd)
        is_one_off INTEGER NOT NULL DEFAULT 0,
        note TEXT,
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
        paid_at_jalali TEXT,
        actual_paid_amount INTEGER,
        notification_id INTEGER,
        FOREIGN KEY(loan_id) REFERENCES loans(id) ON DELETE CASCADE
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

    await db.execute('''
      CREATE TABLE income_profiles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        counterparty_id INTEGER,
        label TEXT,
        mode TEXT NOT NULL, -- 'fixed' or 'variable'
        created_at TEXT NOT NULL,
        FOREIGN KEY(counterparty_id) REFERENCES counterparties(id)
      )
    ''');

    // Transactions ledger table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT NOT NULL,
        amount INTEGER NOT NULL,
        direction TEXT NOT NULL,
        account_id INTEGER,
        related_type TEXT,
        related_id INTEGER,
        description TEXT,
        source TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ledger_entries (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount INTEGER NOT NULL,
        category_id INTEGER,
        ref_type TEXT NOT NULL,
        ref_id INTEGER,
        date_jalali TEXT NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_ref ON ledger_entries(ref_type, ref_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date_jalali)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_budget_lines_category ON budget_lines(category_id)',
    );

    try {
      await db.insert('accounts', {
        'name': 'Cash',
        'type': 'cash',
        'balance': 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _ensureCoreTables(plain.Database db) async {
    try {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'",
      );
      final names =
          tables.map((r) => r['name'] as String?).whereType<String>().toSet();

      if (!names.contains('accounts')) {
        await db.execute('''
          CREATE TABLE accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)',
        );
        await db.insert('accounts', {
          'name': 'Cash',
          'type': 'cash',
          'balance': 0,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      if (!names.contains('categories')) {
        await db.execute('''
          CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            parent_id INTEGER,
            type TEXT,
            color TEXT,
            icon TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY(parent_id) REFERENCES categories(id) ON DELETE SET NULL
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)',
        );
      }

      if (!names.contains('budget_lines')) {
        await db.execute('''
          CREATE TABLE budget_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            amount INTEGER NOT NULL,
            period TEXT NOT NULL,
            start_date_jalali TEXT,
            rollover INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_budget_lines_category ON budget_lines(category_id)',
        );
      }

      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_ref ON ledger_entries(ref_type, ref_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date_jalali)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)',
      );
    } catch (_) {}
  }

  FutureOr<void> _onUpgrade(
      plain.Database db, int oldVersion, int newVersion) async {
    debugPrint('DatabaseHelper: Migrating from v$oldVersion to v$newVersion');

    if (oldVersion < 2) {
      // Add the actual_paid_amount column to installments. Use a try/catch
      // to tolerate existing databases where the column may already exist.
      try {
        await db.execute(
          'ALTER TABLE installments ADD COLUMN actual_paid_amount INTEGER',
        );
        debugPrint('Migration: Added actual_paid_amount column');
      } catch (e) {
        debugPrint('Migration: actual_paid_amount column may exist: $e');
      }
    }

    if (oldVersion < 3) {
      // Add the optional tag column to counterparties.
      try {
        await db.execute('ALTER TABLE counterparties ADD COLUMN tag TEXT');
        debugPrint('Migration: Added tag column to counterparties');
      } catch (e) {
        debugPrint('Migration: tag column may exist: $e');
      }
    }

    if (oldVersion < 4) {
      // Add loan financial columns and create budgets table for upgrades
      try {
        await db.execute('ALTER TABLE loans ADD COLUMN interest_rate REAL');
      } catch (_) {}
      try {
        await db.execute(
          'ALTER TABLE loans ADD COLUMN monthly_payment INTEGER',
        );
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
        try {
          await db.execute('''
          CREATE TABLE IF NOT EXISTS budget_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category TEXT,
            amount INTEGER NOT NULL,
            period TEXT,
            date_jalali TEXT,
            is_one_off INTEGER NOT NULL DEFAULT 0,
            note TEXT,
            created_at TEXT NOT NULL
          )
        ''');
        } catch (_) {}
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
      // Ensure ledger indices exist even for existing databases
      await db.execute(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_ref ON ledger_entries(ref_type, ref_id)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date_jalali)',
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)',
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
    if (oldVersion < 6) {
      try {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            amount INTEGER NOT NULL,
            direction TEXT NOT NULL,
            account_id INTEGER,
            related_type TEXT,
            related_id INTEGER,
            description TEXT,
            source TEXT
          )
        ''');
      } catch (_) {}
    }
    if (oldVersion < 7) {
      // Add paid_at_jalali and ledger entries table; backfill existing data.
      try {
        try {
          await db.execute(
            'ALTER TABLE installments ADD COLUMN paid_at_jalali TEXT',
          );
        } catch (_) {}

        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS ledger_entries (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount INTEGER NOT NULL,
              category_id INTEGER,
              ref_type TEXT NOT NULL,
              ref_id INTEGER,
              date_jalali TEXT NOT NULL,
              note TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
            )
          ''');
          await db.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_ref ON ledger_entries(ref_type, ref_id)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date_jalali)');
          await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_budget_lines_category ON budget_lines(category_id)',
          );

          try {
            // Seed a default cash account so integrations can update balances safely.
            await db.insert('accounts', {
              'name': 'Cash',
              'type': 'cash',
              'balance': 0,
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}
        } catch (_) {}

        // Backfill paid_at_jalali from paid_at
        try {
          final rows = await db.query(
            'installments',
            columns: ['id', 'paid_at'],
            where: 'paid_at IS NOT NULL',
          );
          for (final row in rows) {
            final iid = row['id'];
            final paidAt = row['paid_at'] as String?;
            if (iid == null || paidAt == null) continue;
            final parsed = DateTime.tryParse(paidAt);
            if (parsed == null) continue;
            final j = dateTimeToJalali(parsed);
            final paidJ = formatJalali(j);
            try {
              await db.update(
                'installments',
                {'paid_at_jalali': paidJ},
                where: 'id = ?',
                whereArgs: [iid],
              );
            } catch (_) {}
          }
        } catch (_) {}

        // Seed ledger entries for existing loans (disbursements)
        try {
          final loans = await db.query('loans');
          for (final row in loans) {
            try {
              final loan = Loan.fromMap(row);
              if (loan.id == null) continue;
              final amt = loan.direction == LoanDirection.borrowed
                  ? loan.principalAmount
                  : -loan.principalAmount;
              final date = loan.startDateJalali.isNotEmpty
                  ? loan.startDateJalali
                  : _isoToJalaliString(loan.createdAt);
              final map = {
                'amount': amt,
                'ref_type': 'loan_disbursement',
                'ref_id': loan.id,
                'date_jalali': date,
                'note': loan.title,
                'created_at': DateTime.now().toIso8601String(),
              };
              try {
                await db.insert(
                  'ledger_entries',
                  map,
                  conflictAlgorithm: plain.ConflictAlgorithm.ignore,
                );
              } catch (_) {}
            } catch (_) {}
          }
        } catch (_) {}

        // Seed ledger entries for already-paid installments
        try {
          final paidRows = await db.rawQuery(
            '''
            SELECT i.id, i.actual_paid_amount, i.amount, i.paid_at, i.paid_at_jalali,
                   l.direction, l.title
            FROM installments i
            JOIN loans l ON i.loan_id = l.id
            WHERE i.status = 'paid'
          ''',
          );
          for (final r in paidRows) {
            try {
              final instId = r['id'];
              if (instId == null) continue;
              final amtRaw = r['actual_paid_amount'] ?? r['amount'];
              final amt = amtRaw is int ? amtRaw : int.tryParse('$amtRaw') ?? 0;
              final dirStr = (r['direction'] as String?) ?? 'borrowed';
              final dir = dirStr == 'lent'
                  ? LoanDirection.lent
                  : LoanDirection.borrowed;
              final signed = dir == LoanDirection.borrowed ? -amt : amt;
              final paidIso = r['paid_at'] as String?;
              final paidJ = (r['paid_at_jalali'] as String?) ??
                  _isoToJalaliString(paidIso);
              final title = r['title'] as String?;
              final map = {
                'amount': signed,
                'ref_type': 'installment_payment',
                'ref_id': instId,
                'date_jalali': paidJ,
                'note': title,
                'created_at': DateTime.now().toIso8601String(),
              };
              try {
                await db.insert(
                  'ledger_entries',
                  map,
                  conflictAlgorithm: plain.ConflictAlgorithm.ignore,
                );
              } catch (e) {
                debugPrint(
                    'Migration: Ledger entry insertion failed for installment: $e');
              }
            } catch (e) {
              debugPrint(
                  'Migration: Failed to process installment ledger entry: $e');
            }
          }
        } catch (e) {
          debugPrint('Migration: Paid installments ledger seeding warning: $e');
        }
      } catch (e) {
        debugPrint('Migration: v7 upgrade completed with warnings: $e');
      }
    }

    if (oldVersion < 8) {
      // Add ON DELETE CASCADE to foreign keys by recreating tables
      // This is necessary because SQLite doesn't support ALTER TABLE to modify FK constraints
      debugPrint('Migration: v8 - Adding ON DELETE CASCADE to foreign keys');

      try {
        // Wrap all operations in a transaction to ensure atomicity
        await db.transaction((txn) async {
          // 1. Recreate loans table with CASCADE
          await txn.execute('''
            CREATE TABLE loans_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              counterparty_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              direction TEXT NOT NULL,
              principal_amount INTEGER NOT NULL,
              installment_count INTEGER NOT NULL,
              installment_amount INTEGER NOT NULL,
              start_date_jalali TEXT NOT NULL,
              interest_rate REAL,
              compounding_frequency TEXT,
              grace_period_days INTEGER,
              monthly_payment INTEGER,
              term_months INTEGER,
              notes TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY(counterparty_id) REFERENCES counterparties(id) ON DELETE CASCADE
            )
          ''');

          // Copy data
          await txn.execute('''
            INSERT INTO loans_new SELECT * FROM loans
          ''');

          // Drop old table and rename
          await txn.execute('DROP TABLE loans');
          await txn.execute('ALTER TABLE loans_new RENAME TO loans');

          // Recreate loan indices
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_loans_counterparty ON loans(counterparty_id)',
          );

          debugPrint('Migration: v8 - loans table recreated with CASCADE');

          // 2. Recreate installments table with CASCADE
          await txn.execute('''
            CREATE TABLE installments_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              loan_id INTEGER NOT NULL,
              due_date_jalali TEXT NOT NULL,
              amount INTEGER NOT NULL,
              status TEXT NOT NULL,
              paid_at TEXT,
              paid_at_jalali TEXT,
              actual_paid_amount INTEGER,
              notification_id INTEGER,
              FOREIGN KEY(loan_id) REFERENCES loans(id) ON DELETE CASCADE
            )
          ''');

          // Copy data
          await txn.execute('''
            INSERT INTO installments_new SELECT * FROM installments
          ''');

          // Drop old table and rename
          await txn.execute('DROP TABLE installments');
          await txn
              .execute('ALTER TABLE installments_new RENAME TO installments');

          // Recreate installment indices
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_installments_loan_id ON installments(loan_id)',
          );
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_installments_due_date ON installments(due_date_jalali)',
          );
          await txn.execute(
            'CREATE INDEX IF NOT EXISTS idx_installments_status ON installments(status)',
          );

          debugPrint(
              'Migration: v8 - installments table recreated with CASCADE');
        });
      } catch (e) {
        debugPrint('Migration: v8 upgrade failed: $e');
        throw Exception('Failed to migrate to v8: $e');
      }
    }

    if (oldVersion < 9) {
      // v9: Add accounts, categories, and budget_lines to support the
      // coherent financial model (accounts, categories, budgets per line).
      debugPrint('Migration: v9 - Creating accounts, categories, budget_lines');
      try {
        // Use IF NOT EXISTS to be idempotent across runs
        await db.execute('''
          CREATE TABLE IF NOT EXISTS accounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            balance INTEGER NOT NULL DEFAULT 0,
            notes TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            type TEXT,
            color TEXT,
            icon TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS budget_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            category_id INTEGER NOT NULL,
            amount INTEGER NOT NULL,
            period TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE CASCADE
          )
        ''');

        // Indices for faster lookups
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_accounts_name ON accounts(name)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_categories_name ON categories(name)');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_budget_lines_category ON budget_lines(category_id)');

        // Seed a default 'Cash' account if none exist to avoid null-account UX
        try {
          final rows = await db.rawQuery('SELECT COUNT(1) as c FROM accounts');
          final count = (rows.isNotEmpty && rows.first['c'] != null)
              ? int.tryParse('${rows.first['c']}') ?? 0
              : 0;
          if (count == 0) {
            await db.insert('accounts', {
              'name': 'Cash',
              'type': 'cash',
              'balance': 0,
              'created_at': DateTime.now().toIso8601String(),
            });
          }
        } catch (_) {}
      } catch (e) {
        debugPrint('Migration: v9 upgrade failed: $e');
        // don't throw here to avoid blocking upgrades on non-critical schema
      }
    }

    if (oldVersion < 10) {
      // v10: add category_id to ledger_entries and attempt backfill from
      // existing data (note matching category name or counterparty tags).
      debugPrint('Migration: v10 - Adding category_id to ledger_entries');
      try {
        await db.transaction((txn) async {
          // Recreate ledger_entries with category_id and FK to categories
          await txn.execute('''
            CREATE TABLE ledger_entries_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              amount INTEGER NOT NULL,
              category_id INTEGER,
              ref_type TEXT NOT NULL,
              ref_id INTEGER,
              date_jalali TEXT NOT NULL,
              note TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY(category_id) REFERENCES categories(id) ON DELETE SET NULL
            )
          ''');

          // Copy existing data, leaving category_id NULL for now
          await txn.execute('''
            INSERT INTO ledger_entries_new (id, amount, ref_type, ref_id, date_jalali, note, created_at)
            SELECT id, amount, ref_type, ref_id, date_jalali, note, created_at FROM ledger_entries
          ''');

          await txn.execute('DROP TABLE ledger_entries');
          await txn.execute(
              'ALTER TABLE ledger_entries_new RENAME TO ledger_entries');

          // Recreate indices
          await txn.execute(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_ledger_ref ON ledger_entries(ref_type, ref_id)');
          await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_ledger_date ON ledger_entries(date_jalali)');
          await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_ledger_category_date ON ledger_entries(category_id, date_jalali)');
        });

        // Attempt best-effort backfills (non-transactional, tolerate failures)
        try {
          // 1) If note matches a category name exactly, assign that category
          await db.execute('''
            UPDATE ledger_entries
            SET category_id = (
              SELECT id FROM categories WHERE name = ledger_entries.note LIMIT 1
            )
            WHERE note IS NOT NULL AND category_id IS NULL
          ''');
        } catch (_) {}

        try {
          // 2) For loan disbursements, try to use the counterparty.tag -> categories.name
          await db.execute('''
            UPDATE ledger_entries
            SET category_id = (
              SELECT c.id FROM categories c
              WHERE c.name = (
                SELECT tag FROM counterparties cp
                WHERE cp.id = (
                  SELECT counterparty_id FROM loans l WHERE l.id = ledger_entries.ref_id
                )
              ) LIMIT 1
            )
            WHERE ref_type = 'loan_disbursement' AND ref_id IS NOT NULL AND category_id IS NULL
          ''');
        } catch (_) {}

        try {
          // 3) For installment payments, follow installment -> loan -> counterparty.tag
          await db.execute('''
            UPDATE ledger_entries
            SET category_id = (
              SELECT c.id FROM categories c
              WHERE c.name = (
                SELECT tag FROM counterparties cp
                WHERE cp.id = (
                  SELECT counterparty_id FROM loans l WHERE l.id = (
                    SELECT loan_id FROM installments i WHERE i.id = ledger_entries.ref_id
                  )
                )
              ) LIMIT 1
            )
            WHERE ref_type = 'installment_payment' AND ref_id IS NOT NULL AND category_id IS NULL
          ''');
        } catch (_) {}
      } catch (e) {
        debugPrint('Migration: v10 upgrade warning: $e');
      }
    }

    debugPrint(
        'DatabaseHelper: Migration to v$newVersion completed successfully');
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

  // -----------------
  // Transactions / Ledger
  // -----------------

  Future<int> insertTransaction(Map<String, dynamic> txn) async {
    if (_isWeb) {
      _transactionId++;
      final map = Map<String, dynamic>.from(txn);
      map['id'] = _transactionId;
      _transactionStore.add(map);
      return _transactionId;
    }

    final db = await database;
    // Keep transaction atomic: insert transaction and update account balance
    final Map<String, dynamic> txnMap = Map<String, dynamic>.from(txn);
    return await db.transaction<int>((transaction) async {
      final id = await transaction.insert('transactions', txnMap);
      try {
        final accountId = txnMap['account_id'] as int?;
        final direction = txnMap['direction'] as String? ?? 'debit';
        final amount = txnMap['amount'] is int
            ? txnMap['amount'] as int
            : int.tryParse('${txnMap['amount']}') ?? 0;
        if (accountId != null) {
          // Apply balance change on accounts table
          if (direction == 'credit') {
            await transaction.execute(
                'UPDATE accounts SET balance = COALESCE(balance,0) + ? WHERE id = ?',
                [amount, accountId]);
          } else {
            await transaction.execute(
                'UPDATE accounts SET balance = COALESCE(balance,0) - ? WHERE id = ?',
                [amount, accountId]);
          }
        }
      } catch (error, stackTrace) {
        // Ensure atomicity: if account balance update fails, roll back the transaction.
        debugPrint(
            'insertTransaction balance update failed for txn ${txnMap['id'] ?? 'unknown'}: $error');
        debugPrint(stackTrace.toString());
        // Rethrow so the surrounding DB transaction is rolled back.
        rethrow;
      }
      return id;
    });
  }

  Future<List<Map<String, dynamic>>> getTransactionsByAccount(
      int accountId) async {
    if (_isWeb) {
      final rows = _transactionStore
          .where((r) => r['account_id'] == accountId)
          .toList()
        ..sort((a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return rows;
    }
    final db = await database;
    return await db.query('transactions',
        where: 'account_id = ?',
        whereArgs: [accountId],
        orderBy: 'timestamp DESC');
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    if (_isWeb) {
      final rows = List<Map<String, dynamic>>.from(_transactionStore)
        ..sort((a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return rows;
    }
    final db = await database;
    return await db.query('transactions', orderBy: 'timestamp DESC');
  }

  // -----------------
  // Accounts / Categories / BudgetLines CRUD
  // -----------------

  Future<List<Account>> getAccounts() async {
    if (_isWeb) {
      return _transactionStore
          .map((row) => Account(
                id: row['id'] as int?,
                name: row['name'] as String? ?? 'Unnamed',
                type: row['type'] as String? ?? 'cash',
                balance: row['balance'] is int
                    ? row['balance'] as int
                    : int.tryParse('${row['balance']}') ?? 0,
                notes: row['notes'] as String?,
                createdAt: row['created_at'] as String? ??
                    DateTime.now().toIso8601String(),
              ))
          .toList();
    }

    final db = await database;
    final rows = await db.query('accounts', orderBy: 'name ASC');
    return rows
        .map((r) => Account(
              id: r['id'] as int?,
              name: r['name'] as String? ?? 'Unnamed',
              type: r['type'] as String? ?? 'cash',
              balance: r['balance'] is int
                  ? r['balance'] as int
                  : int.tryParse('${r['balance']}') ?? 0,
              notes: r['notes'] as String?,
              createdAt: r['created_at'] as String? ??
                  DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  Future<int> insertAccount(Account a) async {
    if (_isWeb) {
      _transactionId++;
      final map = {
        'id': _transactionId,
        'name': a.name,
        'type': a.type,
        'balance': a.balance ?? 0,
        'notes': a.notes,
        'created_at': a.createdAt,
      };
      _transactionStore.add(map);
      return _transactionId;
    }
    final db = await database;
    return await db.insert('accounts', {
      'name': a.name,
      'type': a.type,
      'balance': a.balance ?? 0,
      'notes': a.notes,
      'created_at': a.createdAt,
    });
  }

  Future<int> updateAccount(Account a) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.update(
        'accounts',
        {
          'name': a.name,
          'type': a.type,
          'balance': a.balance ?? 0,
          'notes': a.notes,
          'created_at': a.createdAt,
        },
        where: 'id = ?',
        whereArgs: [a.id]);
  }

  Future<int> deleteAccount(int id) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Category>> getCategories() async {
    if (_isWeb) return [];
    final db = await database;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows
        .map((r) => Category(
              id: r['id'] as int?,
              name: r['name'] as String? ?? 'Unnamed',
              type: r['type'] as String? ?? 'expense',
              color: r['color'] as String?,
              icon: r['icon'] as String?,
              createdAt: r['created_at'] as String? ??
                  DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  Future<int> insertCategory(Category c) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.insert('categories', {
      'name': c.name,
      'type': c.type,
      'color': c.color,
      'icon': c.icon,
      'created_at': c.createdAt,
    });
  }

  Future<int> updateCategory(Category c) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.update(
        'categories',
        {
          'name': c.name,
          'type': c.type,
          'color': c.color,
          'icon': c.icon,
          'created_at': c.createdAt,
        },
        where: 'id = ?',
        whereArgs: [c.id]);
  }

  Future<int> deleteCategory(int id) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BudgetLine>> getBudgetLines() async {
    if (_isWeb) return [];
    final db = await database;
    final rows = await db.query('budget_lines', orderBy: 'created_at DESC');
    return rows
        .map((r) => BudgetLine(
              id: r['id'] as int?,
              categoryId: r['category_id'] as int,
              amount: r['amount'] as int,
              period: r['period'] as String,
              spent: r['spent'] is int ? r['spent'] as int : null,
              createdAt: r['created_at'] as String? ??
                  DateTime.now().toIso8601String(),
            ))
        .toList();
  }

  Future<int> insertBudgetLine(BudgetLine b) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.insert('budget_lines', {
      'category_id': b.categoryId,
      'amount': b.amount,
      'period': b.period,
      'created_at': b.createdAt,
    });
  }

  Future<int> updateBudgetLine(BudgetLine b) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.update(
        'budget_lines',
        {
          'category_id': b.categoryId,
          'amount': b.amount,
          'period': b.period,
          'created_at': b.createdAt,
        },
        where: 'id = ?',
        whereArgs: [b.id]);
  }

  Future<int> deleteBudgetLine(int id) async {
    if (_isWeb) return 1;
    final db = await database;
    return await db.delete('budget_lines', where: 'id = ?', whereArgs: [id]);
  }

  // -----------------
  // Aggregations
  // -----------------

  /// Returns total spent (positive number) for a category in a given period (period format: 'yyyy-MM').
  /// Only expense entries (amount < 0) are included and summed as positive.
  Future<int> getBudgetSpent(int categoryId, String period) async {
    if (_isWeb) return 0;
    final db = await database;
    try {
      final rows = await db.rawQuery('''
        SELECT COALESCE(SUM(-amount),0) as spent
        FROM ledger_entries
        WHERE date_jalali LIKE ?
          AND category_id = ?
          AND amount < 0
      ''', ['$period%', categoryId]);
      final v = rows.first['spent'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
    } catch (_) {}
    return 0;
  }

  Future<int> getNetWorth() async {
    if (_isWeb) return 0;
    final db = await database;
    try {
      final rows = await db
          .rawQuery('SELECT COALESCE(SUM(balance),0) as total FROM accounts');
      final v = rows.first['total'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
    } catch (_) {}
    return 0;
  }

  Future<int> getMonthlyCashflow(String period) async {
    if (_isWeb) return 0;
    final db = await database;
    try {
      final rows = await db.rawQuery('''
        SELECT COALESCE(SUM(amount),0) as total
        FROM ledger_entries
        WHERE date_jalali LIKE ?
      ''', ['$period%']);
      final v = rows.first['total'];
      if (v is int) return v;
      if (v is String) return int.tryParse(v) ?? 0;
    } catch (_) {}
    return 0;
  }

  /// Returns a map of category name -> total spent (positive number) for a given Jalali month.
  /// Month is specified by `year` and `month` (1-12). Only expense entries (amount < 0) are summed.
  Future<Map<String, int>> getSpendingByCategoryForMonth(
      int year, int month) async {
    // Build the period prefix like 'yyyy-MM'
    final mm = month.toString().padLeft(2, '0');
    final like = '$year-$mm%';

    if (_isWeb) {
      // Best-effort web fallback using in-memory ledger store; categories not persisted on web here.
      final out = <String, int>{};
      for (final r in _ledgerStore) {
        final d = r['date_jalali'] as String?;
        if (d == null || !d.startsWith('$year-$mm')) continue;
        final amtRaw = r['amount'];
        final amt = amtRaw is int ? amtRaw : int.tryParse('$amtRaw') ?? 0;
        if (amt >= 0) continue; // expenses only
        // No category name storage on web fallback; group under 'Uncategorized'
        const name = 'Uncategorized';
        out[name] = (out[name] ?? 0) + (-amt);
      }
      return out;
    }

    final db = await database;
    final rows = await db.rawQuery('''
      SELECT c.name as category, COALESCE(SUM(-le.amount),0) as spent
      FROM ledger_entries le
      LEFT JOIN categories c ON c.id = le.category_id
      WHERE le.date_jalali LIKE ? AND le.amount < 0
      GROUP BY c.name
    ''', [like]);

    final map = <String, int>{};
    for (final r in rows) {
      final name = (r['category'] as String?) ?? 'Uncategorized';
      final v = r['spent'];
      final val = v is int ? v : (v is String ? int.tryParse(v) ?? 0 : 0);
      map[name] = val;
    }
    return map;
  }

  Future<List<Map<String, dynamic>>> getTransactionsByRelated(
      String relatedType, int relatedId) async {
    if (_isWeb) {
      final rows = _transactionStore
          .where((r) =>
              r['related_type'] == relatedType && r['related_id'] == relatedId)
          .toList()
        ..sort((a, b) =>
            (b['timestamp'] as String).compareTo(a['timestamp'] as String));
      return rows;
    }
    final db = await database;
    return await db.query('transactions',
        where: 'related_type = ? AND related_id = ?',
        whereArgs: [relatedType, relatedId],
        orderBy: 'timestamp DESC');
  }

  Future<int> getAccountBalance(int accountId) async {
    if (_isWeb) {
      int balance = 0;
      for (final t
          in _transactionStore.where((r) => r['account_id'] == accountId)) {
        final dir = (t['direction'] as String?) ?? 'debit';
        final amt = t['amount'] is int
            ? t['amount'] as int
            : int.parse(t['amount'].toString());
        if (dir == 'credit') {
          balance += amt;
        } else {
          balance -= amt;
        }
      }
      return balance;
    }
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT COALESCE(SUM(CASE WHEN direction = 'credit' THEN amount ELSE -amount END), 0) as balance
      FROM transactions
      WHERE account_id = ?
    ''', [accountId]);
    final value = rows.first['balance'];
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  // ---- Ledger entries ----

  String _isoToJalaliString(String? iso) {
    if (iso == null || iso.isEmpty) {
      return formatJalali(dateTimeToJalali(DateTime.now()));
    }
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) {
      return formatJalali(dateTimeToJalali(DateTime.now()));
    }
    return formatJalali(dateTimeToJalali(parsed));
  }

  Future<int> upsertLedgerEntry(LedgerEntry entry) async {
    if (_isWeb) {
      // Replace existing entry with same ref_type/ref_id (if any) to keep idempotent.
      final idx = _ledgerStore.indexWhere(
        (r) => r['ref_type'] == entry.refType && r['ref_id'] == entry.refId,
      );
      final map = entry.toMap();
      if (idx >= 0) {
        _ledgerStore[idx] = {
          ..._ledgerStore[idx],
          ...map,
          'id': _ledgerStore[idx]['id']
        };
        return _ledgerStore[idx]['id'] as int;
      }
      _ledgerId++;
      map['id'] = _ledgerId;
      _ledgerStore.add(map);
      return _ledgerId;
    }

    final db = await database;
    return await db.insert(
      'ledger_entries',
      entry.toMap(),
      conflictAlgorithm: plain.ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteLedgerEntryByRef(String refType, int refId) async {
    if (_isWeb) {
      final before = _ledgerStore.length;
      _ledgerStore
          .removeWhere((r) => r['ref_type'] == refType && r['ref_id'] == refId);
      return before - _ledgerStore.length;
    }
    final db = await database;
    return await db.delete(
      'ledger_entries',
      where: 'ref_type = ? AND ref_id = ?',
      whereArgs: [refType, refId],
    );
  }

  /// Set `category_id` for a ledger entry identified by its ref_type/ref_id.
  /// Returns number of rows updated.
  Future<int> setLedgerEntryCategoryByRef(
      String refType, int refId, int categoryId) async {
    if (_isWeb) {
      var updated = 0;
      for (var r in _ledgerStore) {
        if (r['ref_type'] == refType && r['ref_id'] == refId) {
          r['category_id'] = categoryId;
          updated++;
        }
      }
      return updated;
    }
    final db = await database;
    return await db.update(
      'ledger_entries',
      {'category_id': categoryId},
      where: 'ref_type = ? AND ref_id = ?',
      whereArgs: [refType, refId],
    );
  }

  Future<int> getLedgerBalance({int initialBalance = 0}) async {
    if (_isWeb) {
      final total = _ledgerStore.fold<int>(initialBalance, (sum, r) {
        final amt = r['amount'];
        final parsed = amt is int ? amt : int.tryParse('$amt') ?? 0;
        return sum + parsed;
      });
      return total;
    }
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM ledger_entries',
    );
    final value = rows.first['total'];
    if (value is int) return initialBalance + value;
    if (value is String) return initialBalance + (int.tryParse(value) ?? 0);
    return initialBalance;
  }

  Future<List<LedgerEntry>> getLedgerEntriesBetween(
    String start,
    String end,
  ) async {
    if (_isWeb) {
      final rows = _ledgerStore.where((r) {
        final d = r['date_jalali'] as String?;
        if (d == null) return false;
        return d.compareTo(start) >= 0 && d.compareTo(end) <= 0;
      }).toList()
        ..sort(
          (a, b) =>
              (a['date_jalali'] as String?)
                  ?.compareTo(b['date_jalali'] as String? ?? '') ??
              0,
        );
      return rows.map((r) => LedgerEntry.fromMap(r)).toList();
    }
    final db = await database;
    final rows = await db.query(
      'ledger_entries',
      where: 'date_jalali BETWEEN ? AND ?',
      whereArgs: [start, end],
      orderBy: 'date_jalali ASC, id ASC',
    );
    return rows.map((r) => LedgerEntry.fromMap(r)).toList();
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
      try {
        final amt = loan.direction == LoanDirection.borrowed
            ? loan.principalAmount
            : -loan.principalAmount;
        final date = loan.startDateJalali.isNotEmpty
            ? loan.startDateJalali
            : _isoToJalaliString(loan.createdAt);
        await upsertLedgerEntry(
          LedgerEntry(
            id: null,
            amount: amt,
            refType: 'loan_disbursement',
            refId: _loanId,
            dateJalali: date,
            note: loan.title,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } catch (_) {}
      return _loanId;
    }

    final db = await database;
    final id = await db.insert('loans', loan.toMap());
    try {
      final amt = loan.direction == LoanDirection.borrowed
          ? loan.principalAmount
          : -loan.principalAmount;
      final date = loan.startDateJalali.isNotEmpty
          ? loan.startDateJalali
          : _isoToJalaliString(loan.createdAt);

      // Resolve category id from counterparty tag or automation suggestions.
      // NOTE: This involves querying counterparties, categories, and potentially
      // automation_rules tables. For batch loan imports, consider pre-resolving
      // categories to avoid repeated queries. Current implementation prioritizes
      // accuracy and ease of use for typical single-loan insertion flows.
      int? categoryId;
      try {
        final cpRows = await db.query(
          'counterparties',
          where: 'id = ?',
          whereArgs: [loan.counterpartyId],
          limit: 1,
        );
        final payee = (cpRows.isNotEmpty
                ? cpRows.first['name'] as String?
                : loan.title) ??
            '';
        final tag = (cpRows.isNotEmpty ? cpRows.first['tag'] as String? : null);
        String? catName = tag;
        if (catName == null) {
          try {
            // Only attempt to use automation rules if the underlying table exists.
            final automationTable = await db.rawQuery(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'automation_rules' LIMIT 1",
            );
            if (automationTable.isNotEmpty) {
              final repo = AutomationRulesRepository();
              final suggestion = await repo.applyRules(
                  payee, loan.notes ?? '', loan.principalAmount);
              catName = suggestion['category'];
            }
          } catch (e) {
            // Make sure any automation-related failure does not affect the main transaction.
            debugPrint('AutomationRulesRepository.applyRules failed: $e');
          }
        }
        if (catName != null) {
          final catRows = await db.query('categories',
              where: 'name = ?', whereArgs: [catName], limit: 1);
          if (catRows.isNotEmpty) categoryId = catRows.first['id'] as int?;
        }
      } catch (_) {}

      await upsertLedgerEntry(
        LedgerEntry(
          id: null,
          amount: amt,
          categoryId: categoryId,
          refType: 'loan_disbursement',
          refId: id,
          dateJalali: date,
          note: loan.title,
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
    } catch (_) {}
    // Re-run insights and reschedule notifications when a loan is added.
    final settings = SettingsRepository();
    await settings.init();
    if (settings.smartInsightsEnabled) {
      await SmartInsightsService().runInsights(notify: false);
    }
    try {
      await NotificationService().rebuildScheduledNotifications();
    } catch (_) {
      // In some test environments the notifications plugin/platform
      // may not be initialized; swallow errors to keep DB operations safe.
    }
    return id;
  }

  Future<List<Loan>> getAllLoans({LoanDirection? direction}) async {
    if (_isWeb) {
      var rows = List<Map<String, dynamic>>.from(_loanStore);
      if (direction != null) {
        final dirStr =
            direction == LoanDirection.borrowed ? 'borrowed' : 'lent';
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
      final smartEnabled =
          await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) {
        await SmartInsightsService().runInsights(notify: true);
      }
      // Apply automation rules to potentially tag the counterparty/loan
      try {
        final loanRows = await db.query(
          'loans',
          where: 'id = ?',
          whereArgs: [installment.loanId],
          limit: 1,
        );
        if (loanRows.isNotEmpty) {
          final loan = Loan.fromMap(loanRows.first);
          final cpRows = await db.query(
            'counterparties',
            where: 'id = ?',
            whereArgs: [loan.counterpartyId],
            limit: 1,
          );
          final payee = (cpRows.isNotEmpty
                  ? cpRows.first['name'] as String?
                  : loan.title) ??
              '';
          final desc = loan.notes ?? '';
          final amt = installment.actualPaidAmount ?? installment.amount;
          final repo = AutomationRulesRepository();

          final suggestion = await repo.applyRules(payee, desc, amt);
          final cat = suggestion['category'];
          if (cat != null && cpRows.isNotEmpty) {
            await db.update(
              'counterparties',
              {'tag': cat},
              where: 'id = ?',
              whereArgs: [loan.counterpartyId],
            );
          }
        }
      } catch (_) {}
    } catch (_) {}
    try {
      await NotificationService().rebuildScheduledNotifications();
    } catch (_) {}
    return id;
  }

  // Delete all installments for a given loan id.

  Future<int> deleteInstallmentsByLoanId(int loanId) async {
    if (_isWeb) {
      final ids = _installmentStore
          .where((r) => r['loan_id'] == loanId)
          .map((r) => r['id'])
          .whereType<int>()
          .toList();
      _installmentStore.removeWhere((r) => r['loan_id'] == loanId);
      for (final id in ids) {
        try {
          await deleteLedgerEntryByRef('installment_payment', id);
        } catch (_) {}
      }
      return 1;
    }

    final db = await database;
    try {
      final rows = await db.query(
        'installments',
        columns: ['id'],
        where: 'loan_id = ?',
        whereArgs: [loanId],
      );
      for (final r in rows) {
        final id = r['id'];
        if (id is int) {
          await deleteLedgerEntryByRef('installment_payment', id);
        }
      }
    } catch (_) {}
    final res = await db.delete(
      'installments',
      where: 'loan_id = ?',
      whereArgs: [loanId],
    );
    try {
      final smartEnabled =
          await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) await SmartInsightsService().runInsights(notify: true);
    } catch (_) {}
    try {
      await NotificationService().rebuildScheduledNotifications();
    } catch (_) {}
    return res;
  }

  Future<List<Installment>> getInstallmentsByLoanId(int loanId) async {
    if (_isWeb) {
      final rows =
          _installmentStore.where((r) => r['loan_id'] == loanId).toList()
            ..sort(
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
      try {
        final loan = _loanStore.firstWhere(
          (l) => l['id'] == installment.loanId,
          orElse: () => {},
        );
        final direction = loan['direction'] == 'lent'
            ? LoanDirection.lent
            : LoanDirection.borrowed;
        if (installment.status == InstallmentStatus.paid) {
          final amt = (installment.actualPaidAmount ?? installment.amount) *
              (direction == LoanDirection.borrowed ? -1 : 1);
          final paidJ = installment.paidAtJalali ??
              _isoToJalaliString(installment.paidAt);
          await upsertLedgerEntry(
            LedgerEntry(
              id: null,
              amount: amt,
              refType: 'installment_payment',
              refId: installment.id,
              dateJalali: paidJ,
              note: loan['title'] as String?,
              createdAt: DateTime.now().toIso8601String(),
            ),
          );
        } else if (installment.id != null) {
          await deleteLedgerEntryByRef('installment_payment', installment.id!);
        }
      } catch (_) {}
      return 1;
    }

    final db = await database;
    final res = await db.update(
      'installments',
      installment.toMap(),
      where: 'id = ?',
      whereArgs: [installment.id],
    );
    try {
      Loan? loan;
      try {
        final row = await db.query(
          'loans',
          where: 'id = ?',
          whereArgs: [installment.loanId],
          limit: 1,
        );
        if (row.isNotEmpty) loan = Loan.fromMap(row.first);
      } catch (_) {}

      if (installment.status == InstallmentStatus.paid) {
        final direction = loan?.direction ?? LoanDirection.borrowed;
        final amt = (installment.actualPaidAmount ?? installment.amount) *
            (direction == LoanDirection.borrowed ? -1 : 1);
        final paidJ =
            installment.paidAtJalali ?? _isoToJalaliString(installment.paidAt);

        // Attempt to resolve a category id for this installment payment.
        // NOTE: This category resolution involves multiple database queries
        // (counterparties, categories, automation_rules) and may add latency
        // to the installment update operation. For high-frequency updates,
        // consider caching category mappings or moving resolution to a
        // background task. Current implementation prioritizes data consistency
        // over performance for typical use cases with moderate update frequency.
        int? categoryId;
        try {
          String? catName;
          if (loan != null) {
            final cpRows = await db.query(
              'counterparties',
              where: 'id = ?',
              whereArgs: [loan.counterpartyId],
              limit: 1,
            );
            final payee = (cpRows.isNotEmpty
                    ? cpRows.first['name'] as String?
                    : loan.title) ??
                '';
            final tag =
                (cpRows.isNotEmpty ? cpRows.first['tag'] as String? : null);
            catName = tag;
            if (catName == null) {
              try {
                // Only attempt to use automation rules if the underlying table exists.
                final automationTable = await db.rawQuery(
                  "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'automation_rules' LIMIT 1",
                );
                if (automationTable.isNotEmpty) {
                  final repo = AutomationRulesRepository();
                  final suggestion = await repo.applyRules(
                      payee, loan.notes ?? '', (amt).abs());
                  catName = suggestion['category'];
                }
              } catch (e) {
                // Make sure any automation-related failure does not affect the main transaction.
                debugPrint('AutomationRulesRepository.applyRules failed: $e');
              }
            }
          }

          if (catName != null) {
            final catRows = await db.query('categories',
                where: 'name = ?', whereArgs: [catName], limit: 1);
            if (catRows.isNotEmpty) categoryId = catRows.first['id'] as int?;
          }
        } catch (_) {}

        await upsertLedgerEntry(
          LedgerEntry(
            id: null,
            amount: amt,
            categoryId: categoryId,
            refType: 'installment_payment',
            refId: installment.id,
            dateJalali: paidJ,
            note: loan?.title,
            createdAt: DateTime.now().toIso8601String(),
          ),
        );
      } else if (installment.id != null) {
        await deleteLedgerEntryByRef('installment_payment', installment.id!);
      }
    } catch (_) {}
    try {
      final smartEnabled =
          await SettingsRepository().getSmartSuggestionsEnabled();
      if (smartEnabled) {
        await SmartInsightsService().runInsights(notify: true);
      }
      try {
        final loanRows = await db.query(
          'loans',
          where: 'id = ?',
          whereArgs: [installment.loanId],
          limit: 1,
        );
        if (loanRows.isNotEmpty) {
          final loan = Loan.fromMap(loanRows.first);
          final cpRows = await db.query(
            'counterparties',
            where: 'id = ?',
            whereArgs: [loan.counterpartyId],
            limit: 1,
          );
          final payee = (cpRows.isNotEmpty
                  ? cpRows.first['name'] as String?
                  : loan.title) ??
              '';
          final desc = loan.notes ?? '';
          final amt = installment.actualPaidAmount ?? installment.amount;
          final repo = AutomationRulesRepository();
          final suggestion = await repo.applyRules(payee, desc, amt);
          final cat = suggestion['category'];
          if (cat != null && cpRows.isNotEmpty) {
            await db.update(
              'counterparties',
              {'tag': cat},
              where: 'id = ?',
              whereArgs: [loan.counterpartyId],
            );
          }
        }
      } catch (_) {}
    } catch (_) {}
    try {
      await NotificationService().rebuildScheduledNotifications();
    } catch (_) {}
    return res;
  }

  // Update an existing loan row. Requires loan.id to be non-null.
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

  // Delete a loan row by id.
  Future<int> deleteLoan(int loanId) async {
    if (_isWeb) {
      _loanStore.removeWhere((r) => r['id'] == loanId);
      return 1;
    }

    final db = await database;
    return await db.delete('loans', where: 'id = ?', whereArgs: [loanId]);
  }

  // Delete a loan and all its installments. This method will cancel any
  // scheduled notifications associated with the installments before deleting
  // them and the loan itself.
  Future<void> deleteLoanWithInstallments(int loanId) async {
    // Fetch installments to cancel notifications
    final installments = await getInstallmentsByLoanId(loanId);

    // Get max offset days from settings to cancel all possible notification IDs
    final settings = SettingsRepository();
    final maxOffsetDays = await settings.getReminderOffsetDays();

    for (final inst in installments) {
      if (inst.id != null) {
        try {
          await NotificationService().cancelInstallmentNotifications(
            inst.id!,
            maxOffsetDays,
          );
        } catch (_) {}
      }
    }

    // Delete installments first, then the loan
    await deleteInstallmentsByLoanId(loanId);
    try {
      for (final inst in installments) {
        if (inst.id != null) {
          await deleteLedgerEntryByRef('installment_payment', inst.id!);
        }
      }
      await deleteLedgerEntryByRef('loan_disbursement', loanId);
    } catch (_) {}
    await deleteLoan(loanId);
  }

  Future<Map<int, List<Installment>>> getInstallmentsGroupedByLoanId(
    List<int> loanIds,
  ) async {
    if (loanIds.isEmpty) return {};

    if (_isWeb) {
      final filtered = _installmentStore
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
      final rows = _installmentStore.where((r) {
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

  // Refresh installments that are overdue based on a provided Gregorian `now`.
  // Converts `now` to Jalali and updates installments whose `due_date_jalali` < today.
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
