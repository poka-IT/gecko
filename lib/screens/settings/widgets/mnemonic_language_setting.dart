import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';

/// Toggle for generating mnemonics in English instead of the app locale.
class MnemonicLanguageSetting extends StatefulWidget {
  const MnemonicLanguageSetting({super.key});

  @override
  State<MnemonicLanguageSetting> createState() => _MnemonicLanguageSettingState();
}

class _MnemonicLanguageSettingState extends State<MnemonicLanguageSetting> {
  @override
  Widget build(BuildContext context) {
    final config = ConfigService(configBox);
    final generateInEnglish = config.generateMnemonicsInEnglish;

    return InkWell(
      onTap: () {
        final newValue = !generateInEnglish;
        config.generateMnemonicsInEnglish = newValue;
        if (mounted) {
          setState(() {});
        }
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(4)),
        child: Row(
          children: [
            Icon(Icons.translate_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'generateMnemonicsInEnglish'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),
                  Text(
                    'generateMnemonicsInEnglishDescription'.tr(),
                    style: scaledTextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                  ),
                ],
              ),
            ),
            Switch(
              value: generateInEnglish,
              thumbColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (states.contains(WidgetState.selected)) {
                  return context.colorScheme.primary;
                }
                return Colors.grey[400];
              }),
              trackColor: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                if (!states.contains(WidgetState.selected)) {
                  return Colors.grey[300];
                }
                return null;
              }),
              onChanged: (bool value) {
                config.generateMnemonicsInEnglish = value;
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
