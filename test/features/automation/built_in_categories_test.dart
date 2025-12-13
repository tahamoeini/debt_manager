import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/features/automation/built_in_categories.dart';

void main() {
  group('BuiltInCategories', () {
    test('detectCategory returns utilities for water-related payees', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'شرکت آب و برق',
        null,
        null,
      );

      expect(category, equals('utilities'));
      expect(confidence, greaterThan(0.5));
    });

    test('detectCategory detects food/restaurants', () {
      final (category, _) = BuiltInCategories.detectCategory(
        'Restaurant Pizza House',
        null,
        null,
      );

      expect(category, equals('food'));
    });

    test('detectCategory detects transport/taxi', () {
      final (category, _) = BuiltInCategories.detectCategory(
        'Uber',
        'Trip from A to B',
        50000,
      );

      expect(category, equals('transport'));
    });

    test('detectCategory detects subscriptions', () {
      final (category, _) = BuiltInCategories.detectCategory(
        'Netflix Monthly',
        null,
        null,
      );

      expect(category, equals('subscription'));
    });

    test('detectCategory returns nil for unknown payee', () {
      final (category, confidence) = BuiltInCategories.detectCategory(
        'Random XYZ Company',
        null,
        null,
      );

      expect(category, isNull);
      expect(confidence, equals(0.0));
    });

    test('detectCategory uses amount hints for large transactions', () {
      final (category, _) = BuiltInCategories.detectCategory(
        'Unknown Payee',
        null,
        10000000,
      );

      expect(category, equals('investment')); // heuristic for large amount
    });

    test('categories map has all entries', () {
      expect(BuiltInCategories.categories, isNotEmpty);
      expect(BuiltInCategories.categories.containsKey('utilities'), isTrue);
      expect(BuiltInCategories.categories.containsKey('food'), isTrue);
      expect(BuiltInCategories.categories.containsKey('loan'), isTrue);
    });

    test('payee patterns include Persian and English', () {
      expect(BuiltInCategories.payeePatterns.containsKey('رستوران'), isTrue);
      expect(BuiltInCategories.payeePatterns.containsKey('restaurant'), isTrue);
    });
  });
}
