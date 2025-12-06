import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/transaction_tile.dart';
import 'package:debt_manager/core/theme/app_colors.dart';

void main() {
  group('TransactionTile', () {
    testWidgets('displays title and amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'خرید مواد غذایی',
              amount: 50000,
              isExpense: true,
            ),
          ),
        ),
      );

      expect(find.text('خرید مواد غذایی'), findsOneWidget);
      expect(find.textContaining('50,000'), findsOneWidget);
    });

    testWidgets('shows negative sign for expenses', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Expense',
              amount: 1000,
              isExpense: true,
            ),
          ),
        ),
      );

      expect(find.textContaining('-'), findsOneWidget);
    });

    testWidgets('shows positive sign for income', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Income',
              amount: 1000,
              isExpense: false,
            ),
          ),
        ),
      );

      expect(find.textContaining('+'), findsOneWidget);
    });

    testWidgets('displays expense amount in red color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TransactionTile(
              title: 'Expense',
              amount: 1000,
              isExpense: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the amount text widget
      final amountFinder = find.textContaining('-');
      expect(amountFinder, findsOneWidget);
      
      final text = tester.widget<Text>(amountFinder);
      final colorScheme = Theme.of(tester.element(amountFinder)).colorScheme;
      
      // Should use the expense color from the theme
      expect(text.style?.color, colorScheme.expense);
    });

    testWidgets('displays income amount in green color', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: Scaffold(
            body: TransactionTile(
              title: 'Income',
              amount: 1000,
              isExpense: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the amount text widget
      final amountFinder = find.textContaining('+');
      expect(amountFinder, findsOneWidget);
      
      final text = tester.widget<Text>(amountFinder);
      final colorScheme = Theme.of(tester.element(amountFinder)).colorScheme;
      
      // Should use the income color from the theme
      expect(text.style?.color, colorScheme.income);
    });

    testWidgets('shows subtitle when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Purchase',
              subtitle: '۱۴۰۲/۰۹/۱۵',
              amount: 1000,
            ),
          ),
        ),
      );

      expect(find.text('۱۴۰۲/۰۹/۱۵'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Transaction',
              amount: 1000,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });
}
