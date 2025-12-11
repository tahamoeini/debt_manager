import 'package:flutter/material.dart';

class ChartStyles {
  static const double sectionHeight = 160;
  static TextStyle legendText(BuildContext context) => Theme.of(context).textTheme.bodySmall ?? const TextStyle(fontSize: 12);
}
