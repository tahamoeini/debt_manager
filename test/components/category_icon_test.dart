import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/components/category_icon.dart';

void main() {
  group('CategoryIcon', () {
    testWidgets('displays icon style correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              style: CategoryIconStyle.icon,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsOneWidget);
    });

    testWidgets('displays circle style correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'transport',
              style: CategoryIconStyle.circle,
            ),
          ),
        ),
      );

      // Should have a Container with circular decoration
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });

    testWidgets('displays square style correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'shopping',
              style: CategoryIconStyle.square,
            ),
          ),
        ),
      );

      // Should have a Container with rounded rectangle
      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, isNotNull);
    });

    testWidgets('displays dot style correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'utilities',
              style: CategoryIconStyle.dot,
              size: 12,
            ),
          ),
        ),
      );

      // Should have a Container with circular shape but no icon
      final container = tester.widget<Container>(
        find.byType(Container),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('uses custom icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              customIcon: Icons.star,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_outlined), findsNothing);
    });

    testWidgets('handles null category gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: null,
              style: CategoryIconStyle.icon,
            ),
          ),
        ),
      );

      // Should display default icon
      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('respects custom size', (tester) async {
      const customSize = 48.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              category: 'food',
              style: CategoryIconStyle.circle,
              size: customSize,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(container.constraints?.minWidth, customSize);
      expect(container.constraints?.minHeight, customSize);
    });
  });

  group('CategoryChip', () {
    testWidgets('displays category name', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: 'Food',
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);
    });

    testWidgets('displays icon when showIcon is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: 'food',
              showIcon: true,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsOneWidget);
    });

    testWidgets('hides icon when showIcon is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: 'food',
              showIcon: false,
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('shows selected state correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: 'Food',
              isSelected: true,
            ),
          ),
        ),
      );

      final text = tester.widget<Text>(find.text('Food'));
      expect(text.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('is tappable when onTap is provided', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryChip(
              category: 'Food',
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
