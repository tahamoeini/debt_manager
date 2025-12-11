import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/dashboard_card.dart';
import 'package:debt_manager/core/widgets/stat_card.dart';

void main() {
  group('DashboardCard', () {
    testWidgets('displays title, value, and subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Total Balance',
              value: '۱۲۳٬۴۵۶ ریال',
              subtitle: 'Assets - Debts',
            ),
          ),
        ),
      );

      expect(find.text('Total Balance'), findsOneWidget);
      expect(find.text('۱۲۳٬۴۵۶ ریال'), findsOneWidget);
      expect(find.text('Assets - Debts'), findsOneWidget);
    });

    testWidgets('shows icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '۱۰۰',
              icon: Icons.account_balance_wallet,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.account_balance_wallet), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DashboardCard(
              title: 'Balance',
              value: '۱۰۰',
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(tapped, isTrue);
    });
  });

  group('StatCard', () {
    testWidgets('displays title and value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Budget Left',
              value: '۵۰٬۰۰۰ ریال',
            ),
          ),
        ),
      );

      expect(find.text('Budget Left'), findsOneWidget);
      expect(find.text('۵۰٬۰۰۰ ریال'), findsOneWidget);
    });

    testWidgets('applies custom color when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              title: 'Budget',
              value: '۱۰۰',
              color: Colors.green,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('۱۰۰'));
      expect(text.style?.color, Colors.green);
    });
  });
}
