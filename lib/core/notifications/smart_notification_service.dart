// Smart notification service: handles budget alerts, smart suggestions, and enhanced reminders
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:debt_manager/core/settings/settings_repository.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/budget/budgets_repository.dart';
import 'package:debt_manager/features/budget/models/budget.dart';
import 'package:debt_manager/features/loans/models/installment.dart';

class SmartNotificationService {
  static final SmartNotificationService instance = SmartNotificationService._internal();
  SmartNotificationService._internal();
  factory SmartNotificationService() => instance;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final _settings = SettingsRepository();
  final _db = DatabaseHelper.instance;
  final _budgetRepo = BudgetsRepository();

  static const String _channelIdBudget = 'budget_alerts_channel';
  static const String _channelNameBudget = 'Budget Alerts';
  static const String _channelDescBudget = 'Alerts when budgets reach thresholds';

  static const String _channelIdSuggestions = 'smart_suggestions_channel';
  static const String _channelNameSuggestions = 'Smart Suggestions';
  static const String _channelDescSuggestions = 'Suggestions for subscriptions and savings';

  static const String _channelIdSummary = 'monthly_summary_channel';
  static const String _channelNameSummary = 'Monthly Summary';
  static const String _channelDescSummary = 'Monthly budget performance summaries';

  /// Initialize smart notification channels
  Future<void> init() async {
    if (kIsWeb) {
      debugPrint('SmartNotificationService: skipping initialization on web');
      return;
    }

    // Create notification channels for different types
    final budgetChannel = AndroidNotificationChannel(
      _channelIdBudget,
      _channelNameBudget,
      description: _channelDescBudget,
      importance: Importance.high,
    );

    final suggestionsChannel = AndroidNotificationChannel(
      _channelIdSuggestions,
      _channelNameSuggestions,
      description: _channelDescSuggestions,
      importance: Importance.defaultImportance,
    );

    final summaryChannel = AndroidNotificationChannel(
      _channelIdSummary,
      _channelNameSummary,
      description: _channelDescSummary,
      importance: Importance.defaultImportance,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(budgetChannel);
    await android?.createNotificationChannel(suggestionsChannel);
    await android?.createNotificationChannel(summaryChannel);
  }

  /// Check all budgets and send notifications for those exceeding thresholds
  Future<void> checkBudgetThresholds(String period) async {
    if (kIsWeb) return;

    final alertsEnabled = await _settings.getBudgetAlertsEnabled();
    if (!alertsEnabled) return;

    final threshold90 = await _settings.getBudgetThreshold90Enabled();
    final threshold100 = await _settings.getBudgetThreshold100Enabled();

    if (!threshold90 && !threshold100) return;

    try {
      final budgets = await _budgetRepo.getBudgetsByPeriod(period);

      for (final budget in budgets) {
        final utilization = await _budgetRepo.computeUtilization(budget);
        final percentage = budget.amount > 0 ? (utilization / budget.amount) : 0.0;

        // Check 100% threshold
        if (threshold100 && percentage >= 1.0) {
          await _sendBudgetAlert(
            budget,
            percentage,
            '⚠️ Budget Exceeded',
            'You\'ve exceeded your ${budget.category ?? 'general'} budget for this period.',
          );
        }
        // Check 90% threshold (but not if already at 100%)
        else if (threshold90 && percentage >= 0.9 && percentage < 1.0) {
          await _sendBudgetAlert(
            budget,
            percentage,
            '⚠️ Budget Warning',
            'You\'ve used ${(percentage * 100).toStringAsFixed(0)}% of your ${budget.category ?? 'general'} budget.',
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking budget thresholds: $e');
    }
  }

  Future<void> _sendBudgetAlert(Budget budget, double percentage, String title, String body) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        _channelIdBudget,
        _channelNameBudget,
        channelDescription: _channelDescBudget,
        importance: Importance.high,
        priority: Priority.high,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use budget ID as notification ID to avoid duplicates
      final notificationId = budget.id != null ? 20000 + budget.id! : 20000;

      await _plugin.show(
        notificationId,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error sending budget alert: $e');
    }
  }

  /// Send a monthly summary notification
  Future<void> sendMonthEndSummary(String period, Map<String, dynamic> summary) async {
    if (kIsWeb) return;

    final enabled = await _settings.getMonthEndSummaryEnabled();
    if (!enabled) return;

    try {
      final underBudget = summary['underBudget'] as int? ?? 0;
      final total = summary['total'] as int? ?? 0;

      String message;
      if (total == 0) {
        message = 'No budgets tracked this month.';
      } else if (underBudget == total) {
        message = 'Great job! You stayed under budget in all $total categories! 🎉';
      } else {
        message = 'You stayed under budget in $underBudget of $total categories.';
      }

      const androidDetails = AndroidNotificationDetails(
        _channelIdSummary,
        _channelNameSummary,
        channelDescription: _channelDescSummary,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _plugin.show(
        30000, // Fixed ID for monthly summary
        '📊 Monthly Budget Summary',
        message,
        details,
      );
    } catch (e) {
      debugPrint('Error sending month-end summary: $e');
    }
  }

  /// Send a smart suggestion notification
  Future<void> sendSmartSuggestion(String title, String body, int suggestionId) async {
    if (kIsWeb) return;

    final enabled = await _settings.getSmartSuggestionsEnabled();
    if (!enabled) return;

    try {
      const androidDetails = AndroidNotificationDetails(
        _channelIdSuggestions,
        _channelNameSuggestions,
        channelDescription: _channelDescSuggestions,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const iosDetails = DarwinNotificationDetails();

      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use suggestion ID + offset to avoid collision with other notification types
      final notificationId = 40000 + suggestionId;

      await _plugin.show(
        notificationId,
        title,
        body,
        details,
      );
    } catch (e) {
      debugPrint('Error sending smart suggestion: $e');
    }
  }

  /// Schedule bill reminders based on due dates
  Future<void> scheduleBillReminders() async {
    if (kIsWeb) return;

    try {
      final offsetDays = await _settings.getReminderOffsetDays();
      final now = DateTime.now();
      
      // Get upcoming installments for the next 30 days
      final endDate = now.add(const Duration(days: 30));
      final upcoming = await _db.getUpcomingInstallments(now, endDate);

      for (final installment in upcoming) {
        // Schedule notification X days before due date
        if (offsetDays > 0) {
          await _scheduleReminderForInstallment(installment, offsetDays);
        }
        
        // Also schedule notification on due date
        await _scheduleReminderForInstallment(installment, 0);
      }
    } catch (e) {
      debugPrint('Error scheduling bill reminders: $e');
    }
  }

  Future<void> _scheduleReminderForInstallment(Installment installment, int daysOffset) async {
    // This would integrate with the existing notification service
    // For now, we'll leave it as a placeholder that would call
    // the NotificationService.scheduleInstallmentReminder method
    debugPrint('Would schedule reminder for installment ${installment.id} with offset $daysOffset days');
  }

  /// Cancel all scheduled notifications for a specific type
  Future<void> cancelAllNotificationsOfType(String type) async {
    if (kIsWeb) return;

    // Cancel notifications based on type
    // Budget alerts: 20000-29999
    // Monthly summaries: 30000-39999
    // Smart suggestions: 40000-49999
    try {
      int startId = 0;
      int endId = 0;

      switch (type) {
        case 'budget':
          startId = 20000;
          endId = 29999;
          break;
        case 'summary':
          startId = 30000;
          endId = 39999;
          break;
        case 'suggestions':
          startId = 40000;
          endId = 49999;
          break;
      }

      for (int i = startId; i <= endId; i++) {
        await _plugin.cancel(i);
      }
    } catch (e) {
      debugPrint('Error canceling notifications of type $type: $e');
    }
  }
}
