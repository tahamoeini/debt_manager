class AchievementType {
  static const String paymentMade = 'payment_made';
  static const String earlyPayment = 'early_payment';
  static const String budgetKept = 'budget_kept';
  static const String reportChecked = 'report_checked';
  static const String debtFreeDay = 'debt_free_day';
  static const String speedyPayoff =
      'speedy_payoff'; // paid off loan in <6 months
}

class Achievement {
  final String id;
  final String titleEn;
  final String titleFa;
  final String descriptionEn;
  final String descriptionFa;
  final int xpValue;
  final String category; // e.g., 'payment', 'budget', 'milestone'
  final String? iconEmoji;

  Achievement({
    required this.id,
    required this.titleEn,
    required this.titleFa,
    required this.descriptionEn,
    required this.descriptionFa,
    required this.xpValue,
    required this.category,
    this.iconEmoji,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'titleEn': titleEn,
    'titleFa': titleFa,
    'descriptionEn': descriptionEn,
    'descriptionFa': descriptionFa,
    'xpValue': xpValue,
    'category': category,
    'iconEmoji': iconEmoji,
  };
}

class UserProgress {
  final int totalXp;
  final int level; // computed: totalXp / 100
  final Map<String, int> streaks; // e.g., {'payments': 5, 'budget': 3}
  final List<String> unlockedAchievements; // achievement IDs
  final DateTime? freedomDate; // projected debt-free date
  final int daysFreedomCountdown; // days until freedom date

  UserProgress({
    required this.totalXp,
    required this.level,
    required this.streaks,
    required this.unlockedAchievements,
    this.freedomDate,
    required this.daysFreedomCountdown,
  });

  factory UserProgress.empty() => UserProgress(
    totalXp: 0,
    level: 0,
    streaks: {},
    unlockedAchievements: [],
    freedomDate: null,
    daysFreedomCountdown: 0,
  );

  Map<String, dynamic> toMap() => {
    'totalXp': totalXp,
    'level': level,
    'streaks': streaks,
    'unlockedAchievements': unlockedAchievements,
    'freedomDate': freedomDate?.toIso8601String(),
    'daysFreedomCountdown': daysFreedomCountdown,
  };
}

class UserAction {
  final String actionType; // use AchievementType constants
  final DateTime timestamp;
  final Map<String, dynamic>? metadata; // optional context (e.g., loanId)

  UserAction({
    required this.actionType,
    required this.timestamp,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'actionType': actionType,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };
}

class Milestone {
  final int xpThreshold; // e.g., 500, 1000
  final String titleEn;
  final String titleFa;
  final String iconEmoji;

  Milestone({
    required this.xpThreshold,
    required this.titleEn,
    required this.titleFa,
    required this.iconEmoji,
  });
}

/// Define standard achievements
class BuiltInAchievements {
  static final all = <String, Achievement>{
    'first_payment': Achievement(
      id: 'first_payment',
      titleEn: 'First Payment',
      titleFa: 'اولین پرداخت',
      descriptionEn: 'Log your first payment',
      descriptionFa: 'ثبت اولین پرداخت خود',
      xpValue: 50,
      category: 'payment',
      iconEmoji: '💰',
    ),
    'payment_streak_7': Achievement(
      id: 'payment_streak_7',
      titleEn: '7-Day Streak',
      titleFa: 'رکورد 7 روزه',
      descriptionEn: 'Make payments 7 days in a row',
      descriptionFa: '7 روز متوالی پرداخت کنید',
      xpValue: 100,
      category: 'payment',
      iconEmoji: '🔥',
    ),
    'budget_champion': Achievement(
      id: 'budget_champion',
      titleEn: 'Budget Champion',
      titleFa: 'قهرمان بودجه',
      descriptionEn: 'Stay within budget for 3 months',
      descriptionFa: '3 ماه در بودجه بمانید',
      xpValue: 150,
      category: 'budget',
      iconEmoji: '📊',
    ),
    'early_bird': Achievement(
      id: 'early_bird',
      titleEn: 'Early Bird',
      titleFa: 'زودرس',
      descriptionEn: 'Pay a debt early 5 times',
      descriptionFa: '5 بار یک بدهی را زودتر بپردازید',
      xpValue: 200,
      category: 'payment',
      iconEmoji: '⏰',
    ),
    'debt_free_month': Achievement(
      id: 'debt_free_month',
      titleEn: 'Debt-Free Month',
      titleFa: 'ماه بدهی‌آزاد',
      descriptionEn: 'Pay off a full debt',
      descriptionFa: 'یک بدهی کامل را بپردازید',
      xpValue: 300,
      category: 'milestone',
      iconEmoji: '🎉',
    ),
    'financial_analyst': Achievement(
      id: 'financial_analyst',
      titleEn: 'Financial Analyst',
      titleFa: 'تحلیلگر مالی',
      descriptionEn: 'Check reports 10 times',
      descriptionFa: '10 بار گزارش بررسی کنید',
      xpValue: 120,
      category: 'report',
      iconEmoji: '📈',
    ),
  };

  static final milestones = <Milestone>[
    Milestone(
      xpThreshold: 100,
      titleEn: 'Novice',
      titleFa: 'مبتدی',
      iconEmoji: '🌱',
    ),
    Milestone(
      xpThreshold: 500,
      titleEn: 'Intermediate',
      titleFa: 'درمیانی',
      iconEmoji: '⭐',
    ),
    Milestone(
      xpThreshold: 1000,
      titleEn: 'Advanced',
      titleFa: 'پیشرفته',
      iconEmoji: '🏆',
    ),
    Milestone(
      xpThreshold: 2000,
      titleEn: 'Master',
      titleFa: 'استاد',
      iconEmoji: '👑',
    ),
  ];
}
