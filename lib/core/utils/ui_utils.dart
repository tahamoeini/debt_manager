import 'package:flutter/material.dart';

// Small UI helpers used across screens for consistent SnackBar and async
// error/waiting states.
class UIUtils {
  static const snackBarDuration = Duration(seconds: 3);

  static void showAppSnackBar(BuildContext context, String message) {
    final sb = SnackBar(
      content: Text(message),
      duration: snackBarDuration,
      behavior: SnackBarBehavior.floating,
    );
    ScaffoldMessenger.of(context).showSnackBar(sb);
  }

  static Widget asyncErrorWidget(Object? error) {
    // Friendly Farsi message; callers should also debugPrint the error.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'متأسفانه در بارگذاری داده‌ها مشکلی رخ داد. لطفاً مجدداً تلاش کنید.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static Widget centeredLoading() =>
      const Center(child: CircularProgressIndicator());
}
