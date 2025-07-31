// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show WalletEntity;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

class CustomDerivation extends StatefulWidget {
  const CustomDerivation({super.key});

  @override
  State<CustomDerivation> createState() => _CustomDerivationState();
}

class _CustomDerivationState extends State<CustomDerivation> {
  String? dropdownValue;

  @override
  void initState() {
    dropdownValue = 'root';
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    final derivationList = <String>['root', for (var i = 0; i < 51; i += 1) i.toString()];

    for (WalletEntity wallet in myWalletProvider.listWallets) {
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
                            Text(value, style: scaledTextStyle(fontSize: 16, color: Colors.black)),
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
                    String newDerivationName = '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number + 2}';
                    if (dropdownValue == 'root') {
                      await myWalletProvider.generateRootWallet(context, 'rootWallet'.tr());
                    } else {
                      await myWalletProvider.generateNewDerivation(
                        context,
                        newDerivationName,
                        int.parse(dropdownValue!),
                      );
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
