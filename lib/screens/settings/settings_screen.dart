import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/screens/settings/settings_card.dart';
import 'package:gecko/screens/settings/widgets/background_image_setting.dart';
import 'package:gecko/screens/settings/widgets/clear_cache_setting.dart';
import 'package:gecko/screens/settings/widgets/currency_setting.dart';
import 'package:gecko/screens/settings/widgets/delete_safes_setting.dart';
import 'package:gecko/screens/settings/widgets/expert_mode_setting.dart';
import 'package:gecko/screens/settings/widgets/language_setting.dart';
import 'package:gecko/screens/settings/widgets/mnemonic_language_setting.dart';
import 'package:gecko/screens/settings/widgets/network_section.dart';
import 'package:gecko/screens/settings/widgets/sentry_setting.dart';
import 'package:gecko/screens/settings/widgets/text_size_setting.dart';
import 'package:gecko/screens/settings/widgets/theme_setting.dart';
import 'package:gecko/screens/settings/widgets/window_size_setting.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  /// When true, renders without Scaffold/AppBar (for embedding in desktop modal).
  final bool embeddedMode;

  const SettingsScreen({super.key, this.embeddedMode = false});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _expertMode = false;

  @override
  void initState() {
    super.initState();
    _expertMode = ref.read(configServiceProvider).expertMode;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScaledSizedBox(height: isSmallScreen ? 12 : 20),

                // Section Général
                Text(
                  'generalSettings'.tr(),
                  style: scaledTextStyle(
                    fontSize: isSmallScreen ? 15 : 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                // Carte Unité de devise
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const CurrencySetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Sélection du thème
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const ThemeSetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Language setting
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const LanguageSetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Text size setting
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const TextSizeSetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Mode expert
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: ExpertModeSetting(
                      value: _expertMode,
                      onChanged: (value) {
                        if (mounted) {
                          setState(() {
                            _expertMode = value;
                          });
                        }
                      },
                    ),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Rapports d'erreurs Sentry
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const SentrySetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Image de fond
                SettingsCard(
                  child: Padding(
                    padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                    child: const BackgroundImageSetting(),
                  ),
                ),
                ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                // Carte Nettoyage du cache
                SettingsCard(child: const ClearCacheSetting()),
                ScaledSizedBox(height: isSmallScreen ? 20 : 24),

                // Section Expert (visible seulement en mode expert)
                if (_expertMode) ...[
                  // Carte Génération de mnémoniques en anglais
                  SettingsCard(
                    child: Padding(
                      padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                      child: const MnemonicLanguageSetting(),
                    ),
                  ),
                  if (isDesktopLayout(context)) ...[
                    ScaledSizedBox(height: isSmallScreen ? 12 : 16),
                    SettingsCard(
                      child: Padding(
                        padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
                        child: const WindowSizeSetting(),
                      ),
                    ),
                  ],
                  ScaledSizedBox(height: isSmallScreen ? 12 : 16),

                  const NetworkSettingsSection(),
                  ScaledSizedBox(height: isSmallScreen ? 20 : 24),
                ],

                // Section Danger
                ScaledSizedBox(height: isSmallScreen ? 8 : 12),

                // Carte Suppression des coffres
                SettingsCard(
                  border: Border.all(color: context.geckoColors.deleteAction.withValues(alpha: 0.1)),
                  child: const DeleteSafesSetting(),
                ),
                ScaledSizedBox(height: isSmallScreen ? 20 : 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embeddedMode) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GeckoAppBar('parameters'.tr()),
      body: SafeArea(child: content),
    );
  }
}
