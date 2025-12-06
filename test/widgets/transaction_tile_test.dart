// Widget tests for TransactionTile component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/transaction_tile.dart';

void main() {
  group('TransactionTile', () {
    testWidgets('displays income transaction in green', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Salary',
              amount: 5000,
              type: TransactionType.income,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the formatted amount text
      expect(find.textContaining('+'), findsOneWidget);
      
      // Check that income icon is displayed
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('displays expense transaction in red', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Groceries',
              amount: 150,
              type: TransactionType.expense,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the formatted amount text with negative sign
      expect(find.textContaining('-'), findsOneWidget);
      
      // Check that expense icon is displayed
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('displays title and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Shopping',
              subtitle: '2024-01-15',
              amount: 250,
              type: TransactionType.expense,
            ),
          ),
        ),
      );

      expect(find.text('Shopping'), findsOneWidget);
      expect(find.text('2024-01-15'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test',
              amount: 100,
              type: TransactionType.income,
              onTap: () {
                wasTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ListTile));
      expect(wasTapped, true);
    });

    testWidgets('uses custom icon when provided', (WidgetTester tester) async {
      const customIcon = Icons.shopping_cart;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Shopping',
              amount: 100,
              type: TransactionType.expense,
              icon: customIcon,
            ),
          ),
        ),
      );

      expect(find.byIcon(customIcon), findsOneWidget);
    });

    testWidgets('displays custom trailing widget when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TransactionTile(
              title: 'Test',
              amount: 100,
              type: TransactionType.income,
              trailing: const Icon(Icons.check_circle),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
