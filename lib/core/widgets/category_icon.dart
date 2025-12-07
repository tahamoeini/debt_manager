import 'package:flutter/material.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';
import 'package:debt_manager/core/utils/category_colors.dart';

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
  final String? category;
  final IconData icon;
  final double size;
  final Color? backgroundColor;
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
