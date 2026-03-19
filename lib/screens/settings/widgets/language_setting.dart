import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';

/// Language selector dropdown.
class LanguageSetting extends StatelessWidget {
  const LanguageSetting({super.key});

  static const _systemLocaleKey = 'system';

  @override
  Widget build(BuildContext context) {
    final config = ConfigService(configBox);
    final currentLocale = context.locale;
    final isSystemLocale = config.localeOverride == null;

    final languages = <String, (String, String)>{
      _systemLocaleKey: ('systemLanguage'.tr(), '🌐'),
      'en': ('English', '🇬🇧'),
      'fr': ('Français', '🇫🇷'),
      'es': ('Español', '🇪🇸'),
      'it': ('Italiano', '🇮🇹'),
      'eo': ('Esperanto', '🟢'),
      'de': ('Deutsch', '🇩🇪'),
    };

    final currentKey = isSystemLocale ? _systemLocaleKey : currentLocale.languageCode;
    final currentLabel = languages[currentKey]?.$1 ?? languages[_systemLocaleKey]!.$1;
    final currentFlag = languages[currentKey]?.$2 ?? languages[_systemLocaleKey]!.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'language'.tr(),
          style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        ScaledSizedBox(height: 8),
        PopupMenuButton<String>(
          onSelected: (String langCode) {
            if (langCode == _systemLocaleKey) {
              config.localeOverride = null;
              context.resetLocale();
            } else {
              config.localeOverride = langCode;
              context.setLocale(Locale(langCode));
            }
          },
          itemBuilder: (BuildContext ctx) {
            return languages.entries.map((entry) {
              final langCode = entry.key;
              final label = entry.value.$1;
              final flag = entry.value.$2;
              final isSelected = langCode == currentKey;
              return PopupMenuItem<String>(
                value: langCode,
                child: Row(
                  children: [
                    Text(flag, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(label)),
                    if (isSelected) Icon(Icons.check, color: context.colorScheme.primary, size: 20),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(12), vertical: scaleSize(10)),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, color: context.colorScheme.primary, size: scaleSize(20)),
                SizedBox(width: scaleSize(8)),
                Text('$currentFlag $currentLabel', style: scaledTextStyle(fontSize: 14)),
                SizedBox(width: scaleSize(4)),
                Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodyMedium?.color),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
