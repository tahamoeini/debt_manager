import 'package:flutter_test/flutter_test.dart';
import 'package:debt_manager/core/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    test('getUserMessage returns appropriate message for network errors', () {
      final message1 = ErrorHandler.getUserMessage(Exception('Network error'));
      expect(message1, 'خطای اتصال به شبکه');

      final message2 =
          ErrorHandler.getUserMessage(Exception('Connection timeout'));
      expect(message2, 'خطای اتصال به شبکه');
    });

    test('getUserMessage returns appropriate message for timeout errors', () {
      final message = ErrorHandler.getUserMessage(Exception('Request timeout'));
      expect(message, 'زمان انتظار به پایان رسید');
    });

    test('getUserMessage returns appropriate message for database errors', () {
      final message1 = ErrorHandler.getUserMessage(Exception('Database error'));
      expect(message1, 'خطا در ذخیره‌سازی داده');

      final message2 =
          ErrorHandler.getUserMessage(Exception('SQL syntax error'));
      expect(message2, 'خطا در ذخیره‌سازی داده');
    });

    test('getUserMessage returns fallback for unknown errors', () {
      final message = ErrorHandler.getUserMessage(
        Exception('Unknown error'),
        fallback: 'پیام سفارشی',
      );
      expect(message, 'پیام سفارشی');
    });

    test('getUserMessage returns default fallback when no specific match', () {
      final message = ErrorHandler.getUserMessage(Exception('Random error'));
      expect(message, 'خطایی رخ داده است');
    });

    test('handleAsync executes operation and returns result on success',
        () async {
      final result = await ErrorHandler.handleAsync<int>(
        context: 'test',
        operation: () async => 42,
      );
      expect(result, 42);
    });

    test('handleAsync catches error and returns null on failure', () async {
      final result = await ErrorHandler.handleAsync<int>(
        context: 'test',
        operation: () async => throw Exception('Test error'),
      );
      expect(result, null);
    });

    test('handleAsync calls onError with user message on failure', () async {
      String? errorMessage;

      await ErrorHandler.handleAsync<int>(
        context: 'test',
        operation: () async => throw Exception('Database error'),
        onError: (msg) => errorMessage = msg,
      );

      expect(errorMessage, 'خطا در ذخیره‌سازی داده');
    });

    test('handleSync executes operation and returns result on success', () {
      final result = ErrorHandler.handleSync<int>(
        context: 'test',
        operation: () => 42,
      );
      expect(result, 42);
    });

    test('handleSync catches error and returns null on failure', () {
      final result = ErrorHandler.handleSync<int>(
        context: 'test',
        operation: () => throw Exception('Test error'),
      );
      expect(result, null);
    });

    test('handleSync calls onError with user message on failure', () {
      String? errorMessage;

      ErrorHandler.handleSync<int>(
        context: 'test',
        operation: () => throw Exception('Permission denied'),
        onError: (msg) => errorMessage = msg,
      );

      expect(errorMessage, 'دسترسی مورد نیاز وجود ندارد');
    });
  });

  group('ErrorContextExtension', () {
    test('logError extension works', () {
      // Just verify it doesn't throw
      expect(() => 'TestContext'.logError(Exception('Test')), returnsNormally);
    });

    test('logWarning extension works', () {
      expect(() => 'TestContext'.logWarning('Test warning'), returnsNormally);
    });

    test('logInfo extension works', () {
      expect(() => 'TestContext'.logInfo('Test info'), returnsNormally);
    });
  });

  group('Error message localization', () {
    test('all error messages are in Persian', () {
      final testCases = [
        Exception('network'),
        Exception('timeout'),
        Exception('permission'),
        Exception('database'),
        Exception('authentication'),
        Exception('encryption'),
        Exception('unknown'),
      ];

      for (final error in testCases) {
        final message = ErrorHandler.getUserMessage(error);
        // Verify message contains Persian characters
        expect(message, matches(RegExp(r'[\u0600-\u06FF]')));
      }
    });
  });
}
