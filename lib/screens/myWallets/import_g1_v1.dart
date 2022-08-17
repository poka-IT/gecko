import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:provider/provider.dart';

class ImportG1v1 extends StatelessWidget {
  const ImportG1v1({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    Timer? debounce;
    const int debouneTime = 300;
    String selectedWallet = myWalletProvider.getDefaultWallet().name!;

    return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Importer son ancien compte'),
            )),
        body:
            SafeArea(child: Consumer<SubstrateSdk>(builder: (context, sub, _) {
          return Column(children: <Widget>[
            const SizedBox(height: 20),
            TextFormField(
              autofocus: true,
              onChanged: (text) {
                if (debounce?.isActive ?? false) {
                  debounce!.cancel();
                }
                debounce = Timer(const Duration(milliseconds: debouneTime), () {
                  sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                });
              },
              keyboardType: TextInputType.text,
              controller: sub.csSalt,
              obscureText:
                  sub.isCesiumIDVisible, //This will obscure text dynamically
              decoration: InputDecoration(
                hintText: 'Entrez votre identifiant Cesium',
                suffixIcon: IconButton(
                  icon: Icon(
                    sub.isCesiumIDVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    sub.cesiumIDisVisible();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextFormField(
              autofocus: true,
              onChanged: (text) {
                if (debounce?.isActive ?? false) {
                  debounce!.cancel();
                }
                debounce = Timer(const Duration(milliseconds: debouneTime), () {
                  sub.csToV2Address(sub.csSalt.text, sub.csPassword.text);
                });
              },
              keyboardType: TextInputType.text,
              controller: sub.csPassword,
              obscureText:
                  sub.isCesiumIDVisible, //This will obscure text dynamically
              decoration: InputDecoration(
                hintText: 'Entrez votre mot de passe Cesium',
                suffixIcon: IconButton(
                  icon: Icon(
                    sub.isCesiumIDVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.black,
                  ),
                  onPressed: () {
                    sub.cesiumIDisVisible();
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              sub.g1V1NewAddress,
              style: const TextStyle(
                  fontSize: 14.0,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace'),
            ),
            const SizedBox(height: 20),
            balance(context, sub.g1V1NewAddress, 17),
            walletOptions.idtyStatus(context, sub.g1V1NewAddress,
                isOwner: false, color: Colors.black),
            getCerts(context, sub.g1V1NewAddress, 14),
            const SizedBox(height: 30),
            Text('selectDestWallet'.tr()),
            const SizedBox(height: 10),
            DropdownButtonHideUnderline(
              child: DropdownButton(
                // alignment: AlignmentDirectional.topStart,
                value: selectedWallet,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: myWalletProvider.listWallets.map((wallet) {
                  return DropdownMenuItem(
                    value: wallet.name,
                    child: Text(wallet.name!),
                  );
                }).toList(),
                onChanged: (newSelectedWallet) {
                  selectedWallet = newSelectedWallet.toString();
                  sub.reload();
                },
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: 380 * ratio,
              height: 60 * ratio,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  primary: orangeC, // background
                  onPrimary: Colors.white, // foreground
                ),
                onPressed: () {
                  log.d('GOOO');
                },
                child: Text(
                  'validate'.tr(),
                  style: TextStyle(
                      fontSize: 23 * ratio, fontWeight: FontWeight.w600),
                ),
              ),
            )
          ]);
        })));
  }
}
