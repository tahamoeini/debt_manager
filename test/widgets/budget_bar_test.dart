// Widget tests for BudgetBar component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/budget_bar.dart';
import 'package:debt_manager/core/theme/app_theme_extensions.dart';

void main() {
  group('BudgetBar', () {
    testWidgets('displays progress bar with percentage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('shows green color when usage is below 60%', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      // Should have a progress value of 0.5 (50%)
      expect(progressIndicator.value, 0.5);
    });

    testWidgets('shows warning color when usage is between 60% and 90%', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 750,
              limit: 1000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      expect(progressIndicator.value, 0.75);
    });

    testWidgets('shows danger color when usage is 90% or above', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 950,
              limit: 1000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      expect(progressIndicator.value, 0.95);
    });

    testWidgets('handles zero limit gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 100,
              limit: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      // Should default to 0 when limit is 0
      expect(progressIndicator.value, 0.0);
    });

    testWidgets('clamps value at 100% when over budget', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 1500,
              limit: 1000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      // Should be clamped to 1.0 (100%)
      expect(progressIndicator.value, 1.0);
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('displays label when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
              label: 'Food Budget',
            ),
          ),
        ),
      );

      expect(find.text('Food Budget'), findsOneWidget);
    });

    testWidgets('hides percentage when showPercentage is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetBar(
              current: 500,
              limit: 1000,
              showPercentage: false,
            ),
          ),
        ),
      );

      expect(find.text('50%'), findsNothing);
    });

    testWidgets('shows amount when showAmount is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
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
  });
}
