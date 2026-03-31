import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/nfc_providers.dart';
import 'package:gecko/screens/settings/settings_card.dart';
import 'package:gecko/screens/settings/widgets/clear_cache_setting.dart';
import 'package:gecko/screens/settings/widgets/delete_safes_setting.dart';
import 'package:gecko/screens/settings/widgets/scan_default_action_setting.dart';
import 'package:gecko/screens/settings/widgets/sentry_setting.dart';

/// General tab: scan action, sentry, clear cache, delete safes.
class GeneralTab extends StatelessWidget {
  const GeneralTab({super.key});

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
            const _NfcSettingsCardWrapper(),
            SettingsCard(
              child: Padding(padding: EdgeInsets.all(padding), child: const SentrySetting()),
            ),
            spacing,
            SettingsCard(child: const ClearCacheSetting()),
            ScaledSizedBox(height: isSmallScreen ? 20 : 24),
            SettingsCard(
              border: Border.all(color: context.geckoColors.deleteAction.withValues(alpha: 0.1)),
              child: const DeleteSafesSetting(),
            ),
            ScaledSizedBox(height: isSmallScreen ? 20 : 24),
          ],
        ),
      ),
    );
  }
}

/// Wraps the NFC scan settings card so the entire card is hidden when NFC is not supported.
class _NfcSettingsCardWrapper extends ConsumerWidget {
  const _NfcSettingsCardWrapper();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nfcStatus = ref.watch(nfcAvailabilityProvider);
    return nfcStatus.when(
      data: (availability) {
        if (availability == NFCAvailability.not_supported) return const SizedBox.shrink();
        final isSmallScreen = MediaQuery.of(context).size.height < 700;
        return Padding(
          padding: EdgeInsets.only(bottom: scaleSize(isSmallScreen ? 12 : 16)),
          child: SettingsCard(
            child: Padding(
              padding: EdgeInsets.all(scaleSize(isSmallScreen ? 10 : 14)),
              child: const ScanDefaultActionSetting(),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
