import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A reusable error page for invalid route parameter IDs.
/// 
/// Displays a user-friendly error message with an icon and a button
/// to navigate back to a safe location.
class InvalidIdErrorPage extends StatelessWidget {
  const InvalidIdErrorPage({
    super.key,
    required this.title,
    required this.message,
    required this.returnRoute,
    required this.returnButtonText,
  });

  /// The title shown in the app bar
  final String title;
  
  /// The error message shown to the user
  final String message;
  
  /// The route to navigate to when the return button is pressed
  final String returnRoute;
  
  /// The text shown on the return button
  final String returnButtonText;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(returnRoute),
              child: Text(returnButtonText),
            ),
          ],
        ),
      ),
    );
  }
}
