import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/settings/settings_card.dart';
import 'package:gecko/screens/settings/widgets/expert_mode_setting.dart';
import 'package:gecko/screens/settings/widgets/mnemonic_language_setting.dart';
import 'package:gecko/screens/settings/widgets/network_section.dart';
import 'package:gecko/screens/settings/widgets/window_size_setting.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/widgets/desktop/desktop_utils.dart';

/// Advanced tab: expert mode toggle + expert-only settings (mnemonic, window size, network).
class AdvancedTab extends ConsumerStatefulWidget {
  const AdvancedTab({super.key});

  @override
  ConsumerState<AdvancedTab> createState() => _AdvancedTabState();
}

class _AdvancedTabState extends ConsumerState<AdvancedTab> {
  bool _expertMode = false;

  @override
  void initState() {
    super.initState();
    _expertMode = ref.read(configServiceProvider).expertMode;
  }

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
              child: Padding(
                padding: EdgeInsets.all(padding),
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
            if (_expertMode) ...[
              spacing,
              SettingsCard(
                child: Padding(padding: EdgeInsets.all(padding), child: const MnemonicLanguageSetting()),
              ),
              if (isDesktopLayout(context)) ...[
                spacing,
                SettingsCard(
                  child: Padding(padding: EdgeInsets.all(padding), child: const WindowSizeSetting()),
                ),
              ],
              spacing,
              const NetworkSettingsSection(),
            ],
            ScaledSizedBox(height: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }
}
