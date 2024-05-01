// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/screens/wallet_view.dart' show buttonSize, buttonFontSize;
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:provider/provider.dart';

class CertifyButton extends StatelessWidget {
  const CertifyButton(this.address, {Key? key}) : super(key: key);
  final String address;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    final defaultWallet = myWalletProvider.getDefaultWallet();

    return Column(
      children: <Widget>[
        ScaledSizedBox(
          height: buttonSize,
          child: ClipOval(
            child: Material(
              color: const Color(0xffFFD58D),
              child: InkWell(
                key: keyCertify,
                splashColor: orangeC,
                onTap: () async {
                  final result = await confirmPopupCertification(
                        context,
                        'areYouSureYouWantToCertify1'.tr(),
                        duniterIndexer.walletNameIndexer[address] ??
                            "noIdentity".tr(),
                        'areYouSureYouWantToCertify2'.tr(),
                        getShortPubkey(address),
                      ) ??
                      false;

                  if (!result) return;
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
                  if (myWalletProvider.pinCode == '') {
                    return;
                  }
                  WalletsProfilesProvider walletViewProvider =
                      Provider.of<WalletsProfilesProvider>(context,
                          listen: false);
                  final acc = sub.getCurrentWallet();
                  final transactionId = await sub.certify(
                    acc.address!,
                    walletViewProvider.address,
                    myWalletProvider.pinCode,
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return TransactionInProgress(
                        transactionId: transactionId,
                        transType: 'cert',
                      );
                    }),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(bottom: 0),
                  child: Image(image: AssetImage('assets/gecko_certify.png')),
                ),
              ),
            ),
          ),
        ),
        ScaledSizedBox(height: 6),
        Text(
          "certify".tr(),
          textAlign: TextAlign.center,
          style: scaledTextStyle(
              fontSize: buttonFontSize, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
