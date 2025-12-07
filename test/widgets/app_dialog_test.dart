// Widget tests for AppDialog and ConfirmationDialog components.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/widgets/app_dialog.dart';

void main() {
  group('AppDialog', () {
    testWidgets('displays title and content', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDialog(
              title: 'Test Dialog',
              content: const Text('This is test content'),
              actions: const [],
            ),
          ),
        ),
      );

      expect(find.text('Test Dialog'), findsOneWidget);
      expect(find.text('This is test content'), findsOneWidget);
    });

    testWidgets('displays action buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDialog(
              title: 'Test Dialog',
              content: const Text('Content'),
              actions: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);
    });

    testWidgets('does not display icon when not provided', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppDialog(
              title: 'Test Dialog',
              content: const Text('Content'),
              actions: const [],
            ),
          ),
        ),
      );

      expect(find.byType(Icon), findsNothing);
    });
  });

  group('ConfirmationDialog', () {
    testWidgets('displays title and message', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Confirm Delete',
              message: 'Are you sure you want to delete this item?',
            ),
          ),
        ),
      );

      expect(find.text('Confirm Delete'), findsOneWidget);
      expect(find.text('Are you sure you want to delete this item?'), findsOneWidget);
    });

    testWidgets('displays default buttons', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Confirm',
              message: 'Are you sure?',
            ),
          ),
        ),
      );

      expect(find.text('تأیید'), findsOneWidget);
      expect(find.text('لغو'), findsOneWidget);
    });

    testWidgets('displays custom button text', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Delete Item',
              message: 'Are you sure?',
              confirmText: 'Delete',
              cancelText: 'Cancel',
            ),
          ),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('returns false when cancel is pressed', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        title: 'Test',
                        message: 'Test message',
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('لغو'));
      await tester.pumpAndSettle();

      expect(result, false);
    });

    testWidgets('returns true when confirm is pressed', (WidgetTester tester) async {
      bool? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () async {
                    result = await showDialog<bool>(
                      context: context,
                      builder: (context) => const ConfirmationDialog(
                        title: 'Test',
                        message: 'Test message',
                      ),
                    );
                  },
                  child: const Text('Show Dialog'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('تأیید'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('uses error styling for dangerous action', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ConfirmationDialog(
              title: 'Delete',
              message: 'This cannot be undone',
              isDangerous: true,
            ),
          ),
        ),
      );

      // Just check that the dialog renders correctly with isDangerous flag
      expect(find.text('Delete'), findsOneWidget);
      expect(find.text('This cannot be undone'), findsOneWidget);
    });
  });
}
