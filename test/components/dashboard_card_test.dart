import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/components/dashboard_card.dart';

void main() {
  group('DashboardCard', () {
    testWidgets('displays title and value correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Title',
              value: '1,234',
            ),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });

    testWidgets('displays optional subtitle', (tester) async {
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

      expect(find.text('Test Subtitle'), findsOneWidget);
    });

    testWidgets('displays optional icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Title',
              value: '1,234',
              icon: Icons.account_balance_wallet,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('shows loading indicator when isLoading is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Title',
              value: '1,234',
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('1,234'), findsNothing);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Test Title',
              value: '1,234',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      expect(tapped, true);
    });
  });

  group('StatCard', () {
    testWidgets('displays correctly with required properties', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Balance',
              value: '5,000',
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.text('Balance'), findsOneWidget);
      expect(find.text('5,000'), findsOneWidget);
    });
  });
}
