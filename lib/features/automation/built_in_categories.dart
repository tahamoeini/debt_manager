class BuiltInCategory {
  final String id;
  final String nameEn;
  final String nameFa;
  final int baseXp; // XP earned when categorized correctly

  BuiltInCategory({
    required this.id,
    required this.nameEn,
    required this.nameFa,
    this.baseXp = 10,
  });
}

class BuiltInCategories {
  // Category definitions
  static final categories = {
    'utilities': BuiltInCategory(
      id: 'utilities',
      nameEn: 'Utilities',
      nameFa: 'آب برق گاز',
      baseXp: 15,
    ),
    'food': BuiltInCategory(
      id: 'food',
      nameEn: 'Food & Dining',
      nameFa: 'غذا و رستوران',
      baseXp: 10,
    ),
    'transport': BuiltInCategory(
      id: 'transport',
      nameEn: 'Transport',
      nameFa: 'حمل و نقل',
      baseXp: 10,
    ),
    'subscription': BuiltInCategory(
      id: 'subscription',
      nameEn: 'Subscriptions',
      nameFa: 'اشتراک‌ها',
      baseXp: 20,
    ),
    'healthcare': BuiltInCategory(
      id: 'healthcare',
      nameEn: 'Healthcare',
      nameFa: 'درمان و سلامت',
      baseXp: 15,
    ),
    'shopping': BuiltInCategory(
      id: 'shopping',
      nameEn: 'Shopping',
      nameFa: 'خرید',
      baseXp: 10,
    ),
    'entertainment': BuiltInCategory(
      id: 'entertainment',
      nameEn: 'Entertainment',
      nameFa: 'تفریح',
      baseXp: 5,
    ),
    'loan': BuiltInCategory(
      id: 'loan',
      nameEn: 'Loan Payment',
      nameFa: 'پرداخت وام',
      baseXp: 25,
    ),
    'investment': BuiltInCategory(
      id: 'investment',
      nameEn: 'Investment',
      nameFa: 'سرمایه‌گذاری',
      baseXp: 30,
    ),
  };

