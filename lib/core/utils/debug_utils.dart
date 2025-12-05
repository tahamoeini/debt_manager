import 'package:flutter/foundation.dart' show debugPrint;

const bool kDebugLogging = false;

// Debug utilities: central toggle for debug logging across the app.
// Set to `true` during development to enable verbose data-load logs.
// Helper to conditionally print debug messages.
void debugLog(String msg) {
  if (kDebugLogging) {
    debugPrint(msg);
  }
}
