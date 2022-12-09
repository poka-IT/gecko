// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CustomDerivation extends StatefulWidget {
  const CustomDerivation({Key? key}) : super(key: key);

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
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    final derivationList = <String>[
      'root',
      for (var i = 0; i < 51; i += 1) i.toString()
    ];

    final listWallets = myWalletProvider.readAllWallets();

    for (WalletData wallet in listWallets) {
      derivationList.remove(wallet.derivation.toString());
      if (wallet.derivation == -1) {
        derivationList.remove('root');
      }
    }

    if (!derivationList.contains(dropdownValue)) {
      dropdownValue = derivationList.first;
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
          toolbarHeight: 60 * ratio,
          title: SizedBox(
            height: 22,
            child: Text('createCustomDerivation'.tr()),
          )),
      body: Center(
        child: SafeArea(
          child: Column(children: <Widget>[
            const Spacer(),
            Text(
              'chooseDerivation'.tr(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 100,
              child: DropdownButton<String>(
                value: dropdownValue,
                menuMaxHeight: 300,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: orangeC),
                underline: Container(
                  height: 2,
                  color: orangeC,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    dropdownValue = newValue!;
                  });
                },
                items: derivationList
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                      value: value,
                      child: SizedBox(
                        width: 75,
                        child: Row(children: [
                          const Spacer(),
                          Text(
                            value,
                            style: const TextStyle(
                                fontSize: 20, color: Colors.black),
                          ),
                          const Spacer(),
                        ]),
                      ));
                }).toList(),
              ),
            ),
            const Spacer(flex: 1),
            SizedBox(
              width: 410,
              height: 70,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, elevation: 4,
                  backgroundColor: orangeC, // foreground
                ),
                onPressed: () async {
                  WalletData? defaultWallet =
                      myWalletProvider.getDefaultWallet();
                  String? pin;
                  if (myWalletProvider.pinCode == '') {
                    pin = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (homeContext) {
                          return UnlockingWallet(wallet: defaultWallet);
                        },
                      ),
                    );
                  }

                  if (pin != null || myWalletProvider.pinCode != '') {
                    String newDerivationName =
                        '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
                    if (dropdownValue == 'root') {
                      await myWalletProvider.generateRootWallet(
                          context, 'Portefeuille racine');
                    } else {
                      await myWalletProvider.generateNewDerivation(
                        context,
                        newDerivationName,
                        int.parse(dropdownValue!),
                      );
                    }
                    Navigator.pop(context);
                    Navigator.pop(context);
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) {
                    //     return const WalletsHome();
                    //   }),
                    // );
                  }
                },
                child: Text(
                  'validate'.tr(),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const Spacer(),
          ]),
        ),
      ),
    );
  }
}
