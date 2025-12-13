import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

/// A heatmap widget displaying spending by category over multiple months.
/// The matrix shows categories as rows and months as columns, with intensity
/// representing spending amount.
class CategoryHeatmap extends StatelessWidget {
  /// Map of category names to lists of monthly spending values.
  /// Key: category name (e.g., "Food", "Transport")
  /// Value: list of spending values for each month (oldest to newest)
  final Map<String, List<int>> categoryMonthlySpending;

  /// List of month labels (e.g., ["Far", "Ord", "Kho", "Dey", "Bah", "Esf"])
  final List<String> monthLabels;

  /// Optional title
  final String? title;

  /// Maximum value for color normalization (if null, uses max value in data)
  final int? maxValue;

  const CategoryHeatmap({
    super.key,
    required this.categoryMonthlySpending,
    required this.monthLabels,
    this.title,
    this.maxValue,
  });

  /// Calculate color based on normalized value (0.0 to 1.0)
  Color _getColor(double normalized) {
    // Green (low spending) -> Yellow -> Red (high spending)
    if (normalized < 0.5) {
      // Green to Yellow
      final t = normalized * 2;
      return Color.lerp(
        Colors.green.shade100,
        Colors.yellow.shade300,
        t,
      )!;
    } else {
      // Yellow to Red
      final t = (normalized - 0.5) * 2;
      return Color.lerp(
        Colors.yellow.shade300,
        Colors.red.shade400,
        t,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (categoryMonthlySpending.isEmpty || monthLabels.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'داده‌ای برای نمایش وجود ندارد',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
      );
    }

    // Find max value
    int maxVal = maxValue ?? 0;
    for (final monthValues in categoryMonthlySpending.values) {
      for (final val in monthValues) {
        if (val > maxVal) maxVal = val;
      }
    }
    if (maxVal == 0) maxVal = 1; // Avoid division by zero

    final categories = categoryMonthlySpending.keys.toList();
    const cellSize = 48.0;
    const cellPadding = 4.0;

    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null) ...[
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category labels column
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Empty cell for alignment with month labels
                      SizedBox(
                        height: cellSize + (cellPadding * 2),
                      ),
                      // Category names
                      ...categories.map((category) {
                        return SizedBox(
                          height: cellSize + (cellPadding * 2),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 100),
                                child: Text(
                                  category,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                  const SizedBox(width: 8),
                  // Heatmap grid
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Month labels row
                      Row(
                        children: monthLabels.map((label) {
                          return SizedBox(
                            width: cellSize + (cellPadding * 2),
                            height: cellSize + (cellPadding * 2),
                            child: Center(
                              child: Text(
                                label,
                                style: Theme.of(context).textTheme.labelSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      // Heatmap rows
                      ...categories.asMap().entries.map((entry) {
                        final monthValues = categoryMonthlySpending[entry.value]!;
                        return Row(
                          children: List.generate(monthLabels.length, (monthIndex) {
                            final value = monthIndex < monthValues.length
                                ? monthValues[monthIndex]
                                : 0;
                            final normalized = value / maxVal;
                            final color = _getColor(normalized);

                            return Padding(
                              padding: const EdgeInsets.all(cellPadding),
                              child: Tooltip(
                                message:
                                    '${entry.value} - ${monthLabels[monthIndex]}\n${formatCurrency(value)}',
                                child: Container(
                                  width: cellSize,
                                  height: cellSize,
                                  decoration: BoxDecoration(
                                    color: color,
                                    border: Border.all(
                                      color: Colors.grey.shade300,
                                      width: 0.5,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Center(
                                    child: value > 0
                                        ? Text(
                                            formatCurrency(value),
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall
                                                ?.copyWith(
                                                  color: normalized > 0.5
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  fontSize: 9,
                                                ),
                                            textAlign: TextAlign.center,
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Legend
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'کم',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade300,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'متوسط',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(width: 24),
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.red.shade400,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'زیاد',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
