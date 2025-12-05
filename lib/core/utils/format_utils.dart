// Formatting utilities for currency and Persian digit conversion.

/// Convert an integer to Persian digits (۰-۹).
String toPersianDigits(int value) {
  const map = {
    '0': '۰',
    '1': '۱',
    '2': '۲',
    '3': '۳',
    '4': '۴',
    '5': '۵',
    '6': '۶',
    '7': '۷',
    '8': '۸',
    '9': '۹',
  };
  final s = value.toString();
  return s.split('').map((c) => map[c] ?? c).join();
}

/// Format a currency value with thousand separators and Persian digits.
/// Example: formatCurrency(1234567) => "۱٬۲۳۴٬۵۶۷ ریال"
String formatCurrency(int value) {
  final s = value.abs().toString();
  final withSep = s.replaceAllMapped(
    RegExp(r"\B(?=(\d{3})+(?!\d))"),
    (m) => ',',
  );
  final persian = withSep.split('').map((c) {
    const map = {
      '0': '۰',
      '1': '۱',
      '2': '۲',
      '3': '۳',
      '4': '۴',
      '5': '۵',
      '6': '۶',
      '7': '۷',
      '8': '۸',
      '9': '۹',
      ',': '٬',
    };
    return map[c] ?? c;
  }).join();
  return '${value < 0 ? '-' : ''}$persian ریال';
}
