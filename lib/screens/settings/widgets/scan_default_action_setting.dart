import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/nfc_providers.dart';
import 'package:gecko/services/config_service.dart';

/// Setting for the default scan button action (QR / NFC / Ask).
///
/// Only visible when NFC hardware is present (even if disabled).
class ScanDefaultActionSetting extends ConsumerStatefulWidget {
  const ScanDefaultActionSetting({super.key});

  @override
  ConsumerState<ScanDefaultActionSetting> createState() => _ScanDefaultActionSettingState();
}

class _ScanDefaultActionSettingState extends ConsumerState<ScanDefaultActionSetting> {
  @override
  Widget build(BuildContext context) {
    final nfcStatus = ref.watch(nfcAvailabilityProvider);

    return nfcStatus.when(
      data: (availability) {
        // Hide entirely if device has no NFC hardware
        if (availability == NFCAvailability.not_supported) return const SizedBox.shrink();

        final config = ConfigService(configBox);
        final current = config.scanDefaultAction;

        return RadioGroup<String>(
          groupValue: current,
          onChanged: (v) {
            if (v != null) {
              config.scanDefaultAction = v;
              setState(() {});
            }
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: scaleSize(8), bottom: scaleSize(4)),
                child: Row(
                  children: [
                    Icon(Icons.contactless_rounded, color: context.colorScheme.primary, size: scaleSize(24)),
                    ScaledSizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'scanDefaultAction'.tr(),
                        style: scaledTextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodyMedium?.color),
                      ),
                    ),
                  ],
                ),
              ),
              _buildOption(context, config, current, 'ask', 'scanDefaultAsk'.tr(), Icons.touch_app_rounded),
              _buildOption(context, config, current, 'qr', 'scanDefaultQr'.tr(), Icons.qr_code_scanner),
              _buildOption(context, config, current, 'nfc', 'scanDefaultNfc'.tr(), Icons.nfc_rounded),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }

  Widget _buildOption(
    BuildContext context,
    ConfigService config,
    String current,
    String value,
    String label,
    IconData icon,
  ) {
    final isSelected = current == value;
    return InkWell(
      onTap: () {
        config.scanDefaultAction = value;
        setState(() {});
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: scaleSize(6), horizontal: scaleSize(36)),
        child: Row(
          children: [
            Icon(
              icon,
              size: scaleSize(20),
              color: isSelected ? context.colorScheme.primary : context.colorScheme.outline,
            ),
            ScaledSizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: scaledTextStyle(
                  fontSize: 13,
                  color: isSelected ? context.colorScheme.primary : Theme.of(context).textTheme.bodyMedium?.color,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            Radio<String>(value: value, activeColor: context.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
