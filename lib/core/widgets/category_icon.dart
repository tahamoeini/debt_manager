// Reusable category icon widget for visual category representation.
import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/category_colors.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
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

/// A widget for displaying a category icon with consistent styling.
/// Uses a CircleAvatar with category-specific color and icon.
/// 
/// Example usage:
/// ```dart
/// CategoryIcon(
///   category: 'food',
///   icon: Icons.restaurant,
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
  final Color? backgroundColor;

  /// Optional icon color
  final Color? iconColor;

  const CategoryIcon({
    super.key,
    this.category,
    required this.icon,
    this.size = AppDimensions.categoryIconSize,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    // Use category color if available, otherwise use theme color
    final bgColor = backgroundColor ?? 
        (category != null 
            ? colorForCategory(category, brightness: brightness)
            : theme.colorScheme.primaryContainer);
    
    final fgColor = iconColor ?? 
        (backgroundColor != null 
            ? _getContrastColor(backgroundColor!)
            : theme.colorScheme.onPrimaryContainer);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bgColor,
      child: Icon(
        icon,
        size: size * 0.5,
        color: fgColor,
      ),
    );
  }

  Color _getContrastColor(Color background) {
    // Calculate luminance and return black or white for contrast
    final luminance = background.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
}

/// A widget that combines a category icon with a label.
///
/// Example usage:
/// ```dart
/// CategoryIconWithLabel(
///   category: 'food',
///   icon: Icons.restaurant,
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

  /// Required icon
  final IconData icon;

  /// Optional custom color
  final Color? color;

  const CategoryIconWithLabel({
    super.key,
    this.category,
    required this.label,
    required this.icon,
    this.iconSize = 40.0,
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
          backgroundColor: color,
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

/// A simplified category badge that shows just a colored circle indicator
class CategoryBadge extends StatelessWidget {
  final String? category;
  final double size;
  final Color? color;

  const CategoryBadge({
    super.key,
    this.category,
    this.size = 12.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    final badgeColor = color ?? 
        (category != null 
            ? colorForCategory(category, brightness: brightness)
            : theme.colorScheme.primary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
