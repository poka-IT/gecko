// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
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
      padding: EdgeInsets.all(scaleSize(11)),
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
                    if (myWalletProvider.pinCode == '') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (homeContext) {
                            return UnlockingWallet(wallet: defaultWallet);
                          },
                        ),
                      );
                    }
                    if (myWalletProvider.pinCode == '') return;
                    await myWalletProvider.generateNewDerivation(
                        context, newDerivationName);
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: const BoxDecoration(color: floattingYellow),
                  child: Center(
                      child: myWalletProvider.isNewDerivationLoading
                          ? ScaledSizedBox(
                              height: 50,
                              width: 50,
                              child: const CircularProgressIndicator(
                                color: orangeC,
                                strokeWidth: 6,
                              ),
                            )
                          : Text(
                              '+',
                              style: scaledTextStyle(
                                  fontSize: 110,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFFCB437)),
                            )),
                )),
          ),
        ]),
      ),
    );
  }
}
