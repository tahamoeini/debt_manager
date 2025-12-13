import 'package:flutter/material.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

/// A thermometer-style progress indicator showing debt payoff progress.
/// Shows the percentage of a loan that has been paid.
class DebtThermometer extends StatelessWidget {
  /// The name of the loan
  final String title;

  /// The counterparty name (if applicable)
  final String? counterpartyName;

  /// The total loan amount
  final int totalAmount;

  /// The amount paid so far
  final int amountPaid;

  /// Optional callback when tapped
  final VoidCallback? onTap;

  /// Height of the thermometer. Defaults to 200.
  final double height;

  /// Show detailed labels
  final bool showDetails;

  const DebtThermometer({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.amountPaid,
    this.counterpartyName,
    this.onTap,
    this.height = 200,
    this.showDetails = true,
  });

  double get _fillPercentage =>
      totalAmount > 0 ? (amountPaid / totalAmount).clamp(0.0, 1.0) : 0.0;

  int get _remainingAmount => (totalAmount - amountPaid).clamp(0, totalAmount);

  /// Get color based on fill percentage
  Color _getColor(BuildContext context) {
    if (_fillPercentage >= 0.9) {
      return Colors.green.shade600; // Almost done
    } else if (_fillPercentage >= 0.5) {
      return Colors.blue.shade600; // Halfway
    } else if (_fillPercentage >= 0.25) {
      return Colors.orange.shade600; // Started
    } else {
      return Colors.red.shade600; // Just started
    }
  }

  @override
  Widget build(BuildContext context) {
    final fillColor = _getColor(context);
    final fillHeight = height * _fillPercentage;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (counterpartyName != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            counterpartyName!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Percentage badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: fillColor.withAlpha(25),
                      border: Border.all(color: fillColor, width: 1.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(_fillPercentage * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: fillColor,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Thermometer
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Thermometer bulb (small circle at bottom)
                  SizedBox(
                    width: 40,
                    height: height + 20,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Thermometer tube
                        Expanded(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: 24,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey.shade400,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Stack(
                                alignment: Alignment.bottomCenter,
                                children: [
                                  // Background
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  // Fill
                                  Container(
                                    height: fillHeight,
                                    decoration: BoxDecoration(
                                      color: fillColor,
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                    ),
                                  ),
                                  // Milestone markers
                                  ...List.generate(4, (index) {
                                    final position = (height / 4) * (4 - index);
                                    return Positioned(
                                      top: position,
                                      child: Container(
                                        width: 28,
                                        height: 1,
                                        color: Colors.grey.shade300,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Bulb
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 2,
                            ),
                            color: Colors.grey.shade100,
                          ),
                          child: Center(
                            child: Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: fillColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Details
                  if (showDetails)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'پرداخت شده',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              Text(
                                formatCurrency(amountPaid),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: fillColor,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'باقی مانده',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                              ),
                              Text(
                                formatCurrency(_remainingAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.orange.shade600,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'کل',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Text(
                                formatCurrency(totalAmount),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
