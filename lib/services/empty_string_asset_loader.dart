import 'dart:convert';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';

/// Asset loader that filters out empty string values from translation files.
///
/// Weblate adds all translation keys to every locale file, even when
/// untranslated, using empty strings as values. Since easy_localization
/// only falls back to the fallback locale when a key is *missing*, empty
/// strings bypass the fallback mechanism and produce blank UI text.
///
/// This loader removes empty string entries so that easy_localization
/// properly falls back to English for untranslated keys.
class EmptyStringAssetLoader extends AssetLoader {
  const EmptyStringAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) async {
    final data = await rootBundle.loadString('$path/${locale.toStringWithSeparator()}.json');
    final map = json.decode(data) as Map<String, dynamic>;
    return _removeEmptyStrings(map);
  }

  Map<String, dynamic> _removeEmptyStrings(Map<String, dynamic> map) {
    final result = <String, dynamic>{};
    for (final entry in map.entries) {
      if (entry.value is String && (entry.value as String).isEmpty) {
        continue;
      }
      if (entry.value is Map<String, dynamic>) {
        final nested = _removeEmptyStrings(entry.value as Map<String, dynamic>);
        if (nested.isNotEmpty) {
          result[entry.key] = nested;
        }
        continue;
      }
      result[entry.key] = entry.value;
    }
    return result;
  }
}
