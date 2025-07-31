import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';

class ScanDerivationsInfoMigrated extends ConsumerWidget {
  const ScanDerivationsInfoMigrated({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scanInfo = ref.watch(scanDisplayInfoProvider);

    return Visibility(
      visible: scanInfo.showProgress,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Column(
          children: [
            // Status text
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_getStatusMessage(scanInfo), style: scaledTextStyle(fontSize: 15)),
                ScaledSizedBox(width: 10),
                ScaledSizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: scaleSize(3)),
                ),
              ],
            ),

            // Progress bar (optional, shows visual progress)
            if (scanInfo.progress > 0 && scanInfo.progress < 1)
              Padding(
                padding: EdgeInsets.only(top: scaleSize(10)),
                child: SizedBox(
                  width: scaleSize(200),
                  child: LinearProgressIndicator(
                    value: scanInfo.progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(context.colorScheme.primary),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getStatusMessage(ScanDisplayInfo scanInfo) {
    switch (scanInfo.status) {
      case WalletScanStatus.scanningRoot:
        return 'scanRootDerivationInProgress'.tr();

      case WalletScanStatus.generatingKeypairs:
        return 'generatingKeypairs'.tr(); // You may need to add this translation

      case WalletScanStatus.scanningBalances:
        return 'derivationsScanProgress'.tr(args: ['30']); // Default to 30 like original

      case WalletScanStatus.importingWallets:
        return "importDerivationsInProgress".tr(
          args: ['${scanInfo.scannedWalletCount}', '${scanInfo.validWalletCount}'],
        );

      case WalletScanStatus.completed:
        return 'Scan completed';

      case WalletScanStatus.none:
        return '';
    }
  }
}
