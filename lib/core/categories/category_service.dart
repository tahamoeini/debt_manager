// Category service: manages custom categories for budgets and transactions
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/finance/models/finance_models.dart';

class CategoryService {
  static const _keyCustomCategories = 'custom_categories';

  // Default categories that come with the app
  static const List<String> defaultCategories = [
    'food',
    'utilities',
    'transport',
    'shopping',
    'rent',
    'entertainment',
  ];

  // Get all categories (default + custom)
  Future<List<String>> getAllCategories() async {
    final db = DatabaseHelper.instance;
    try {
      await _ensureMigrated();
      final rows = await db.getCategories();
      final names = rows.map((c) => c.name).toList();

      // Ensure default categories exist in DB; if missing, insert them.
      for (final d in defaultCategories) {
        if (!names.contains(d)) {
          await db.insertCategory(Category(
            name: d,
            type: 'expense',
            color: null,
            icon: null,
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }

      // Re-read after potential inserts
      final finalRows = await db.getCategories();
      return finalRows.map((c) => c.name).toList();
    } catch (_) {
      // If DB is unavailable, fall back to default+prefs
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyCustomCategories);
      final custom = <String>[];
      if (json != null) {
        try {
          final list = jsonDecode(json) as List<dynamic>;
          custom.addAll(list.cast<String>());
        } catch (_) {}
      }
      final all = [...defaultCategories, ...custom];
      return all.toSet().toList();
    }
  }

  // Get only custom categories
  Future<List<String>> getCustomCategories() async {
    try {
      await _ensureMigrated();
      final db = DatabaseHelper.instance;
      final rows = await db.getCategories();
      final names = rows
          .map((c) => c.name)
          .where((n) => !defaultCategories.contains(n))
          .toList();
      return names;
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyCustomCategories);
      if (json == null) return [];
      try {
        final list = jsonDecode(json) as List<dynamic>;
        return list.cast<String>();
      } catch (_) {
        return [];
      }
    }
  }

  // Add a new custom category
  Future<void> addCategory(String category) async {
    final trimmed = category.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    try {
      await _ensureMigrated();
      final db = DatabaseHelper.instance;
      final existing = await db.getCategories();
      if (existing.any((c) => c.name.toLowerCase() == trimmed)) {
        throw Exception('Category already exists');
      }
      await db.insertCategory(Category(
        name: trimmed,
        type: 'expense',
        color: null,
        icon: null,
        createdAt: DateTime.now().toIso8601String(),
      ));
      return;
    } catch (_) {
      // Fallback to prefs if DB unavailable
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyCustomCategories);
      final custom = <String>[];
      if (json != null) {
        try {
          final list = jsonDecode(json) as List<dynamic>;
          custom.addAll(list.cast<String>());
        } catch (_) {}
      }
      final allCategories = {...defaultCategories, ...custom};
      if (allCategories.contains(trimmed)) {
        throw Exception('Category already exists');
      }
      custom.add(trimmed);
      await _saveCustomCategories(custom);
    }
  }

  // Rename a custom category
  Future<void> renameCategory(String oldName, String newName) async {
    final trimmed = newName.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    try {
      await _ensureMigrated();
      final db = DatabaseHelper.instance;
      final rows = await db.getCategories();
      final found = rows.firstWhere(
          (c) => c.name.toLowerCase() == oldName.toLowerCase(),
          orElse: () => throw Exception('Category not found'));
      final conflict = rows.any((c) => c.name.toLowerCase() == trimmed);
      if (conflict) throw Exception('New category name already exists');
      await db.updateCategory(found.copyWith(name: trimmed));
      return;
    } catch (_) {
      // Fallback to prefs
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyCustomCategories);
      final custom = <String>[];
      if (json != null) {
        try {
          final list = jsonDecode(json) as List<dynamic>;
          custom.addAll(list.cast<String>());
        } catch (_) {}
      }
      final index = custom.indexOf(oldName.toLowerCase());
      if (index == -1) throw Exception('Category not found');
      final allCategories = {...defaultCategories, ...custom};
      if (allCategories.contains(trimmed)) {
        throw Exception('New category name already exists');
      }
      custom[index] = trimmed;
      await _saveCustomCategories(custom);
    }
  }

  // Delete a custom category
  Future<void> deleteCategory(String category) async {
    try {
      final db = DatabaseHelper.instance;
      final rows = await db.getCategories();
      Category? found;
      try {
        found = rows
            .firstWhere((c) => c.name.toLowerCase() == category.toLowerCase());
      } catch (_) {
        found = null;
      }
      if (found != null) {
        if (isDefaultCategory(found.name)) {
          throw Exception('Cannot delete default category');
        }
        await db.deleteCategory(found.id!);
        return;
      }
    } catch (_) {}

    final custom = await getCustomCategories();
    custom.remove(category.toLowerCase());
    await _saveCustomCategories(custom);
  }

  // Check if a category is a default (non-deletable) category
  bool isDefaultCategory(String category) {
    return defaultCategories.contains(category.toLowerCase());
  }

  Future<void> _saveCustomCategories(List<String> categories) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCustomCategories, jsonEncode(categories));
  }

  // Ensure any custom categories stored in SharedPreferences are migrated into DB.
  bool _migrated = false;
  Future<void> _ensureMigrated() async {
    if (_migrated) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_keyCustomCategories);
      if (json != null) {
        try {
          final list = jsonDecode(json) as List<dynamic>;
          final items = list.cast<String>();
          final db = DatabaseHelper.instance;
          final existing = await db.getCategories();
          final existingNames =
              existing.map((c) => c.name.toLowerCase()).toSet();
          for (final name in items) {
            final n = name.trim().toLowerCase();
            if (n.isEmpty) continue;
            if (!existingNames.contains(n) && !defaultCategories.contains(n)) {
              await db.insertCategory(Category(
                name: n,
                type: 'expense',
                color: null,
                icon: null,
                createdAt: DateTime.now().toIso8601String(),
              ));
            }
          }
        } catch (_) {}
        // Remove prefs key once attempted migration to avoid repeated work
        try {
          await prefs.remove(_keyCustomCategories);
        } catch (_) {}
      }
    } catch (_) {}
    _migrated = true;
  }
}
