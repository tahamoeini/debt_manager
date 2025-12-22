import 'package:flutter/foundation.dart';

/// Standardized error handling and logging utility.
///
/// Provides consistent error logging, user-friendly messages,
/// and structured error reporting across the app.
class ErrorHandler {
  static const String _prefix = 'DebtManager';

  /// Log an error with context.
  /// In debug mode, prints full stack trace.
  /// In release mode, logs essential info only.
  static void logError(
    String context,
    dynamic error, [
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String();
    final message = '$_prefix [$context] Error at $timestamp: $error';

    if (kDebugMode) {
      debugPrint(message);
      if (stackTrace != null) {
        debugPrint('Stack trace:\n$stackTrace');
      }
    } else {
      // In production, you might send to analytics/crash reporting
      // For now, just log essential info
      debugPrint(message);
    }
  }

  /// Log a warning with context.
  static void logWarning(String context, String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('$_prefix [$context] Warning at $timestamp: $message');
  }

  /// Log an info message with context.
  static void logInfo(String context, String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      debugPrint('$_prefix [$context] Info at $timestamp: $message');
    }
  }

  /// Get user-friendly error message from exception.
  /// Strips technical details and provides localized messages.
  static String getUserMessage(dynamic error, {String? fallback}) {
    if (error == null) return fallback ?? 'خطای نامشخص';

    // Map common errors to user-friendly Persian messages
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'خطای اتصال به شبکه';
    }

    if (errorStr.contains('timeout')) {
      return 'زمان انتظار به پایان رسید';
    }

    if (errorStr.contains('permission')) {
      return 'دسترسی مورد نیاز وجود ندارد';
    }

    if (errorStr.contains('database') || errorStr.contains('sql')) {
      return 'خطا در ذخیره‌سازی داده';
    }

    if (errorStr.contains('authentication') || errorStr.contains('pin')) {
      return 'خطای احراز هویت';
    }

    if (errorStr.contains('encryption')) {
      return 'خطای رمزگذاری';
    }

    // Return fallback or generic message
    return fallback ?? 'خطایی رخ داده است';
  }

  /// Wrap an async operation with error handling.
  /// Logs errors and optionally shows user message.
  static Future<T?> handleAsync<T>({
    required String context,
    required Future<T> Function() operation,
    void Function(String message)? onError,
    String? fallbackMessage,
  }) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      logError(context, error, stackTrace);

      if (onError != null) {
        final userMessage = getUserMessage(error, fallback: fallbackMessage);
        onError(userMessage);
      }

      return null;
    }
  }

  /// Wrap a sync operation with error handling.
  static T? handleSync<T>({
    required String context,
    required T Function() operation,
    void Function(String message)? onError,
    String? fallbackMessage,
  }) {
    try {
      return operation();
    } catch (error, stackTrace) {
      logError(context, error, stackTrace);

      if (onError != null) {
        final userMessage = getUserMessage(error, fallback: fallbackMessage);
        onError(userMessage);
      }

      return null;
    }
  }

  /// Log a non-critical operation that failed but app can continue.
  /// Example: notification scheduling fails, but loan creation succeeds.
  static void logNonCritical(String context, String operation, dynamic error) {
    logWarning(
      context,
      'Non-critical operation failed: $operation - $error',
    );
  }
}

/// Extension on String for logging contexts.
extension ErrorContextExtension on String {
  void logError(dynamic error, [StackTrace? stackTrace]) {
    ErrorHandler.logError(this, error, stackTrace);
  }

  void logWarning(String message) {
    ErrorHandler.logWarning(this, message);
  }

  void logInfo(String message) {
    ErrorHandler.logInfo(this, message);
  }
}
