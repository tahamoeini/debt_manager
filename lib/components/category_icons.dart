// Component: Category Icons and Colors
// Category Icons and Colors
//
// Centralized mapping of category names to their visual representation
// (icons and colors). This ensures consistency across the app.

import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/category_colors.dart' as legacy;

// Category icon and color data
class CategoryData {
  final IconData icon;
  final Color color;

  const CategoryData({required this.icon, required this.color});
}

// Map of category names to their visual representation
class CategoryIcons {
  CategoryIcons._();

  static const Map<String, CategoryData> _categoryMap = {
    'food': CategoryData(
      icon: Icons.restaurant_outlined,
      color: Color(0xFF2E7D32), // green
    ),
    'groceries': CategoryData(
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFF2E7D32), // green
    ),
    'utilities': CategoryData(
      icon: Icons.lightbulb_outline,
      color: Color(0xFF1565C0), // blue
    ),
    'transport': CategoryData(
      icon: Icons.directions_car_outlined,
      color: Color(0xFFF57C00), // orange
    ),
    'shopping': CategoryData(
      icon: Icons.shopping_bag_outlined,
      color: Color(0xFF6A1B9A), // purple
    ),
    'rent': CategoryData(
      icon: Icons.home_outlined,
      color: Color(0xFF00796B), // teal
    ),
    'entertainment': CategoryData(
      icon: Icons.movie_outlined,
      color: Color(0xFFD84315), // deep orange
    ),
    'health': CategoryData(
      icon: Icons.local_hospital_outlined,
      color: Color(0xFFE91E63), // pink
    ),
    'education': CategoryData(
      icon: Icons.school_outlined,
      color: Color(0xFF3F51B5), // indigo
    ),
    'travel': CategoryData(
      icon: Icons.flight_outlined,
      color: Color(0xFF00ACC1), // cyan
    ),
    'bills': CategoryData(
      icon: Icons.receipt_outlined,
      color: Color(0xFF1565C0), // blue
    ),
    'salary': CategoryData(
      icon: Icons.attach_money_outlined,
      color: Color(0xFF2E7D32), // green
    ),
    'investment': CategoryData(
      icon: Icons.trending_up_outlined,
      color: Color(0xFF1976D2), // blue
    ),
    'gift': CategoryData(
      icon: Icons.card_giftcard_outlined,
      color: Color(0xFF9C27B0), // purple
    ),
    'other': CategoryData(
      icon: Icons.category_outlined,
      color: Color(0xFF757575), // grey
    ),
  };

  // Default category data when no match is found
  static const CategoryData _defaultCategory = CategoryData(
    icon: Icons.help_outline,
    color: Color(0xFF9E9E9E), // grey
  );

  // Get category icon for a given category name
  static IconData getIcon(String? category) {
    if (category == null || category.trim().isEmpty) {
      return _defaultCategory.icon;
    }
    final key = category.toLowerCase().trim();
    return _categoryMap[key]?.icon ?? _defaultCategory.icon;
  }

  // Get category color for a given category name
  // Uses the existing colorForCategory function for consistency
  static Color getColor(String? category, {required Brightness brightness}) {
    return legacy.colorForCategory(category, brightness: brightness);
  }

  // Get category data (icon + color) for a given category name
  static CategoryData getData(String? category) {
    if (category == null || category.trim().isEmpty) {
      return _defaultCategory;
    }
    final key = category.toLowerCase().trim();
    return _categoryMap[key] ?? _defaultCategory;
  }

  // Get all available categories
  static List<String> get allCategories => _categoryMap.keys.toList();
}
