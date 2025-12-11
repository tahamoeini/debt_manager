// Widget tests for TransactionTile component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/transaction_tile.dart';

void main() {
  group('TransactionTile', () {
    testWidgets('displays title and amount', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
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

      // Find the title text
      expect(find.text('Salary'), findsOneWidget);
      
      // Check that income icon is displayed
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('displays expense transaction', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
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

      // Find the title text
      expect(find.text('Groceries'), findsOneWidget);
      
      // Check that expense icon is displayed
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });
  });
}
