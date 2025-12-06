// Widget tests for DashboardCard component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/dashboard_card.dart';

void main() {
  group('DashboardCard', () {
    testWidgets('displays title, value, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
        MaterialApp(
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

    testWidgets('does not display icon when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('displays action widget when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '5,000',
              action: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
    });

    testWidgets('applies custom color to icon', (WidgetTester tester) async {
      const customColor = Colors.red;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '5,000',
              icon: Icons.account_balance_wallet,
              color: customColor,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.account_balance_wallet));
      expect(icon.color, customColor);
    });
  });
}
