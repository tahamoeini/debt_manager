import 'package:flutter/material.dart';

extension ColorWithValues on Color {
  /// Compatibility helper used across the codebase. Returns the same color
  /// with the provided alpha (0.0-1.0) applied.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    final alphaValue = (alpha.clamp(0.0, 1.0) * 255).round();
    final r = ((this.r * 255.0).round()).clamp(0, 255).toInt();
    final g = ((this.g * 255.0).round()).clamp(0, 255).toInt();
    final b = ((this.b * 255.0).round()).clamp(0, 255).toInt();
    return Color.fromARGB(alphaValue, r, g, b);
  }
}

extension MaterialColorWithValues on MaterialColor {
  Color withValues({double? alpha}) => shade500.withValues(alpha: alpha);
}
