// Category service: manages custom categories for budgets and transactions
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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
    final custom = await getCustomCategories();
    final all = [...defaultCategories, ...custom];
    // Remove duplicates while preserving order
    return all.toSet().toList();
  }

  // Get only custom categories
  Future<List<String>> getCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyCustomCategories);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list.cast<String>();
  }

  // Add a new custom category
  Future<void> addCategory(String category) async {
    final trimmed = category.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    final custom = await getCustomCategories();
    // Combine all categories and check for duplicates more efficiently
    final allCategories = {...defaultCategories, ...custom};
    if (allCategories.contains(trimmed)) {
      throw Exception('Category already exists');
    }

    custom.add(trimmed);
    await _saveCustomCategories(custom);
  }

  // Rename a custom category
  Future<void> renameCategory(String oldName, String newName) async {
    final trimmed = newName.trim().toLowerCase();
    if (trimmed.isEmpty) return;

    final custom = await getCustomCategories();
    final index = custom.indexOf(oldName.toLowerCase());

    if (index == -1) {
      throw Exception('Category not found');
    }

    // Check if new name conflicts with any existing category
    final allCategories = {...defaultCategories, ...custom};
    if (allCategories.contains(trimmed)) {
      throw Exception('New category name already exists');
    }

    custom[index] = trimmed;
    await _saveCustomCategories(custom);
  }

  // Delete a custom category
  Future<void> deleteCategory(String category) async {
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
}
