/// Deterministic notification ID generation.
///
/// ID Ranges:
/// - 1,000,000,000 - 1,999,999,999: Installment reminders (offset-based)
/// - 2,000,000,000 - 2,999,999,999: Installment due-date reminders
/// - 3,000,000,000 - 3,999,999,999: Budget alerts
/// - 4,000,000,000 - 4,999,999,999: Smart suggestions
/// - 5,000,000,000 - 5,999,999,999: Monthly summaries
///
/// Each installment can have multiple notifications:
/// - Offset reminder: forInstallmentOffset(installmentId, offsetDays)
/// - Due date reminder: forInstallmentDueDate(installmentId)
class NotificationIds {
  static const int installmentOffsetBase = 1000000000;
  static const int installmentDueDateBase = 2000000000;
  static const int budgetAlertBase = 3000000000;
  static const int smartSuggestionBase = 4000000000;
  static const int monthlySummaryBase = 5000000000;

  /// Generate notification ID for installment reminder with offset.
  /// offsetDays is encoded in the ID to support multiple offsets per installment.
  static int forInstallmentOffset(int installmentId, int offsetDays) {
    // Encode offset using a multiplication factor: ID = base + (installmentId * 100) + offsetDays
    // This supports offsets 0-99 and installmentIds up to ~9,999,999
    return installmentOffsetBase + (installmentId * 100) + offsetDays;
  }

  /// Generate notification ID for installment due-date reminder (offset = 0).
  static int forInstallmentDueDate(int installmentId) {
    return installmentDueDateBase + installmentId;
  }

  /// Generate notification ID for budget alert.
  static int forBudgetAlert(int budgetId) {
    return budgetAlertBase + budgetId;
  }

  /// Generate notification ID for smart suggestion.
  static int forSmartSuggestion(int suggestionId) {
    return smartSuggestionBase + suggestionId;
  }

  /// Generate notification ID for monthly summary.
  static int forMonthlySummary(String period) {
    // Hash period string to int (e.g., "2024-01" -> deterministic int)
    final hash = period.hashCode.abs() % 999999999;
    return monthlySummaryBase + hash;
  }

  /// Cancel all notifications for a specific installment.
  static List<int> allForInstallment(int installmentId, int maxOffsetDays) {
    final ids = <int>[];
    // Add all possible offset-based reminders (0 to maxOffsetDays)
    for (var offset = 0; offset <= maxOffsetDays; offset++) {
      ids.add(forInstallmentOffset(installmentId, offset));
    }
    // Add due-date reminder
    ids.add(forInstallmentDueDate(installmentId));
    return ids;
  }

  /// Check if notification ID is an installment reminder.
  static bool isInstallment(int id) {
    return id >= installmentOffsetBase && id < installmentDueDateBase;
  }

  /// Check if notification ID is an installment due-date reminder.
  static bool isInstallmentDueDate(int id) {
    return id >= installmentDueDateBase && id < budgetAlertBase;
  }
}
