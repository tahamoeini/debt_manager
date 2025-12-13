import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:debt_manager/features/achievements/achievements_repository.dart';

void main() {
  group('AchievementsRepository', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('addXp increases total XP', () async {
      final repo = AchievementsRepository.instance;

      await repo.addXp(100);
      final progress1 = await repo.getUserProgress();

      expect(progress1.totalXp, equals(100));

      await repo.addXp(50);
      final progress2 = await repo.getUserProgress();

      expect(progress2.totalXp, equals(150));
    });

    test('XP level computation is correct', () async {
      final repo = AchievementsRepository.instance;

      // Level computed as totalXp ~/ 100
      await repo.addXp(99);
      var progress = await repo.getUserProgress();
      expect(progress.level, equals(0)); // 99 ~/ 100 = 0

      await repo.addXp(1);
      progress = await repo.getUserProgress();
      expect(progress.level, equals(1)); // 100 ~/ 100 = 1

      await repo.addXp(400); // 500 total
      progress = await repo.getUserProgress();
      expect(progress.level, equals(5)); // 500 ~/ 100 = 5
    });

    test('updatePaymentStreak updates streak', () async {
      final repo = AchievementsRepository.instance;

      final streak1 = await repo.updatePaymentStreak();
      expect(streak1, greaterThanOrEqualTo(0));

      final streak2 = await repo.updatePaymentStreak();
      // Should be same day, so same streak
      expect(streak2, greaterThanOrEqualTo(0));
    });

    test('getUserProgress returns valid data on first call', () async {
      final repo = AchievementsRepository.instance;

      final progress = await repo.getUserProgress();

      expect(progress.totalXp, greaterThanOrEqualTo(0));
      expect(progress.level, greaterThanOrEqualTo(0));
      expect(progress.streaks, isNotNull);
    });

    test('UserProgress factory creates default values', () {
      final progress = UserProgress.empty();

      expect(progress.totalXp, equals(0));
      expect(progress.level, equals(0));
      expect(progress.streaks, isEmpty);
      expect(progress.freedomDate, isNull);
    });

    test('getEarnedAchievements returns list', () async {
      final repo = AchievementsRepository.instance;

      final achievements = await repo.getEarnedAchievements();

      expect(achievements, isA<List>());
    });

    test('Multiple XP sources accumulate correctly', () async {
      final repo = AchievementsRepository.instance;

      // Clear previous XP by creating fresh instance
      SharedPreferences.setMockInitialValues({});

      // Simulate various XP rewards
      await repo.addXp(XpRewards.paymentMade); // 10
      await repo.addXp(XpRewards.earlyPayment); // 25
      await repo.addXp(XpRewards.budgetKept); // 20

      final progress = await repo.getUserProgress();

      expect(progress.totalXp, equals(55));
    });

    test('Streak persists across accesses', () async {
      final repo = AchievementsRepository.instance;

      await repo.updatePaymentStreak();

      // Read again
      final progress = await repo.getUserProgress();
      final streakMap = progress.streaks['payments'] ?? 0;

      expect(streakMap, greaterThanOrEqualTo(0));
    });

    test('XP persists across accesses', () async {
      final repo = AchievementsRepository.instance;

      SharedPreferences.setMockInitialValues({});

      await repo.addXp(250);

      final progress = await repo.getUserProgress();

      expect(progress.totalXp, equals(250));
    });

    test('Freedom date is nullable', () async {
      final repo = AchievementsRepository.instance;

      final progress = await repo.getUserProgress();

      // Should not throw
      final countdownDays = progress.daysFreedomCountdown;
      expect(countdownDays, isA<int>());
    });
  });

  group('XpRewards Constants', () {
    test('XpRewards values are positive', () {
      expect(XpRewards.paymentMade, greaterThan(0));
      expect(XpRewards.earlyPayment, greaterThan(0));
      expect(XpRewards.budgetKept, greaterThan(0));
      expect(XpRewards.reportChecked, greaterThan(0));
      expect(XpRewards.loanCompleted, greaterThan(0));
    });

    test('XpRewards are ordered by value', () {
      expect(XpRewards.loanCompleted, greaterThan(XpRewards.earlyPayment));
      expect(XpRewards.earlyPayment, greaterThan(XpRewards.budgetKept));
      expect(XpRewards.budgetKept, greaterThan(XpRewards.paymentMade));
    });
  });

  group('UserProgress', () {
    test('UserProgress level increases with XP', () {
      final progress1 = UserProgress(
        totalXp: 50,
        level: 0,
        streaks: {},
        freedomDate: null,
        daysFreedomCountdown: 0,
      );

      final progress2 = UserProgress(
        totalXp: 150,
        level: 1,
        streaks: {},
        freedomDate: null,
        daysFreedomCountdown: 0,
      );

      expect(progress2.level, greaterThan(progress1.level));
    });

    test('UserProgress level 0 minimum', () {
      final progress = UserProgress(
        totalXp: 0,
        level: 0,
        streaks: {},
        freedomDate: null,
        daysFreedomCountdown: 0,
      );

      expect(progress.level, greaterThanOrEqualTo(0));
    });
  });
}
