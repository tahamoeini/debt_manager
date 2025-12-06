/// Category Icon Widget
/// 
/// A reusable widget for displaying category icons with consistent styling.
/// Uses the centralized category icon/color mapping.

import 'package:flutter/material.dart';
import 'category_icons.dart';
import 'design_system.dart';

/// Display style for the category icon
enum CategoryIconStyle {
  /// Icon only, no background
  icon,
  
  /// Icon in a circular avatar
  circle,
  
  /// Icon in a rounded square
  square,
  
  /// Small dot indicator (no icon)
  dot,
}

/// A widget that displays a category icon with consistent styling
class CategoryIcon extends StatelessWidget {
  /// The category name/tag
  final String? category;

  /// The display style
  final CategoryIconStyle style;

  /// Size of the icon/container
  final double? size;

  /// Optional custom icon (overrides category lookup)
  final IconData? customIcon;

  /// Optional custom color (overrides category lookup)
  final Color? customColor;

  const CategoryIcon({
    super.key,
    required this.category,
    this.style = CategoryIconStyle.circle,
    this.size,
    this.customIcon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    
    final iconData = customIcon ?? CategoryIcons.getIcon(category);
    final color = customColor ?? CategoryIcons.getColor(category, brightness: brightness);
    
    final effectiveSize = size ?? AppIconSize.lg;
    final iconSize = effectiveSize * 0.6;

    switch (style) {
      case CategoryIconStyle.icon:
        return Icon(
          iconData,
          size: effectiveSize,
          color: color,
        );

      case CategoryIconStyle.circle:
        return Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            iconData,
            size: iconSize,
            color: color,
          ),
        );

      case CategoryIconStyle.square:
        return Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            iconData,
            size: iconSize,
            color: color,
          ),
        );

      case CategoryIconStyle.dot:
        return Container(
          width: effectiveSize,
          height: effectiveSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

/// A widget that displays a category chip (icon + label)
class CategoryChip extends StatelessWidget {
  /// The category name/tag
  final String category;

  /// Whether to show the icon
  final bool showIcon;

  /// Optional custom color
  final Color? customColor;

  /// Optional tap handler
  final VoidCallback? onTap;

  /// Whether this chip is selected
  final bool isSelected;

  const CategoryChip({
    super.key,
    required this.category,
    this.showIcon = true,
    this.customColor,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final brightness = theme.brightness;
    
    final color = customColor ?? CategoryIcons.getColor(category, brightness: brightness);
    final backgroundColor = isSelected
        ? color.withOpacity(0.2)
        : colorScheme.surface;
    final borderColor = isSelected
        ? color
        : colorScheme.outline.withOpacity(0.3);

    final content = Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              CategoryIcons.getIcon(category),
              size: AppIconSize.sm,
              color: color,
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            category,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: content,
      );
    }

    return content;
  }
}
