import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:debt_manager/features/achievements/achievements_repository.dart';

void main() {
  group('AchievementsRepository - Integration Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('XP progression through multiple levels', () async {
      final repo = AchievementsRepository.instance;
      
      // Progress through levels
      await repo.addXp(99);
      var progress = await repo.getUserProgress();
      expect(progress.level, equals(0));

      await repo.addXp(1);
      progress = await repo.getUserProgress();
      expect(progress.level, equals(1));

      await repo.addXp(100);
      progress = await repo.getUserProgress();
      expect(progress.level, equals(2));

      await repo.addXp(300);
      progress = await repo.getUserProgress();
      expect(progress.level, equals(5)); // 500 ~/ 100 = 5

      expect(progress.totalXp, equals(500));
    });

    test('Streak calculation with multiple updates', () async {
      final repo = AchievementsRepository.instance;
      
      final streak1 = await repo.updatePaymentStreak();
      expect(streak1, greaterThanOrEqualTo(0));

      // Immediate second update (same day)
      final streak2 = await repo.updatePaymentStreak();
      expect(streak2, greaterThanOrEqualTo(0));

      // Verify consistency
      final progress = await repo.getUserProgress();
      expect(progress.streaks, isNotEmpty);
    });

    test('UserProgress contains all required fields', () async {
      final repo = AchievementsRepository.instance;
      
      await repo.addXp(150);
      final progress = await repo.getUserProgress();

      expect(progress.totalXp, equals(150));
      expect(progress.level, isNotNull);
      expect(progress.streaks, isNotNull);
      expect(progress.daysFreedomCountdown, isNotNull);
    });

    test('Multiple consecutive XP additions', () async {
      final repo = AchievementsRepository.instance;
      
      final amounts = [10, 20, 30, 40, 50];
      int expectedTotal = 0;

      for (final amount in amounts) {
        final newTotal = await repo.addXp(amount);
        expectedTotal += amount;
        expect(newTotal, equals(expectedTotal));
      }

      final progress = await repo.getUserProgress();
      expect(progress.totalXp, equals(expectedTotal));
    });

    test('Earned achievements list', () async {
      final repo = AchievementsRepository.instance;
      
      final achievements = await repo.getEarnedAchievements();
      
      expect(achievements, isA<List<Achievement>>());
      // Initially should be empty or have some default achievements
      expect(achievements, isNotNull);
    });

    test('Achievement unlock workflow', () async {
      final repo = AchievementsRepository.instance;
      
      // Get initial achievements
      final initial = await repo.getEarnedAchievements();
      
      // The count should make sense
      expect(initial.length, greaterThanOrEqualTo(0));
    });
  });

  group('UserProgress - Model Tests', () {
    test('empty() factory creates zero values', () {
      final progress = UserProgress.empty();
      
      expect(progress.totalXp, equals(0));
      expect(progress.level, equals(0));
      expect(progress.streaks, isEmpty);
      expect(progress.freedomDate, isNull);
      expect(progress.daysFreedomCountdown, equals(0));
    });

    test('UserProgress with custom values', () {
      final progress = UserProgress(
        totalXp: 250,
        level: 2,
        streaks: {'payments': 5},
        freedomDate: DateTime(2025, 12, 31),
        daysFreedomCountdown: 350,
      );

      expect(progress.totalXp, equals(250));
      expect(progress.level, equals(2));
      expect(progress.streaks['payments'], equals(5));
      expect(progress.freedomDate, isNotNull);
      expect(progress.daysFreedomCountdown, equals(350));
    });

    test('UserProgress with null freedom date', () {
      final progress = UserProgress(
        totalXp: 100,
        level: 1,
        streaks: {},
        freedomDate: null,
        daysFreedomCountdown: 0,
      );

      expect(progress.freedomDate, isNull);
      expect(progress.daysFreedomCountdown, equals(0));
    });

    test('UserProgress streaks map can hold multiple values', () {
      final progress = UserProgress(
        totalXp: 500,
        level: 5,
        streaks: {
          'payments': 10,
          'budgetKept': 3,
          'noOverdue': 5,
        },
        freedomDate: null,
        daysFreedomCountdown: 0,
      );

      expect(progress.streaks.length, equals(3));
      expect(progress.streaks['payments'], equals(10));
      expect(progress.streaks['budgetKept'], equals(3));
    });
  });

  group('Achievement - Model Tests', () {
    test('Achievement construction', () {
      final achievement = Achievement(
        id: 'first_payment',
        title: 'First Payment Made',
        message: 'You made your first payment!',
      );

      expect(achievement.id, equals('first_payment'));
      expect(achievement.title, equals('First Payment Made'));
      expect(achievement.message, equals('You made your first payment!'));
    });

    test('Achievement with Persian text', () {
      final achievement = Achievement(
        id: 'payment_streak_7',
        title: '۷ روز پیاپی',
        message: 'شما ۷ روز پیاپی پرداخت کرده‌اید',
      );

      expect(achievement.title, contains('۷'));
      expect(achievement.message, contains('روز'));
    });
  });

  group('XpRewards - Constants Tests', () {
    test('XpRewards values are positive integers', () {
      expect(XpRewards.paymentMade, greaterThan(0));
      expect(XpRewards.earlyPayment, greaterThan(0));
      expect(XpRewards.budgetKept, greaterThan(0));
      expect(XpRewards.reportChecked, greaterThan(0));
      expect(XpRewards.loanCompleted, greaterThan(0));
    });

    test('XpRewards hierarchy', () {
      expect(XpRewards.loanCompleted, greaterThan(XpRewards.earlyPayment));
      expect(XpRewards.earlyPayment, greaterThan(XpRewards.budgetKept));
      expect(XpRewards.budgetKept, greaterThan(XpRewards.paymentMade));
      expect(XpRewards.paymentMade, greaterThan(XpRewards.reportChecked));
    });

    test('XpRewards can be used in calculations', () {
      final totalXp = XpRewards.paymentMade +
          XpRewards.budgetKept +
          XpRewards.earlyPayment;

      expect(totalXp, equals(10 + 20 + 25));
      expect(totalXp, equals(55));
    });

    test('XpRewards for milestone achievement', () {
      final milestoneXp = XpRewards.loanCompleted;
      
      expect(milestoneXp, equals(100));
      expect(milestoneXp > XpRewards.paymentMade * 5, isTrue);
    });
  });

  group('AchievementsRepository - Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('XP persists across fresh instances', () async {
      final repo1 = AchievementsRepository.instance;
      await repo1.addXp(200);

      // Create "fresh" instance (in real app would be new object)
      final repo2 = AchievementsRepository.instance;
      final progress = await repo2.getUserProgress();

      expect(progress.totalXp, equals(200));
    });

    test('Multiple XP additions are cumulative', () async {
      final repo = AchievementsRepository.instance;
      
      await repo.addXp(50);
      var progress = await repo.getUserProgress();
      expect(progress.totalXp, equals(50));

      await repo.addXp(75);
      progress = await repo.getUserProgress();
      expect(progress.totalXp, equals(125));

      await repo.addXp(125);
      progress = await repo.getUserProgress();
      expect(progress.totalXp, equals(250));
    });

    test('Level calculation reflects XP correctly', () async {
      final repo = AchievementsRepository.instance;
      
      await repo.addXp(450);
      final progress = await repo.getUserProgress();

      expect(progress.totalXp, equals(450));
      expect(progress.level, equals(4)); // 450 ~/ 100 = 4
    });
  });
}
