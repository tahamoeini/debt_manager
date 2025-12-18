import 'package:shared_preferences/shared_preferences.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';
import 'package:debt_manager/features/reports/reports_repository.dart';
import 'package:debt_manager/features/loans/models/loan.dart';

// XP reward values for actions
class XpRewards {
  static const int paymentMade = 10;
  static const int earlyPayment = 25;
  static const int budgetKept = 20;
  static const int reportChecked = 5;
  static const int loanCompleted = 100;
}

// User progress: XP, level, streaks, freedom date
class UserProgress {
  final int totalXp;
  final int level;
  final Map<String, int> streaks; // e.g., {'payments': 5}
  final DateTime? freedomDate;
  final int daysFreedomCountdown;

  UserProgress({
    required this.totalXp,
    required this.level,
    required this.streaks,
    this.freedomDate,
    required this.daysFreedomCountdown,
  });

  factory UserProgress.empty() => UserProgress(
        totalXp: 0,
        level: 0,
        streaks: {},
        freedomDate: null,
        daysFreedomCountdown: 0,
      );
}

class Achievement {
  final String id;
  final String title;
  final String message;

  Achievement({required this.id, required this.title, required this.message});
}

class AchievementsRepository {
  AchievementsRepository._internal();
  static final AchievementsRepository instance =
      AchievementsRepository._internal();

  static const _keyEarned = 'achievements_earned';
  static const _keyPaidMonths = 'achievements_paid_months';
  static const _keyTotalXp = 'total_xp';
  static const _keyStreak = 'payment_streak_days';

