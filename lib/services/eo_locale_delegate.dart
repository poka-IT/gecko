import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/cupertino.dart';

/// Fallback [MaterialLocalizations] delegate for unsupported locales (e.g. Esperanto).
/// Falls back to English strings while keeping the correct locale code.
class _EoMaterialLocalizationsDelegate extends LocalizationsDelegate<MaterialLocalizations> {
  const _EoMaterialLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'eo';

  @override
  Future<MaterialLocalizations> load(Locale locale) => GlobalMaterialLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<MaterialLocalizations> old) => false;
}

/// Fallback [CupertinoLocalizations] delegate for unsupported locales (e.g. Esperanto).
class _EoCupertinoLocalizationsDelegate extends LocalizationsDelegate<CupertinoLocalizations> {
  const _EoCupertinoLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == 'eo';

  @override
  Future<CupertinoLocalizations> load(Locale locale) => GlobalCupertinoLocalizations.delegate.load(const Locale('en'));

  @override
  bool shouldReload(covariant LocalizationsDelegate<CupertinoLocalizations> old) => false;
}

const eoLocalizationDelegates = <LocalizationsDelegate<dynamic>>[
  _EoMaterialLocalizationsDelegate(),
  _EoCupertinoLocalizationsDelegate(),
];
