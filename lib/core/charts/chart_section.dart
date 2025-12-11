import 'package:flutter/material.dart';

/// A reusable chart section that provides title, optional legend,
/// consistent padding, and empty state handling. Accepts a child
/// chart widget and optional `forecast` data in the future.
class ChartSection extends StatelessWidget {
  const ChartSection(
      {super.key,
      required this.title,
      required this.child,
      this.legend,
      this.emptyText});

  final String title;
  final Widget child;
  final Widget? legend;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (legend != null) legend!,
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 160,
              child: child,
            ),
            if (emptyText != null) ...[
              const SizedBox(height: 8),
              Text(emptyText!, style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
