// Widget tests for CategoryIcon component.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/category_icon.dart';

void main() {
  group('CategoryIcon', () {
    testWidgets('displays icon for known category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsOneWidget);
    });

    testWidgets('displays default icon for unknown category', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'unknown_category',
              size: 40,
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.category), findsOneWidget);
    });

    testWidgets('uses custom icon when provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              size: 40,
              icon: Icons.fastfood,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.fastfood), findsOneWidget);
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('respects custom size', (WidgetTester tester) async {
      const customSize = 60.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              size: customSize,
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.radius, customSize / 2);
    });

    testWidgets('uses custom color when provided', (WidgetTester tester) async {
      const customColor = Colors.purple;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              size: 40,
              backgroundColor: customColor,
            ),
          ),
        ),
      );

      final circleAvatar = tester.widget<CircleAvatar>(find.byType(CircleAvatar));
      expect(circleAvatar.backgroundColor, customColor);
    });
  });

  group('CategoryIconWithLabel', () {
    testWidgets('displays icon and label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIconWithLabel(
              category: 'food',
              label: 'Food & Dining',
              icon: Icons.restaurant,
            ),
          ),
        ),
      );

      expect(find.byType(CategoryIcon), findsOneWidget);
      expect(find.text('Food & Dining'), findsOneWidget);
    });

    testWidgets('displays icon above label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIconWithLabel(
              category: 'transport',
              label: 'Transportation',
              icon: Icons.directions_car,
            ),
          ),
        ),
      );

      final column = tester.widget<Column>(find.byType(Column));
      expect(column.children.length, 3); // Icon, SizedBox, Text
    });
  });
}
