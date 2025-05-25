// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/screens/wallet_view.dart' show buttonSize, buttonFontSize;
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';

class CertifyButton extends StatelessWidget {
  const CertifyButton(this.address, {super.key});
  final String address;

  @override
  Widget build(BuildContext context) {
    final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    return Column(
      children: <Widget>[
        ScaledSizedBox(
          height: buttonSize,
          child: ClipOval(
            child: Material(
              color: const Color(0xffFFD58D),
              child: InkWell(
                key: keyCertify,
                splashColor: context.colorScheme.primary,
                onTap: () async {
                  final walletName = duniterIndexer.walletNameIndexer[address];
                  final message = walletName != null
                      ? '${'areYouSureYouWantToCertify1'.tr()}\n\n**$walletName**\n\n${'areYouSureYouWantToCertify2'.tr()}\n\n**${getShortPubkey(address)}**'
                      : '${'areYouSureCreateIdentityOnAddress'.tr()}\n\n**${getShortPubkey(address)}**';

                  final result = await showConfirmationDialog(
                    context: context,
                    title: walletName != null ? 'certification'.tr() : 'identityCreation'.tr(),
                    message: message,
                    type: walletName != null ? ConfirmationDialogType.question : ConfirmationDialogType.info,
                  );

                  if (!result) return;
                  await sub.setCurrentWallet(myWalletProvider.idtyWallet!);

                  if (myWalletProvider.pinCode == '') {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (homeContext) {
                          return UnlockingWallet(wallet: myWalletProvider.idtyWallet!);
                        },
                      ),
                    );
                  }
                  if (myWalletProvider.pinCode == '') {
                    return;
                  }
                  WalletsProfilesProvider walletViewProvider = Provider.of<WalletsProfilesProvider>(context, listen: false);
                  final acc = sub.getCurrentKeyPair();
                  try {
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
                  } catch (e) {
                    if (e is NotMemberException) {
                      showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
                    } else if (e is CantBeCertException) {
                      showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
                    }
                  }
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
        Container(
          constraints: BoxConstraints(maxWidth: scaleSize(100)),
          child: Text(
            "certify".tr(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
