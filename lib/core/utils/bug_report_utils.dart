import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:debt_manager/core/theme/app_constants.dart';

/// Utility class for generating and sharing bug reports.
class BugReportUtils {
  BugReportUtils._();

  /// Generates a unique error ID based on timestamp
  static String generateErrorId() {
    return 'ERR-${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Captures a screenshot of the current screen
  static Future<File?> captureScreenshot(GlobalKey key) async {
    try {
      // Find the RenderRepaintBoundary
      final RenderRepaintBoundary? boundary = 
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      
      if (boundary == null) {
        return null;
      }

      // Capture the image
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        return null;
      }

      // Save to temporary directory
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/bug_report_screenshot.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      
      return file;
    } catch (e) {
      debugPrint('Error capturing screenshot: $e');
      return null;
    }
  }

  /// Prepares and shares a bug report via email
  static Future<void> shareBugReport({
    required BuildContext context,
    String? errorMessage,
    String? appState,
    GlobalKey? screenshotKey,
  }) async {
    try {
      // Generate error ID
      final errorId = generateErrorId();
      
      // Prepare email body
      final StringBuffer body = StringBuffer();
      body.writeln('مدیریت اقساط و بدهی‌ها - گزارش مشکل\n');
      body.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      body.writeln('لطفاً شرح دهید:\n');
      body.writeln('• چه کاری انجام می‌دادید؟');
      body.writeln('• چه مشکلی رخ داد؟');
      body.writeln('• پیشنهاد یا نظر خود را بنویسید:\n\n\n');
      body.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      body.writeln('اطلاعات فنی (لطفاً این بخش را حذف نکنید):');
      body.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      body.writeln('شناسه گزارش: $errorId');
      body.writeln('تاریخ و زمان: ${DateTime.now()}');
      
      if (errorMessage != null && errorMessage.isNotEmpty) {
        body.writeln('پیام خطا: $errorMessage');
      }
      
      if (appState != null && appState.isNotEmpty) {
        body.writeln('وضعیت برنامه: $appState');
      }
      
      body.writeln('\nاطلاعات سیستم:');
      body.writeln('• پلتفرم: ${Platform.operatingSystem}');
      body.writeln('• نسخه سیستم: ${Platform.operatingSystemVersion}');
      
      // Try to capture screenshot
      File? screenshot;
      if (screenshotKey != null) {
        screenshot = await captureScreenshot(screenshotKey);
      }

      // Share via email client
      if (screenshot != null) {
        await Share.shareXFiles(
          [XFile(screenshot.path)],
          subject: 'گزارش مشکل - مدیریت اقساط و بدهی‌ها [$errorId]',
          text: body.toString(),
        );
      } else {
        // Share without screenshot
        await Share.share(
          body.toString(),
          subject: 'گزارش مشکل - مدیریت اقساط و بدهی‌ها [$errorId]',
        );
      }
    } catch (e) {
      debugPrint('Error sharing bug report: $e');
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطا در ارسال گزارش: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Shows a dialog to collect user feedback before sending bug report
  static Future<void> showBugReportDialog({
    required BuildContext context,
    String? errorMessage,
    String? appState,
    GlobalKey? screenshotKey,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('گزارش مشکل یا پیشنهاد'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'با ارسال گزارش مشکل، به بهبود این برنامه کمک می‌کنید.',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (errorMessage != null && errorMessage.isNotEmpty) ...[
                  const Text(
                    'پیام خطا:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(dialogContext).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Text(
                  'یک ایمیل با جزئیات مشکل و تصویر صفحه آماده می‌شود که می‌توانید آن را ارسال کنید.',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('لغو'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                // Use the original context for the share operation
                await shareBugReport(
                  context: context,
                  errorMessage: errorMessage,
                  appState: appState,
                  screenshotKey: screenshotKey,
                );
              },
              icon: const Icon(Icons.send),
              label: const Text('ارسال گزارش'),
            ),
          ],
        );
      },
    );
  }
}
