import '../models/account.dart';
import '../../../core/db/database_helper.dart';

class AccountsRepository {
  final DatabaseHelper _db;

  AccountsRepository(this._db);

  /// Get all accounts
  Future<List<Account>> listAccounts() async {
    final database = await _db.database;
    final results = await database.query(
      'accounts',
      orderBy: 'created_at DESC',
    );

    return results
        .map((row) => Account(
              id: row['id'] as int,
              name: row['name'] as String,
              type: AccountType.values[int.parse(row['type'] as String)],
              balance: (row['balance'] as num).toDouble(),
              notes: row['notes'] as String?,
              createdAt: row['created_at'] as String,
            ))
        .toList();
  }

  /// Get account by ID
  Future<Account?> getAccountById(int id) async {
    final database = await _db.database;
    final results = await database.query(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;

    final row = results.first;
    return Account(
      id: row['id'] as int,
      name: row['name'] as String,
      type: AccountType.values[int.parse(row['type'] as String)],
      balance: (row['balance'] as num).toDouble(),
      notes: row['notes'] as String?,
      createdAt: row['created_at'] as String,
    );
  }

  /// Insert a new account
  Future<int> insertAccount(Account account) async {
    final database = await _db.database;
    return await database.insert(
      'accounts',
      {
        'name': account.name,
        'type': account.type.index.toString(),
        'balance': account.balance.toInt(),
        'notes': account.notes,
        'created_at': account.createdAt,
      },
    );
  }

  /// Update an account
  Future<void> updateAccount(Account account) async {
    final database = await _db.database;
    await database.update(
      'accounts',
      {
        'name': account.name,
        'type': account.type.index.toString(),
        'balance': account.balance.toInt(),
        'notes': account.notes,
      },
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  /// Delete an account
  Future<void> deleteAccount(int id) async {
    final database = await _db.database;
    await database.delete(
      'accounts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update account balance (used by transaction/payment flows)
  Future<void> updateBalance(int accountId, double newBalance) async {
    final database = await _db.database;
    await database.update(
      'accounts',
      {
        'balance': newBalance.toInt(),
      },
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
