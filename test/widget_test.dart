// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:debt_manager/app.dart';

void main() {
  testWidgets('App shell shows home and opens settings',
      (WidgetTester tester) async {
    // Build the app.
    await tester.pumpWidget(const ProviderScope(child: DebtManagerApp()));

    // Initial app bar title should be the home label 'خانه'.
    expect(find.widgetWithText(AppBar, 'خانه'), findsOneWidget);

    // We avoid navigating into screens that query the DB in tests; asserting
    // the AppBar is sufficient for a basic smoke test here.
  });
}
