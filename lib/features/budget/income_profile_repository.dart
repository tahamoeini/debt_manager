import 'package:debt_manager/core/db/database_helper.dart';

class IncomeProfileRepository {
  final _db = DatabaseHelper.instance;

  Future<int> setProfile(int? counterpartyId, String mode,
      {String? label, required String createdAt}) async {
    final db = await _db.database;
    final map = {
      'counterparty_id': counterpartyId,
      'mode': mode,
      'label': label,
      'created_at': createdAt,
    };
    return await db.insert('income_profiles', map);
  }

  Future<int> updateProfile(int id, Map<String, dynamic> changes) async {
    final db = await _db.database;
    return await db
        .update('income_profiles', changes, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Map<String, dynamic>>> getProfiles() async {
    final db = await _db.database;
    return await db.query('income_profiles', orderBy: 'counterparty_id ASC');
  }

  Future<String?> getModeForCounterparty(int counterpartyId) async {
    final db = await _db.database;
    final rows = await db.query('income_profiles',
        where: 'counterparty_id = ?', whereArgs: [counterpartyId], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['mode'] as String?;
  }
}
