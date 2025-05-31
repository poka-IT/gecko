import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:provider/provider.dart';

class ScanDerivationsInfo extends StatelessWidget {
  const ScanDerivationsInfo({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider = Provider.of<GenerateWalletsProvider>(context);
    return Visibility(
      visible: generateWalletProvider.scanStatus != ScanDerivationsStatus.none,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (generateWalletProvider.scanStatus == ScanDerivationsStatus.rootScanning)
              Text(
                'scanRootDerivationInProgress'.tr(),
                style: scaledTextStyle(fontSize: 15),
              ),
            if (generateWalletProvider.scanStatus == ScanDerivationsStatus.scanning)
              Text(
                'derivationsScanProgress'.tr(args: [generateWalletProvider.numberScan.toString()]),
                style: scaledTextStyle(fontSize: 15),
              ),
            if (generateWalletProvider.scanStatus == ScanDerivationsStatus.import)
              Text(
                "importDerivationsInProgress".tr(args: ['${generateWalletProvider.scanedWalletNumber}', '${generateWalletProvider.scanedValidWalletNumber}']),
                style: scaledTextStyle(fontSize: 15),
              ),
            ScaledSizedBox(width: 10),
            ScaledSizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                color: context.colorScheme.primary,
                strokeWidth: scaleSize(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum ScanDerivationsStatus { none, rootScanning, scanning, import }

enum ScanDerivationsResult { none, error, walletExists, walletNotFound, timeout }
