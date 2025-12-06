import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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

  // Small animated empty state used across lists. Keeps no extra assets/deps.
  static Widget animatedEmptyState({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? svgAsset = 'assets/images/empty_state.svg',
  }) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    Widget graphic;
    try {
      graphic = SvgPicture.asset(
        svgAsset!,
        height: 120,
        color: color,
        semanticsLabel: title,
      );
    } catch (_) {
      graphic = Icon(Icons.inbox_outlined, size: 72, color: color);
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: 1.0,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            child: graphic,
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          ]
        ],
      ),
    );
  }
}
