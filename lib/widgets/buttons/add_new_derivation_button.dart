// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class AddNewDerivationButton extends StatelessWidget {
  const AddNewDerivationButton({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context);

    String newDerivationName =
        '${'wallet'.tr()} ${myWalletProvider.listWallets.last.number! + 2}';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Column(children: <Widget>[
          Expanded(
            child: InkWell(
                key: keyAddDerivation,
                onTap: () async {
                  if (!myWalletProvider.isNewDerivationLoading) {
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
                      await myWalletProvider.generateNewDerivation(
                          context, newDerivationName);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(color: floattingYellow),
                  child: Center(
                      child: myWalletProvider.isNewDerivationLoading
                          ? const SizedBox(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(
                                color: orangeC,
                                strokeWidth: 7,
                              ),
                            )
                          : const Text(
                              '+',
                              style: TextStyle(
                                  fontSize: 150,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFCB437)),
                            )),
                )),
          ),
        ]),
      ),
    );
  }
}
