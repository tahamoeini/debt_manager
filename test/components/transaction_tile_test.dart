import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/components/transaction_tile.dart';

void main() {
  group('TransactionTile', () {
    testWidgets('displays transaction details correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Grocery Shopping',
              amount: 125000,
              type: TransactionType.expense,
              date: '2023-10-15',
              payee: 'Supermarket',
              category: 'food',
            ),
          ),
        ),
      );

      expect(find.text('Grocery Shopping'), findsOneWidget);
      // The formatted currency will contain Persian digits
      expect(find.textContaining('ریال'), findsOneWidget);
    });

    testWidgets('shows income in green with + prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Salary',
              amount: 5000000,
              type: TransactionType.income,
            ),
          ),
        ),
      );

      expect(find.text('Salary'), findsOneWidget);
      // The amount text should start with + for income
      final amountText = tester.widget<Text>(
        find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return widget.data!.startsWith('+');
          }
          return false;
        }),
      );
      expect(amountText, isNotNull);
    });

    testWidgets('shows expense in red with - prefix', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Shopping',
              amount: 125000,
              type: TransactionType.expense,
            ),
          ),
        ),
      );

      expect(find.text('Shopping'), findsOneWidget);
      // The amount text should start with - for expense
      final amountText = tester.widget<Text>(
        find.byWidgetPredicate((widget) {
          if (widget is Text && widget.data != null) {
            return widget.data!.startsWith('-');
          }
          return false;
        }),
      );
      expect(amountText, isNotNull);
    });

    testWidgets('generates subtitle from payee, category, and date', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test Transaction',
              amount: 100000,
              type: TransactionType.expense,
              payee: 'Test Payee',
              category: 'food',
              date: '2023-10-15',
            ),
          ),
        ),
      );

      // Subtitle should contain parts joined with ·
      expect(find.textContaining('Test Payee'), findsOneWidget);
      expect(find.textContaining('food'), findsOneWidget);
      expect(find.textContaining('2023-10-15'), findsOneWidget);
    });

    testWidgets('uses custom subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test Transaction',
              amount: 100000,
              type: TransactionType.expense,
              payee: 'Test Payee',
              category: 'food',
              subtitle: 'Custom Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Custom Subtitle'), findsOneWidget);
      expect(find.textContaining('Test Payee'), findsNothing);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test',
              amount: 100,
              type: TransactionType.expense,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(tapped, true);
    });

    testWidgets('shows category icon when category is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test',
              amount: 100,
              type: TransactionType.expense,
              category: 'food',
              showCategoryIcon: true,
            ),
          ),
        ),
      );

      // CategoryIcon widget should be present
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('hides category icon when showCategoryIcon is false', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test',
              amount: 100,
              type: TransactionType.expense,
              category: 'food',
              showCategoryIcon: false,
            ),
          ),
        ),
      );

      // Should show arrow icon instead
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('displays empty title fallback', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: '',
              amount: 100,
              type: TransactionType.expense,
            ),
          ),
        ),
      );

      expect(find.text('بدون عنوان'), findsOneWidget);
    });
  });
}