  // Pattern matching: payee patterns → category
  // Format: (pattern, category_id, confidence_0_to_1)
  // Patterns are case-insensitive and support partial matches
  static final payeePatterns = <String, String>{
    // Utilities (Persian)
    'آب و برق': 'utilities',
    'شرکت آب': 'utilities',
    'برق': 'utilities',
    'گاز': 'utilities',
    'شهرداری': 'utilities',
    'شهر': 'utilities',
    'آب': 'utilities',
    'عوارض': 'utilities',

    // Utilities (English)
    'water': 'utilities',
    'electricity': 'utilities',
    'gas': 'utilities',
    'utility': 'utilities',
    'power company': 'utilities',

    // Food (Persian)
    'رستوران': 'food',
    'غذا': 'food',
    'سفارش': 'food',
    'کافه': 'food',
    'قهوه‌خانه': 'food',
    'فست فود': 'food',
    'پیتزا': 'food',
    'ناهار': 'food',
    'شام': 'food',
    'چای': 'food',
    'بیکاری': 'food',
    'قصاب': 'food',
    'میوه‌فروشی': 'food',

    // Food (English)
    'restaurant': 'food',
    'food': 'food',
    'cafe': 'food',
    'coffee': 'food',
    'pizza': 'food',
    'burger': 'food',
    'bakery': 'food',
    'grocery': 'food',
    'supermarket': 'food',
    'delivery': 'food',

    // Transport (Persian)
    'تاکسی': 'transport',
    'موتور': 'transport',
    'ماشین': 'transport',
    'پمپ بنزین': 'transport',
    'بنزین': 'transport',
    'دیزل': 'transport',
    'اتوبوس': 'transport',
    'مترو': 'transport',
    'قطار': 'transport',
    'سوارکاری': 'transport',
    'تعمیر': 'transport',
    'تعویض روغن': 'transport',
    'جریمه راهداری': 'transport',
    'پارکینگ': 'transport',
    'کرایه': 'transport',

    // Transport (English)
    'taxi': 'transport',
    'uber': 'transport',
    'gas station': 'transport',
    'fuel': 'transport',
    'bus': 'transport',
    'metro': 'transport',
    'train': 'transport',
    'parking': 'transport',
    'tolls': 'transport',
    'uber eats': 'food',
    'lyft': 'transport',
    'car repair': 'transport',

    // Subscriptions (Persian)
    'اپیک': 'subscription',
    'نتفلیکس': 'subscription',
    'تلگرام پریمیوم': 'subscription',
    'اشتراک': 'subscription',
    'سرویس': 'subscription',
    'اپلیکیشن': 'subscription',
    'ماهانه': 'subscription',
    'سالانه': 'subscription',
    'بسته': 'subscription',

    // Subscriptions (English)
    'subscription': 'subscription',
    'netflix': 'subscription',
    'spotify': 'subscription',
    'apple': 'subscription',
    'microsoft': 'subscription',
    'adobe': 'subscription',
    'aws': 'subscription',
    'vpn': 'subscription',
    'monthly': 'subscription',
    'annual': 'subscription',

    // Healthcare (Persian)
    'دکتر': 'healthcare',
    'بیمارستان': 'healthcare',
    'داروخانه': 'healthcare',
    'دارو': 'healthcare',
    'پزشک': 'healthcare',
    'کلینیک': 'healthcare',
    'دندانپزشک': 'healthcare',
    'آزمایشگاه': 'healthcare',

    // Healthcare (English)
    'doctor': 'healthcare',
    'hospital': 'healthcare',
    'pharmacy': 'healthcare',
    'medicine': 'healthcare',
    'health': 'healthcare',
    'clinic': 'healthcare',
    'dental': 'healthcare',

    // Shopping (Persian)
    'فروشگاه': 'shopping',
    'مغازه': 'shopping',
    'دیجیتال': 'shopping',
    'آمازون': 'shopping',
    'علی‌بابا': 'shopping',
    'خرید': 'shopping',
    'لباس': 'shopping',
    'کفش': 'shopping',
    'نشاط': 'shopping',
    'بانی': 'shopping',
    'زنجیره': 'shopping',

    // Shopping (English)
    'amazon': 'shopping',
    'ebay': 'shopping',
    'walmart': 'shopping',
    'target': 'shopping',
    'mall': 'shopping',
    'store': 'shopping',
    'shop': 'shopping',
    'clothing': 'shopping',

    // Entertainment (Persian)
    'سینما': 'entertainment',
    'تئاتر': 'entertainment',
    'کنسرت': 'entertainment',
    'ورزش': 'entertainment',
    'باشگاه': 'entertainment',
    'بازی': 'entertainment',
    'فیلم': 'entertainment',
    'سرگرمی': 'entertainment',

    // Entertainment (English)
    'cinema': 'entertainment',
    'movie': 'entertainment',
    'theater': 'entertainment',
    'concert': 'entertainment',
    'sports': 'entertainment',
    'gym': 'entertainment',
    'game': 'entertainment',

    // Loans (Persian)
    'وام': 'loan',
    'قرض': 'loan',
    'بانک': 'loan',
    'بدهی': 'loan',
    'پرداخت وام': 'loan',
    'قسط': 'loan',
    'سود': 'loan',

    // Loans (English)
    'loan': 'loan',
    'bank': 'loan',
    'mortgage': 'loan',
    'credit': 'loan',
    'debt': 'loan',
    'payment': 'loan',

    // Investment (Persian)
    'سهام': 'investment',
    'بورس': 'investment',
    'طلا': 'investment',
    'ارز': 'investment',
    'رمزارز': 'investment',
    'کریپتو': 'investment',
    'سرمایه‌گذاری': 'investment',

    // Investment (English)
    'stock': 'investment',
    'investment': 'investment',
    'crypto': 'investment',
    'bitcoin': 'investment',
    'gold': 'investment',
    'forex': 'investment',
  };

  /// Detect category from payee/description with confidence score.
  /// Returns tuple: (categoryId, confidence: 0.0-1.0)
  static (String?, double) detectCategory(
    String? payee,
    String? description,
    int? amount,
  ) {
    if ((payee?.isEmpty ?? true) && (description?.isEmpty ?? true)) {
      return (null, 0.0);
    }

    final text = '${payee ?? ''} ${description ?? ''}'.toLowerCase();
    final words = text.split(RegExp(r'\s+'));

    double bestScore = 0.0;
    String? bestCategory;

    for (final pattern in payeePatterns.entries) {
      final patternLower = pattern.key.toLowerCase();
      if (text.contains(patternLower)) {
        // Exact word match scores higher than substring match
        final isWordMatch = words.contains(patternLower);
        final score = isWordMatch ? 0.9 : 0.6;

        if (score > bestScore) {
          bestScore = score;
          bestCategory = pattern.value;
        }
      }
    }

    // Amount-based hints (heuristic)
    if (amount != null && bestScore < 0.5) {
      // Large amounts might be loan/investment
      if (amount > 5000000) {
        bestScore = 0.4;
        bestCategory = 'investment';
      }
    }

    return (bestCategory, bestScore);
  }
}
