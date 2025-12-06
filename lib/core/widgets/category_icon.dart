// Reusable category icon widget for visual category representation.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

/// Mapping of category names to icons.
/// Extend this map to add more categories.
const Map<String, IconData> _categoryIcons = {
  'food': Icons.restaurant,
  'utilities': Icons.bolt,
  'transport': Icons.directions_car,
  'shopping': Icons.shopping_bag,
  'rent': Icons.home,
  'entertainment': Icons.movie,
  'health': Icons.medical_services,
  'education': Icons.school,
  'savings': Icons.savings,
  'general': Icons.category,
};

/// A reusable widget for displaying category icons with consistent styling.
///
/// Each category is represented with:
/// - A color-coded background (from category_colors.dart)
/// - An appropriate icon
/// - Circular avatar style
///
/// Example usage:
/// ```dart
/// CategoryIcon(
///   category: 'food',
///   size: 40,
/// )
/// ```
class CategoryIcon extends StatelessWidget {
  /// Category name (should match keys in _categoryIcons map)
  final String? category;

  /// Size of the icon container (diameter of the circle)
  final double size;

  /// Optional custom icon to override default
  final IconData? icon;

  /// Optional custom color to override category color
  final Color? color;

  const CategoryIcon({
    super.key,
    this.category,
    this.size = 40.0,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;

    // Get category-specific icon and color
    final categoryKey = category?.toLowerCase().trim() ?? 'general';
    final IconData displayIcon = icon ?? _categoryIcons[categoryKey] ?? Icons.category;
    final Color displayColor = color ?? colorForCategory(category, brightness: brightness);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: displayColor.withOpacity(0.2),
      child: Icon(
        displayIcon,
        size: size * 0.5, // Icon size is 50% of container size
        color: displayColor,
      ),
    );
  }
}

/// A widget that combines a category icon with a label.
///
/// Example usage:
/// ```dart
/// CategoryIconWithLabel(
///   category: 'food',
///   label: 'Food & Dining',
/// )
/// ```
class CategoryIconWithLabel extends StatelessWidget {
  /// Category name
  final String? category;

  /// Label text to display below icon
  final String label;

  /// Size of the icon
  final double iconSize;

  /// Optional custom icon
  final IconData? icon;

  /// Optional custom color
  final Color? color;

  const CategoryIconWithLabel({
    super.key,
    this.category,
    required this.label,
    this.iconSize = 40.0,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CategoryIcon(
          category: category,
          size: iconSize,
          icon: icon,
          color: color,
        ),
        const SizedBox(height: AppConstants.spaceXSmall),
        Text(
          label,
          style: textTheme.bodySmall,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
