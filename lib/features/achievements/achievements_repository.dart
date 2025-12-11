import 'package:shared_preferences/shared_preferences.dart';
import 'package:debt_manager/core/db/database_helper.dart';
import 'package:debt_manager/features/loans/models/installment.dart';
import 'package:debt_manager/core/utils/jalali_utils.dart';

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
      list.add(Achievement(
          id: 'first_debt_paid',
          title: 'اولین بدهی پرداخت شد',
          message: 'تبریک! اولین بدهی خود را پرداخت کردید.'));
    }
    if (earned.contains('three_months_streak')) {
      list.add(Achievement(
          id: 'three_months_streak',
          title: '۳ ماه متوالی پرداخت',
          message: 'شما سه ماه پیاپی پرداخت داشته‌اید. ادامه بده!'));
    }
    if (earned.contains('debt_free')) {
      list.add(Achievement(
          id: 'debt_free',
          title: 'بدهی‌ها صفر شد',
          message: 'تبریک! شما الان بدون بدهی هستید.'));
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

  /// Called after a payment is recorded. Returns list of newly awarded achievements.
  Future<List<Achievement>> handlePayment(
      {int? loanId, required DateTime paidAt}) async {
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
        newly.add(Achievement(
            id: 'first_debt_paid',
            title: 'اولین بدهی پرداخت شد',
            message: 'تبریک! اولین بدهی خود را پرداخت کردید.'));
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
        newly.add(Achievement(
            id: 'three_months_streak',
            title: '۳ ماه متوالی پرداخت',
            message: 'شما سه ماه پیاپی پرداخت داشته‌اید. ادامه بده!'));
      }
    }

    // 3) Debt free: total outstanding borrowed becomes zero
    if (!earned.contains('debt_free')) {
      final total = await DatabaseHelper.instance.getTotalOutstandingBorrowed();
      if (total == 0) {
        await _addEarned('debt_free');
        newly.add(Achievement(
            id: 'debt_free',
            title: 'بدهی‌ها صفر شد',
            message: 'تبریک! شما الان بدون بدهی هستید.'));
      }
    }

    return newly;
  }
}
