import 'package:flutter/material.dart';

extension ColorWithValues on Color {
  /// Compatibility helper used across the codebase. Returns the same color
  /// with the provided alpha (0.0-1.0) applied.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final alphaValue = (alpha.clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(alphaValue, red, green, blue);
  }
}

extension MaterialColorWithValues on MaterialColor {
  Color withValues({double? alpha}) => shade500.withValues(alpha: alpha);
}
