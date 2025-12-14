// Automation rules repository: manages automation rules storage and application
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/automation/models/automation_rule.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AutomationRulesRepository {
  final _db = DatabaseHelper.instance;

  Future<int> insertRule(AutomationRule rule) async {
    if (kIsWeb) {
      // Web fallback: rules won't be persisted but can be used in-memory
      return 0;
    }

    final db = await _db.database;
    return await db.insert('automation_rules', rule.toMap());
  }

  Future<int> updateRule(AutomationRule rule) async {
    if (rule.id == null) throw ArgumentError('AutomationRule.id is null');
    if (kIsWeb) return 0;

    final db = await _db.database;
    return await db.update(
      'automation_rules',
      rule.toMap(),
      where: 'id = ?',
      whereArgs: [rule.id],
    );
  }

  Future<int> deleteRule(int id) async {
    if (kIsWeb) return 0;

    final db = await _db.database;
    return await db.delete(
      'automation_rules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<AutomationRule>> getAllRules() async {
    if (kIsWeb) return [];

    final db = await _db.database;
    final rows = await db.query('automation_rules', orderBy: 'created_at DESC');
    return rows.map((r) => AutomationRule.fromMap(r)).toList();
  }

  Future<List<AutomationRule>> getEnabledRules() async {
    if (kIsWeb) return [];

    final db = await _db.database;
    final rows = await db.query(
      'automation_rules',
      where: 'enabled = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => AutomationRule.fromMap(r)).toList();
  }

  // Apply all enabled rules to a transaction (payee, description, amount)
  // Returns suggested category/tag based on matching rules
  Future<Map<String, String?>> applyRules(
    String? payee,
    String? description,
    int? amount,
  ) async {
    final result = <String, String?>{'category': null, 'tag': null};

    // First check built-in patterns
    final builtInCategory = BuiltInCategories.suggestCategory(
      payee,
      description,
    );
    if (builtInCategory != null) {
      result['category'] = builtInCategory;
    }

    // Then check custom rules (which take precedence)
    final rules = await getEnabledRules();

    for (final rule in rules) {
      if (rule.matches(payee, description, amount)) {
        final action = rule.applyAction();
        if (action['action'] == 'set_category') {
          result['category'] = action['value'] as String?;
        } else if (action['action'] == 'set_tag') {
          result['tag'] = action['value'] as String?;
        }

        // First matching rule wins
        break;
      }
    }

    return result;
  }
}
