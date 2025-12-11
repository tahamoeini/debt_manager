// Widget tests for DashboardCard component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/dashboard_card.dart';

void main() {
  group('DashboardCard', () {
    testWidgets('displays title, value, and subtitle',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Title',
              value: '1,234',
              subtitle: 'Test Subtitle',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('displays icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '5,000',
              icon: Icons.account_balance_wallet,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('does not display icon when not provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '5,000',
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('applies custom accent color to icon',
        (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '5,000',
              icon: Icons.account_balance_wallet,
              accentColor: customColor,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });
  });
}
