// Smart insights service: detects subscriptions, spending patterns, and bill changes
import 'package:flutter/foundation.dart' show debugPrint, compute;
import 'package:shamsi_date/shamsi_date.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/core/utils/format_utils.dart';
import 'package:debt_manager/core/compute/smart_insights_compute.dart';

// Represents a detected subscription pattern
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

// Represents a bill amount change alert
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

  // Detect potential subscriptions by analyzing payment patterns
  // Returns a list of subscriptions where similar amounts have been paid to the
  // same payee in multiple months. Uses an isolate for heavy work and allows
  // small amount variance to detect subscription 'creep'.
  Future<List<SubscriptionInsight>> detectSubscriptions() async {
    try {
      final loans = await _db.getAllLoans();
      final loanMaps = loans.map((l) => l.toMap()).toList();
      final loanIds = loans.map((e) => e.id).whereType<int>().toList();
      final grouped = loanIds.isNotEmpty
          ? await _db.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};
      final allInstallments = grouped.values.expand((l) => l).toList();
      final instMaps = allInstallments.map((i) => i.toMap()).toList();

      try {
        final rows =
            await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
          (msg) => computeDetectSubscriptions(
            List<Map<String, dynamic>>.from(msg['loans'] as List),
            List<Map<String, dynamic>>.from(msg['insts'] as List),
          ),
          {'loans': loanMaps, 'insts': instMaps},
        );

        return rows
            .map(
              (r) => SubscriptionInsight(
                payee: r['payee'] as String? ?? 'ناشناس',
                amount: r['amount'] as int? ?? 0,
                occurrences: r['occurrences'] as int? ?? 0,
                description: r['description'] as String? ?? '',
              ),
            )
            .toList();
      } catch (e) {
        // fallback: run on main isolate
        final rows = computeDetectSubscriptions(loanMaps, instMaps);
        return rows
            .map(
              (r) => SubscriptionInsight(
                payee: r['payee'] as String? ?? 'ناشناس',
                amount: r['amount'] as int? ?? 0,
                occurrences: r['occurrences'] as int? ?? 0,
                description: r['description'] as String? ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error detecting subscriptions: $e');
      return [];
    }
  }

  // Detect significant bill amount changes (>20% increase)
  Future<List<BillChangeInsight>> detectBillChanges() async {
    try {
      final now = DateTime.now();
      final jalaliNow = dateTimeToJalali(now);

      // Get current month period
      final currentPeriod =
          '${jalaliNow.year.toString().padLeft(4, '0')}-${jalaliNow.month.toString().padLeft(2, '0')}';

      // Get previous month period
      final prevJalali = jalaliNow.month > 1
          ? Jalali(jalaliNow.year, jalaliNow.month - 1, 1)
          : Jalali(jalaliNow.year - 1, 12, 1);
      final prevPeriod =
          '${prevJalali.year.toString().padLeft(4, '0')}-${prevJalali.month.toString().padLeft(2, '0')}';

      final loans = await _db.getAllLoans();
      final loanMaps = loans.map((l) => l.toMap()).toList();
      final loanIds = loans.map((e) => e.id).whereType<int>().toList();
      final grouped = loanIds.isNotEmpty
          ? await _db.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};
      final allInstallments = grouped.values.expand((l) => l).toList();
      final instMaps = allInstallments.map((i) => i.toMap()).toList();

      try {
        final rows =
            await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
          billChangeEntry,
          {
            'loans': loanMaps,
            'insts': instMaps,
            'current': currentPeriod,
            'prev': prevPeriod,
          },
        );

        return rows
            .map(
              (r) => BillChangeInsight(
                payee: r['payee'] as String? ?? 'ناشناس',
                previousAmount: r['previousAmount'] as int? ?? 0,
                currentAmount: r['currentAmount'] as int? ?? 0,
                percentageChange: r['percentageChange'] as double? ?? 0.0,
                description: r['description'] as String? ?? '',
              ),
            )
            .toList();
      } catch (e) {
        final rows = computeDetectBillChanges(
          loanMaps,
          instMaps,
          currentPeriod,
          prevPeriod,
        );
        return rows
            .map(
              (r) => BillChangeInsight(
                payee: r['payee'] as String? ?? 'ناشناس',
                previousAmount: r['previousAmount'] as int? ?? 0,
                currentAmount: r['currentAmount'] as int? ?? 0,
                percentageChange: r['percentageChange'] as double? ?? 0.0,
                description: r['description'] as String? ?? '',
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error detecting bill changes: $e');
      return [];
    }
  }

  // Anomaly detection: detect categories (loan titles) where current month
  // spending is significantly higher than the rolling average (e.g., >3x).
  Future<List<Map<String, dynamic>>> detectAnomalies({
    int monthsBack = 6,
  }) async {
    try {
      final loans = await _db.getAllLoans();
      final loanMaps = loans.map((l) => l.toMap()).toList();
      final loanIds = loans.map((e) => e.id).whereType<int>().toList();
      final grouped = loanIds.isNotEmpty
          ? await _db.getInstallmentsGroupedByLoanId(loanIds)
          : <int, List<Installment>>{};
      final allInstallments = grouped.values.expand((l) => l).toList();
      final instMaps = allInstallments.map((i) => i.toMap()).toList();

      final now = DateTime.now();
      final nowJ = dateTimeToJalali(now);
      final currentPeriod =
          '${nowJ.year.toString().padLeft(4, '0')}-${nowJ.month.toString().padLeft(2, '0')}';

      try {
        final rows =
            await compute<Map<String, dynamic>, List<Map<String, dynamic>>>(
          (msg) => computeDetectAnomalies(
            List<Map<String, dynamic>>.from(msg['loans'] as List),
            List<Map<String, dynamic>>.from(msg['insts'] as List),
            msg['current'] as String,
            msg['monthsBack'] as int,
          ),
          {
            'loans': loanMaps,
            'insts': instMaps,
            'current': currentPeriod,
            'monthsBack': monthsBack,
          },
        );
        return rows;
      } catch (e) {
        final rows = computeDetectAnomalies(
          loanMaps,
          instMaps,
          currentPeriod,
          monthsBack,
        );
        return rows;
      }
    } catch (e) {
      debugPrint('Error detecting anomalies: $e');
      return [];
    }
  }

  // Get all smart insights (subscriptions + bill changes)
  Future<Map<String, dynamic>> getAllInsights() async {
    final subscriptions = await detectSubscriptions();
    final billChanges = await detectBillChanges();

    return {
      'subscriptions': subscriptions,
      'billChanges': billChanges,
      'hasInsights': subscriptions.isNotEmpty || billChanges.isNotEmpty,
    };
  }

  // Generate a smart suggestion message for detected patterns
  String generateSuggestionMessage(SubscriptionInsight subscription) {
    return '💡 به نظر می‌رسد شما یک اشتراک دارید: ${formatCurrency(subscription.amount)} در ماه برای ${subscription.payee}. هنوز استفاده می‌کنید؟';
  }

  String generateBillChangeMessage(BillChangeInsight change) {
    return '📈 قبض ${change.payee} شما ${change.percentageChange.toStringAsFixed(0)}٪ نسبت به ماه قبل افزایش یافته است';
  }
}
