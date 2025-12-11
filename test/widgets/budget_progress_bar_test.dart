import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/budget_progress_bar.dart';
import 'package:debt_manager/core/theme/app_colors.dart';

void main() {
  group('BudgetProgressBar', () {
    testWidgets('displays progress indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(
              current: 50000,
              limit: 100000,
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('shows green color when under 60% utilization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: BudgetProgressBar(
              current: 50000,
              limit: 100000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      final colorScheme = Theme.of(tester.element(find.byType(BudgetProgressBar))).colorScheme;
      expect(progressBar.color, colorScheme.success);
    });

    testWidgets('shows orange color when between 60-90% utilization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: BudgetProgressBar(
              current: 75000,
              limit: 100000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      final colorScheme = Theme.of(tester.element(find.byType(BudgetProgressBar))).colorScheme;
      expect(progressBar.color, colorScheme.warning);
    });

    testWidgets('shows red color when over 90% utilization', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: BudgetProgressBar(
              current: 95000,
              limit: 100000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      final colorScheme = Theme.of(tester.element(find.byType(BudgetProgressBar))).colorScheme;
      expect(progressBar.color, colorScheme.danger);
    });

    testWidgets('displays percentage when showPercentage is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(
              current: 75000,
              limit: 100000,
              showPercentage: true,
            ),
          ),
        ),
      );

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('displays label when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(
              current: 50000,
              limit: 100000,
              label: 'Food Budget',
            ),
          ),
        ),
      );

      expect(find.text('Food Budget'), findsOneWidget);
    });

    testWidgets('calculates correct progress value', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(
              current: 30000,
              limit: 100000,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      expect(progressBar.value, closeTo(0.3, 0.01));
    });

    testWidgets('handles zero limit gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BudgetProgressBar(
              current: 1000,
              limit: 0,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      
      expect(progressBar.value, 0.0);
    });
  });
}
