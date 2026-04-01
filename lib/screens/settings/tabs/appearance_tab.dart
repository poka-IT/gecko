import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/settings/settings_card.dart';
import 'package:gecko/screens/settings/widgets/background_image_setting.dart';
import 'package:gecko/screens/settings/widgets/language_setting.dart';
import 'package:gecko/screens/settings/widgets/text_size_setting.dart';
import 'package:gecko/screens/settings/widgets/theme_setting.dart';

/// Appearance tab: theme, language, text size, background image.
class AppearanceTab extends StatelessWidget {
  const AppearanceTab({super.key});

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.height < 700;
    final padding = scaleSize(isSmallScreen ? 10 : 14);
    final spacing = ScaledSizedBox(height: isSmallScreen ? 12 : 16);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScaledSizedBox(height: isSmallScreen ? 12 : 20),
            SettingsCard(
              child: Padding(padding: EdgeInsets.all(padding), child: const ThemeSetting()),
            ),
            spacing,
            SettingsCard(
              child: Padding(padding: EdgeInsets.all(padding), child: const LanguageSetting()),
            ),
            spacing,
            SettingsCard(
              child: Padding(padding: EdgeInsets.all(padding), child: const TextSizeSetting()),
            ),
            spacing,
            SettingsCard(
              child: Padding(padding: EdgeInsets.all(padding), child: const BackgroundImageSetting()),
            ),
            ScaledSizedBox(height: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }
}
