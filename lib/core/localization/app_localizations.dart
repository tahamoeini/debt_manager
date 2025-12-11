import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  late Map<String, String> _strings;

  AppLocalizations(this.locale);

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static Future<AppLocalizations> load(Locale locale) async {
    final obj = AppLocalizations(locale);
    final path = 'l10n/intl_${locale.languageCode}.arb';
    try {
      final raw = await rootBundle.loadString(path);
      final map = json.decode(raw) as Map<String, dynamic>;
      obj._strings = map.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      obj._strings = {};
    }
    return obj;
  }

  String t(String key) => _strings[key] ?? key;

  static AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'fa'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) => AppLocalizations.load(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
