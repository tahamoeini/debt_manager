import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:debt_manager/features/achievements/achievements_repository.dart';
import 'package:debt_manager/core/theme/app_dimensions.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressFuture = ref.watch(_userProgressProvider);
    final achievementsFuture = ref.watch(_earnedAchievementsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('پیشرفت و دستاوردها')),
      body: ListView(
        padding: AppDimensions.pagePadding,
        children: [
          progressFuture.when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Text('خطا در بارگذاری پیشرفت'),
            ),
            data: (progress) => Column(
              children: [
                // XP & Level Card
                Card(
                  child: Padding(
                    padding: AppDimensions.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'سطح و تجربه',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('سطح:'),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'سطح ${progress.level + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Text('تجربه: ${progress.totalXp} امتیاز'),
                        const SizedBox(height: AppDimensions.spacingS),
                        // XP Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (progress.totalXp % 100) / 100.0,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade300,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.green.shade400),
                          ),
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          '${(progress.totalXp % 100)} / 100 امتیاز تا سطح بعد',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Streaks Card
                Card(
                  child: Padding(
                    padding: AppDimensions.cardPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'توالی پرداخت‌ها',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppDimensions.spacingM),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('روزهای پیاپی:'),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${progress.streaks['payments'] ?? 0}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacingS),
                        Text(
                          'شما این مدت متوالی پرداخت کرده‌اید',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppDimensions.spacingM),

                // Freedom Date Card
                if (progress.freedomDate != null)
                  Card(
                    color: Colors.green.shade50,
                    child: Padding(
                      padding: AppDimensions.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاریخ آزادی مالی',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.spacingM),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('آزاد شدن از بدهی:'),
                              Text(
                                progress.freedomDate != null
                                    ? '${progress.freedomDate!.year}-${progress.freedomDate!.month}-${progress.freedomDate!.day}'
                                    : '-',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('روزهای باقی‌مانده:'),
                              Text(
                                '${progress.daysFreedomCountdown} روز',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Card(
                    child: Padding(
                      padding: AppDimensions.cardPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'تاریخ آزادی مالی',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppDimensions.spacingS),
                          Text(
                            'هنوز بدهی‌های شما فی الوقت محاسبه نشده‌اند',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: AppDimensions.spacingM),

                // Achievements List
                Text(
                  'دستاوردها',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppDimensions.spacingS),
                achievementsFuture.when(
                  loading: () => Center(child: CircularProgressIndicator()),
                  error: (e, st) => Text('خطا در بارگذاری دستاوردها'),
                  data: (achievements) {
                    if (achievements.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: AppDimensions.cardPadding,
                          child: Text(
                            'هنوز هیچ دستاوردی برنده نشده‌اید',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: achievements.map((achievement) {
                        return Card(
                          child: Padding(
                            padding: AppDimensions.cardPadding,
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 24,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppDimensions.spacingM),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        achievement.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium,
                                      ),
                                      const SizedBox(
                                        height: AppDimensions.spacingS,
                                      ),
                                      Text(
                                        achievement.message,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Providers for UserProgress and earned achievements
final _userProgressProvider = FutureProvider<UserProgress>((ref) async {
  final repo = AchievementsRepository.instance;
  return repo.getUserProgress();
});

final _earnedAchievementsProvider =
    FutureProvider<List<Achievement>>((ref) async {
  final repo = AchievementsRepository.instance;
  return repo.getEarnedAchievements();
});
