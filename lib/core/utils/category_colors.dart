import 'package:flutter/material.dart';

// Small palette for categories. Keys should match lowercased tags used in data.
const Map<String, Color> _categoryMap = {
  'food': Color(0xFF2E7D32), // green
  'utilities': Color(0xFF1565C0), // blue
  'transport': Color(0xFFF57C00), // orange
  'shopping': Color(0xFF6A1B9A), // purple
  'rent': Color(0xFF00796B), // teal
  'entertainment': Color(0xFFD84315), // deep orange
};

Color colorForCategory(String? tag, {required Brightness brightness}) {
  if (tag == null || tag.trim().isEmpty) return Colors.grey;
  final key = tag.toLowerCase().trim();
  final c = _categoryMap[key] ?? Colors.grey;
  // Adjust lightness slightly to ensure visibility on different backgrounds.
  final hsl = HSLColor.fromColor(c);
  if (brightness == Brightness.dark) {
    final lighter = hsl.withLightness((hsl.lightness + 0.28).clamp(0.0, 1.0));
    // If still too dark for dark backgrounds, bump more
    if (lighter.toColor().computeLuminance() < 0.12) {
      return hsl.withLightness((hsl.lightness + 0.45).clamp(0.0, 1.0)).toColor();
    }
    return lighter.toColor();
  } else {
    // For light backgrounds, avoid colors that are too pale (low contrast).
    if (hsl.lightness > 0.9) {
      return hsl.withLightness(0.75).toColor();
    }
    return c;
  }
}
