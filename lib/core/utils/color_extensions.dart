import 'package:flutter/material.dart';

extension ColorWithValues on Color {
  /// Compatibility helper used across the codebase. Returns the same color
  /// with the provided alpha (0.0-1.0) applied.
  Color withValues({double? alpha}) {
    if (alpha == null) return this;
    return withOpacity(alpha.clamp(0.0, 1.0));
  }
}

extension MaterialColorWithValues on MaterialColor {
  Color withValues({double? alpha}) => this.shade500.withValues(alpha: alpha);
}
