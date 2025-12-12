import 'dart:collection';
import 'package:flutter/foundation.dart';

// Simple in-memory debug logger used in debug builds.
class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  final _lines = ListQueue<String>();
  final int _max = 200;

  // Value notifier to enable visual debug overlay in the app (debug only).
  static final ValueNotifier<bool> overlayEnabled = ValueNotifier<bool>(false);

  // Value notifier to enable widget bounds overlay.
  static final ValueNotifier<bool> showBoundsEnabled =
      ValueNotifier<bool>(false);

  void log(String message) {
    final line = '[LOG ${DateTime.now().toIso8601String()}] $message';
    _add(line);
    if (kDebugMode) debugPrint(line);
  }

  void error(Object error, [StackTrace? st]) {
    final line = '[ERROR ${DateTime.now().toIso8601String()}] $error';
    _add(line);
    if (kDebugMode) {
      debugPrint(line);
      if (st != null) debugPrint('$st');
    }
  }

  void _add(String line) {
    _lines.addFirst(line);
    while (_lines.length > _max) {
      _lines.removeLast();
    }
  }

  // Returns recent log lines (newest first).
  List<String> recent([int count = 50]) => _lines.take(count).toList();
}