  Future<Set<String>> _getEarnedSet() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyEarned) ?? <String>[];
    return list.toSet();
  }

  Future<void> _saveEarnedSet(Set<String> s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyEarned, s.toList());
  }

  Future<List<Achievement>> getEarnedAchievements() async {
    final earned = await _getEarnedSet();
    final list = <Achievement>[];
    if (earned.contains('first_debt_paid')) {
      list.add(
        Achievement(
          id: 'first_debt_paid',
          title: 'اولین بدهی پرداخت شد',
          message: 'تبریک! اولین بدهی خود را پرداخت کردید.',
        ),
      );
    }
    if (earned.contains('three_months_streak')) {
      list.add(
        Achievement(
          id: 'three_months_streak',
          title: '۳ ماه متوالی پرداخت',
          message: 'شما سه ماه پیاپی پرداخت داشته‌اید. ادامه بده!',
        ),
      );
    }
    if (earned.contains('debt_free')) {
      list.add(
        Achievement(
          id: 'debt_free',
          title: 'بدهی‌ها صفر شد',
          message: 'تبریک! شما الان بدون بدهی هستید.',
        ),
      );
    }
    return list;
  }

  Future<void> _addEarned(String id) async {
    final set = await _getEarnedSet();
    if (!set.contains(id)) {
      set.add(id);
      await _saveEarnedSet(set);
    }
  }

  Future<Set<String>> _getPaidMonths() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyPaidMonths) ?? <String>[];
    return list.toSet();
  }

  Future<void> _savePaidMonths(Set<String> s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyPaidMonths, s.toList());
  }

  String _monthKeyFrom(DateTime dt) {
    final j = dateTimeToJalali(dt);
    return '${j.year.toString().padLeft(4, '0')}-${j.month.toString().padLeft(2, '0')}';
  }

  // Called after a payment is recorded. Returns list of newly awarded achievements.
  Future<List<Achievement>> handlePayment({
    int? loanId,
    required DateTime paidAt,
  }) async {
    final newly = <Achievement>[];

    // Track month of payment
    final monthKey = _monthKeyFrom(paidAt);
    final months = await _getPaidMonths();
    if (!months.contains(monthKey)) {
      months.add(monthKey);
      await _savePaidMonths(months);
    }

    final earned = await _getEarnedSet();

    // 1) First Debt Paid: if loanId provided and this loan now fully paid
    if (loanId != null && !earned.contains('first_debt_paid')) {
      final installments =
          await DatabaseHelper.instance.getInstallmentsByLoanId(loanId);
      final allPaid = installments.isNotEmpty &&
          installments.every((i) => i.status == InstallmentStatus.paid);
      if (allPaid) {
        await _addEarned('first_debt_paid');
        newly.add(
          Achievement(
            id: 'first_debt_paid',
            title: 'اولین بدهی پرداخت شد',
            message: 'تبریک! اولین بدهی خود را پرداخت کردید.',
          ),
        );
      }
    }

    // 2) Three months streak: check if current month and previous two months have payments
    if (!earned.contains('three_months_streak')) {
      // compute current and previous two month keys
      final keys = <String>[];
      var dt = paidAt;
      for (var i = 0; i < 3; i++) {
        final k = _monthKeyFrom(dt);
        keys.add(k);
        // move dt to previous month
        dt = DateTime(dt.year, dt.month - 1, 1);
      }
      final monthsSet = await _getPaidMonths();
      final hasStreak = keys.every((k) => monthsSet.contains(k));
      if (hasStreak) {
        await _addEarned('three_months_streak');
        newly.add(
          Achievement(
            id: 'three_months_streak',
            title: '۳ ماه متوالی پرداخت',
            message: 'شما سه ماه پیاپی پرداخت داشته‌اید. ادامه بده!',
          ),
        );
      }
    }

    // 3) Debt free: total outstanding borrowed becomes zero
    if (!earned.contains('debt_free')) {
      final total = await DatabaseHelper.instance.getTotalOutstandingBorrowed();
      if (total == 0) {
        await _addEarned('debt_free');
        newly.add(
          Achievement(
            id: 'debt_free',
            title: 'بدهی‌ها صفر شد',
            message: 'تبریک! شما الان بدون بدهی هستید.',
          ),
        );
      }
    }

    return newly;
  }

  // Get current user progress (XP, level, streaks, freedom date)
  Future<UserProgress> getUserProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final totalXp = prefs.getInt(_keyTotalXp) ?? 0;
    final streakStr =
        prefs.getString(_keyStreak) ?? '0:${DateTime.now().toIso8601String()}';
    final parts = streakStr.split(':');
    final streak = int.tryParse(parts.first) ?? 0;

    // Compute freedom date from debt projections
    DateTime? freedomDate;
    try {
      final reportsRepo = ReportsRepository();
      final loans = await DatabaseHelper.instance.getAllLoans(
        direction: LoanDirection.borrowed,
      );
      if (loans.isNotEmpty) {
        DateTime? maxDate;
        for (final loan in loans) {
          if (loan.id == null) continue;
          final projection = await reportsRepo.projectDebtPayoff(loan.id!);
          if (projection.isNotEmpty) {
            // Estimate payoff from projection length
            final estimatedDate = DateTime.now().add(
              Duration(days: projection.length),
            );
            maxDate = maxDate == null || estimatedDate.isAfter(maxDate)
                ? estimatedDate
                : maxDate;
          }
        }
        freedomDate = maxDate;
      }
    } catch (e) {
      // Error computing freedom date, skip
    }

    return UserProgress(
      totalXp: totalXp,
      level: totalXp ~/ 100,
      streaks: {'payments': streak},
      freedomDate: freedomDate,
      daysFreedomCountdown: freedomDate != null
          ? freedomDate.difference(DateTime.now()).inDays
          : 0,
    );
  }

  // Add XP to user progress
  Future<int> addXp(int xpAmount) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyTotalXp) ?? 0;
    final newTotal = current + xpAmount;
    await prefs.setInt(_keyTotalXp, newTotal);
    return newTotal;
  }

  // Update payment streak
  Future<int> updatePaymentStreak() async {
    final prefs = await SharedPreferences.getInstance();
    final streakStr =
        prefs.getString(_keyStreak) ?? '0:${DateTime.now().toIso8601String()}';
    final parts = streakStr.split(':');
    final lastDateStr = parts.length > 1
        ? parts.sublist(1).join(':')
        : DateTime.now().toIso8601String();
    final lastDate = DateTime.parse(lastDateStr);
    final today = DateTime.now();

    int newStreak;
    if (lastDate.difference(today).inDays == -1) {
      // Consecutive day
      newStreak = (int.tryParse(parts.first) ?? 0) + 1;
    } else if (lastDate.year == today.year &&
        lastDate.month == today.month &&
        lastDate.day == today.day) {
      // Same day, no change
      newStreak = int.tryParse(parts.first) ?? 1;
    } else {
      // Broken streak, restart
      newStreak = 1;
    }

    await prefs.setString(_keyStreak, '$newStreak:${today.toIso8601String()}');
    return newStreak;
  }
}
