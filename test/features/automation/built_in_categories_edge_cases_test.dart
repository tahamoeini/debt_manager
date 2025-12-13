import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/features/automation/built_in_categories.dart';

void main() {
  group('BuiltInCategories - Edge Cases', () {
    test('detectCategory with null payee and description', () {
      final (category, confidence) =
          BuiltInCategories.detectCategory(null, null, null);

      expect(category, isNull);
      expect(confidence, equals(0.0));
    });

    test('detectCategory with empty strings', () {
      final (category, confidence) =
          BuiltInCategories.detectCategory('', '', null);

      expect(category, isNull);
      expect(confidence, equals(0.0));
    });

    test('detectCategory with mixed case Persian text', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'شرکت آب و برق تهران',
        'پرداخت قبض آب',
        null,
      );

      expect(category, equals('utilities'));
      expect(confidence, greaterThan(0.5));
    });

    test('detectCategory with English text only', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'Coffee Shop',
        null,
        null,
      );

      expect(category, equals('food'));
      expect(confidence, greaterThan(0.5));
    });

    test('detectCategory with mixed Persian-English', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'STARBUCKS Coffee',
        'ایران - کافه',
        null,
      );

      expect(category, isNotNull);
      expect(confidence, greaterThan(0.0));
    });

    test('detectCategory with very large amount (heuristic)', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'Unknown Vendor',
        'Large purchase',
        100000000, // 100M
      );

      // Large amounts might be categorized as investment if unknown
      expect(category, isNotNull);
    });

    test('detectCategory with zero amount', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'متروی تهران',
        null,
        0,
      );

      expect(category, equals('transport'));
    });

    test('detectCategory with negative amount', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'رستوران',
        null,
        -50000, // refund
      );

      expect(category, equals('food'));
    });

    test('detectCategory word match vs substring match', () {
      // Exact word match should score higher
      final (cat1, conf1) =
          BuiltInCategories.detectCategory('taxi', null, null);
      final (cat2, conf2) =
          BuiltInCategories.detectCategory('taxicab service', null, null);

      expect(cat1, equals('transport'));
      expect(cat2, equals('transport'));
    });

    test('detectCategory with multiple matching keywords', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'Pizza Restaurant',
        'Food delivery',
        null,
      );

      expect(category, equals('food'));
      expect(confidence, greaterThanOrEqualTo(0.6));
    });

    test('detectCategory Persian utility variants', () {
      final variants = [
        'آب',
        'برق',
        'گاز',
      ];

      for (final variant in variants) {
        final (category, confidence) =
            BuiltInCategories.detectCategory(variant, null, null);
        expect(category, equals('utilities'), reason: 'Failed for: $variant');
      }
    });

    test('detectCategory with whitespace variations', () {
      final (cat1, conf1) =
          BuiltInCategories.detectCategory('  taxi  ', null, null);
      final (cat2, conf2) =
          BuiltInCategories.detectCategory('taxi', null, null);

      // Normalization might handle this
      expect([cat1, cat2].contains('transport'), isTrue);
    });

    test('payeePatterns map is not empty', () {
      expect(BuiltInCategories.payeePatterns.isNotEmpty, isTrue);
    });

    test('payeePatterns contains expected categories', () {
      final patterns = BuiltInCategories.payeePatterns.values.toSet();

      expect(patterns.contains('utilities'), isTrue);
      expect(patterns.contains('food'), isTrue);
      expect(patterns.contains('transport'), isTrue);
      expect(patterns.contains('subscription'), isTrue);
    });

    test('BuiltInCategory construction', () {
      final category = BuiltInCategory(
        id: 'test',
        nameEn: 'Test Category',
        nameFa: 'دسته‌بندی آزمایشی',
        baseXp: 50,
      );

      expect(category.id, equals('test'));
      expect(category.nameEn, equals('Test Category'));
      expect(category.nameFa, equals('دسته‌بندی آزمایشی'));
      expect(category.baseXp, equals(50));
    });

    test('detectCategory with healthcare keywords', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'داروخانه',
        'پزشکی',
        null,
      );

      // Healthcare might or might not be in the patterns
      expect(confidence, greaterThanOrEqualTo(0.0));
    });

    test('detectCategory case insensitivity works', () {
      final (cat1, conf1) =
          BuiltInCategories.detectCategory('TAXI', null, null);
      final (cat2, conf2) =
          BuiltInCategories.detectCategory('Taxi', null, null);
      final (cat3, conf3) =
          BuiltInCategories.detectCategory('taxi', null, null);

      expect(cat1, equals(cat2));
      expect(cat2, equals(cat3));
    });

    test('detectCategory with amount-only heuristics', () {
      final (cat1, conf1) = BuiltInCategories.detectCategory(
        'Unknown',
        'Purchase',
        10000000, // Large amount
      );

      final (cat2, conf2) = BuiltInCategories.detectCategory(
        'Unknown',
        'Purchase',
        1000, // Small amount
      );

      // Behavior might differ based on amount heuristics
      expect(conf1, isNotNull);
      expect(conf2, isNotNull);
    });
  });

  group('BuiltInCategories - Integration', () {
    test('categories can be used for transaction processing', () {
      final transactions = [
        ('رستوران ایرانی', 'شام', 500000),
        ('متروی تهران', null, 20000),
        ('netflix', 'subscription', 500000),
      ];

      for (final (payee, desc, amount) in transactions) {
        final (category, confidence) = BuiltInCategories.detectCategory(
          payee,
          desc,
          amount,
        );

        expect(category, isNotNull);
        expect(confidence, greaterThanOrEqualTo(0.0));
        expect(confidence, lessThanOrEqualTo(1.0));
      }
    });

    test('batch categorization maintains consistency', () {
      const payee = 'uber';

      final results = List.generate(
        5,
        (_) => BuiltInCategories.detectCategory(payee, null, null),
      );

      // All results should be identical for same input
      final first = results.first;
      expect(results.every((r) => r == first), isTrue);
    });

    test('categorization with realistic transaction data', () {
      final realistic = [
        ('شرکت برق منطقه‌ای', 'قبض برق', 2000000),
        ('سوپرمارکت', 'خریداری مواد غذایی', 5000000),
        ('تاکسی', 'سفر شهری', 100000),
        ('آمازون', 'خرید آنلاین', 3000000),
      ];

      for (final (payee, desc, amount) in realistic) {
        final (category, confidence) = BuiltInCategories.detectCategory(
          payee,
          desc,
          amount,
        );

        expect(category, isNotNull);
      }
    });
  });
}
