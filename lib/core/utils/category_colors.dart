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
  // In dark mode, increase lightness for visibility
  if (brightness == Brightness.dark) {
    return HSLColor.fromColor(c).withLightness(
      (HSLColor.fromColor(c).lightness + 0.25).clamp(0.0, 1.0),
    ).toColor();
  }
  return c;
}
