/// Debug utilities: central toggle for debug logging across the app.

/// Set to `true` during development to enable verbose data-load logs.
const bool kDebugLogging = false;

/// Helper to conditionally print debug messages.
void debugLog(String msg) {
  if (kDebugLogging) {
    // Use debugPrint to avoid flooding synchronous IO in release builds.
    // ignore: avoid_print
    debugPrint(msg);
  }
}
