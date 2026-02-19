// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/wallet_name_service.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class CustomDerivation extends ConsumerStatefulWidget {
  const CustomDerivation({super.key});

  @override
  ConsumerState<CustomDerivation> createState() => _CustomDerivationState();
}

class _CustomDerivationState extends ConsumerState<CustomDerivation> {
  String? dropdownValue;

  @override
  void initState() {
    dropdownValue = 'root';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final walletsList = ref.watch(walletsListProvider).wallets;

    final derivationList = <String>['root', for (var i = 0; i < 51; i += 1) i.toString()];

    for (WalletEntity wallet in walletsList) {
      derivationList.remove(wallet.derivation.toString());
      if (wallet.derivation == null) {
        derivationList.remove('root');
      }
    }

    if (!derivationList.contains(dropdownValue)) {
      dropdownValue = derivationList.first;
    }

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('createCustomDerivation'.tr()),
      body: Center(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(),
              Text('chooseDerivation'.tr(), style: scaledTextStyle(fontSize: 16)),
              ScaledSizedBox(height: 8),
              Text(
                'advancedFeature'.tr(),
                style: scaledTextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
              ScaledSizedBox(height: 20),
              ScaledSizedBox(
                width: 100,
                child: DropdownButton<String>(
                  value: dropdownValue,
                  menuMaxHeight: 300,
                  icon: Icon(Icons.arrow_downward, size: scaleSize(20)),
                  elevation: 16,
                  style: scaledTextStyle(color: context.colorScheme.primary),
                  underline: Container(height: 2, color: context.colorScheme.primary),
                  onChanged: (String? newValue) {
                    setState(() {
                      dropdownValue = newValue!;
                    });
                  },
                  items: derivationList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: ScaledSizedBox(
                        width: 75,
                        child: Row(
                          children: [
                            const Spacer(),
                            Text(value, style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface)),
                            const Spacer(),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const Spacer(flex: 1),
              ScaledSizedBox(
                width: 240,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: context.colorScheme.primary,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  onPressed: () async {
                    if (!await PinCodeService.askPinCode()) return;
                    String newDerivationName = WalletNameService.defaultN(walletsList.last.number + 2);
                    if (dropdownValue == 'root') {
                      await ref
                          .read(walletActionsProvider.notifier)
                          .generateRootWallet(WalletNameService.defaultMain());
                    } else {
                      await ref
                          .read(walletActionsProvider.notifier)
                          .generateNewDerivation(newDerivationName, customDerivation: int.parse(dropdownValue!));
                    }
                    Navigator.popUntil(context, ModalRoute.withName(RouteNames.myWallets));
                  },
                  child: Text(
                    'validate'.tr(),
                    style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
