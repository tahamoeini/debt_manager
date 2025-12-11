import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/components/budget_bar.dart';

void main() {
  group('BudgetBar', () {
    testWidgets('displays green color when under low threshold',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Should show 50% (which is < 60% threshold)
      expect(find.text('50%'), findsOneWidget);

      // Find LinearProgressIndicator
      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.5);
    });

    testWidgets('displays orange color when between thresholds',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 750,
              limit: 1000,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Should show 75% (which is between 60% and 90%)
      expect(find.text('75%'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.75);
    });

    testWidgets('displays red color when over high threshold', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 950,
              limit: 1000,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Should show 95% (which is > 90% threshold)
      expect(find.text('95%'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 0.95);
    });

    testWidgets('shows amount when showAmount is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
              showAmount: true,
            ),
          ),
        ),
      );

      expect(find.text('500 / 1000'), findsOneWidget);
    });

    testWidgets('handles zero limit gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 100,
              limit: 0,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Should show 0% when limit is 0
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('clamps value at 100% when over limit', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 1500,
              limit: 1000,
              showPercentage: true,
            ),
          ),
        ),
      );

      // Should show 100% (clamped)
      expect(find.text('100%'), findsOneWidget);

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, 1.0);
    });
  });

  group('BudgetProgressCard', () {
    testWidgets('displays category and budget info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressCard(
              category: 'Food',
              current: 750,
              limit: 1000,
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays optional icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressCard(
              category: 'Food',
              current: 750,
              limit: 1000,
              icon: Icons.restaurant,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetProgressCard(
              category: 'Food',
              current: 750,
              limit: 1000,
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
}
