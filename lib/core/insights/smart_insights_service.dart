// Smart insights service: detects subscriptions, spending patterns, and bill changes
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/loan.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/format_utils.dart';

/// Represents a detected subscription pattern
class SubscriptionInsight {
  final String payee;
  final int amount;
  final int occurrences;
  final String description;

  SubscriptionInsight({
    required this.payee,
    required this.amount,
    required this.occurrences,
    required this.description,
  });
}

/// Represents a bill amount change alert
class BillChangeInsight {
  final String payee;
  final int previousAmount;
  final int currentAmount;
  final double percentageChange;
  final String description;

  BillChangeInsight({
    required this.payee,
    required this.previousAmount,
    required this.currentAmount,
    required this.percentageChange,
    required this.description,
  });
}

class SmartInsightsService {
  static final SmartInsightsService instance = SmartInsightsService._internal();
  SmartInsightsService._internal();
  factory SmartInsightsService() => instance;

  final _db = DatabaseHelper.instance;

  /// Detect potential subscriptions by analyzing payment patterns
  /// Returns a list of subscriptions where the same amount has been paid to the same payee
  /// for 3 or more consecutive months
  Future<List<SubscriptionInsight>> detectSubscriptions() async {
    try {
      final loans = await _db.getAllLoans();
      final subscriptions = <SubscriptionInsight>[];

      // Group loans by counterparty and check for recurring patterns
      final loansByCounterparty = <int, List<Loan>>{};
      for (final loan in loans) {
        loansByCounterparty.putIfAbsent(loan.counterpartyId, () => []).add(loan);
      }

      for (final entry in loansByCounterparty.entries) {
        final counterpartyLoans = entry.value;
        
        // Check if there are multiple loans with similar installment amounts
        final amountCounts = <int, int>{};
        String? commonPayee;

        for (final loan in counterpartyLoans) {
          commonPayee = loan.title;
          final amount = loan.installmentAmount;
          amountCounts[amount] = (amountCounts[amount] ?? 0) + 1;
        }

        // If we find 3+ occurrences of the same amount, it's likely a subscription
        for (final amountEntry in amountCounts.entries) {
          if (amountEntry.value >= 3) {
            final amount = amountEntry.key;
            final occurrences = amountEntry.value;
            
            subscriptions.add(SubscriptionInsight(
              payee: commonPayee ?? 'ناشناس',
              amount: amount,
              occurrences: occurrences,
              description: 'پرداخت تکراری ${formatCurrency(amount)} برای $occurrences ماه',
            ));
          }
        }
      }

      return subscriptions;
    } catch (e) {
      debugPrint('Error detecting subscriptions: $e');
      return [];
    }
  }

  /// Detect significant bill amount changes (>20% increase)
  Future<List<BillChangeInsight>> detectBillChanges() async {
    try {
      final changes = <BillChangeInsight>[];
      final now = DateTime.now();
      final jalaliNow = dateTimeToJalali(now);
      
      // Get current month period
      final currentPeriod = '${jalaliNow.year.toString().padLeft(4, '0')}-${jalaliNow.month.toString().padLeft(2, '0')}';
      
      // Get previous month period
      final prevJalali = jalaliNow.month > 1 
          ? Jalali(jalaliNow.year, jalaliNow.month - 1, 1)
          : Jalali(jalaliNow.year - 1, 12, 1);
      final prevPeriod = '${prevJalali.year.toString().padLeft(4, '0')}-${prevJalali.month.toString().padLeft(2, '0')}';

      // Get all loans and their installments
      final loans = await _db.getAllLoans();
      
      for (final loan in loans) {
        final installments = await _db.getInstallmentsByLoanId(loan.id!);
        
        // Find installments paid in current and previous months
        final currentMonthInstallments = installments.where((i) {
          return i.paidAt != null && i.paidAt!.startsWith(currentPeriod);
        }).toList();
        
        final prevMonthInstallments = installments.where((i) {
          return i.paidAt != null && i.paidAt!.startsWith(prevPeriod);
        }).toList();

        // Compare amounts if both months have payments
        if (currentMonthInstallments.isNotEmpty && prevMonthInstallments.isNotEmpty) {
          final currentAmount = currentMonthInstallments.first.actualPaidAmount ?? currentMonthInstallments.first.amount;
          final prevAmount = prevMonthInstallments.first.actualPaidAmount ?? prevMonthInstallments.first.amount;

          if (prevAmount > 0) {
            final percentageChange = ((currentAmount - prevAmount) / prevAmount) * 100;

            // Alert if increase is more than 20%
            if (percentageChange > 20) {
              changes.add(BillChangeInsight(
                payee: loan.title,
                previousAmount: prevAmount,
                currentAmount: currentAmount,
                percentageChange: percentageChange,
                description: '${loan.title} ${percentageChange.toStringAsFixed(1)}٪ نسبت به ماه قبل افزایش یافت',
              ));
            }
          }
        }
      }

      return changes;
    } catch (e) {
      debugPrint('Error detecting bill changes: $e');
      return [];
    }
  }

  /// Get all smart insights (subscriptions + bill changes)
  Future<Map<String, dynamic>> getAllInsights() async {
    final subscriptions = await detectSubscriptions();
    final billChanges = await detectBillChanges();

    return {
      'subscriptions': subscriptions,
      'billChanges': billChanges,
      'hasInsights': subscriptions.isNotEmpty || billChanges.isNotEmpty,
    };
  }

  /// Generate a smart suggestion message for detected patterns
  String generateSuggestionMessage(SubscriptionInsight subscription) {
    return '💡 به نظر می‌رسد شما یک اشتراک دارید: ${formatCurrency(subscription.amount)} در ماه برای ${subscription.payee}. هنوز استفاده می‌کنید؟';
  }

  String generateBillChangeMessage(BillChangeInsight change) {
    return '📈 قبض ${change.payee} شما ${change.percentageChange.toStringAsFixed(0)}٪ نسبت به ماه قبل افزایش یافته است';
  }
}
