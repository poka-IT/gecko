// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';

import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/providers_deprecated/wallets_profiles.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/screens/wallet_view.dart' show buttonSize, buttonFontSize;
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CertifyButton extends ConsumerWidget {
  const CertifyButton(this.address, {super.key, this.isRenewal = false, this.idtyStatus = IdtyStatus.unknown});
  final String address;
  final bool isRenewal;
  final IdtyStatus idtyStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    // Determine the appropriate text based on identity status and renewal status
    String getButtonText() {
      if (idtyStatus == IdtyStatus.none) {
        return "createThisIdentity".tr();
      } else if (isRenewal) {
        return "renewCertification".tr();
      } else {
        return "certify".tr();
      }
    }

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
                  final walletName = ref.read(squidServiceProvider).walletNameIndexer[address];
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
                  await ref.read(walletServiceProvider).setDefaultAddress(address);

                  // Use askPinCode() method for authentication
                  if (!await myWalletProvider.askPinCode()) return;
                  WalletsProfilesProvider walletViewProvider = old_provider.Provider.of<WalletsProfilesProvider>(
                    context,
                    listen: false,
                  );
                  final identityWallet = await ref.read(effectiveCertificationWalletProvider.future);

                  if (identityWallet == null) {
                    throw Exception('Identity wallet not found');
                  }

                  try {
                    final keypair = await ref
                        .read(walletServiceProvider)
                        .getKeyPairFromAddress(address: identityWallet.address, pinCode: myWalletProvider.pinCode);
                    final transactionStatus = ref
                        .read(duniterServiceProvider)
                        .certify(keypair: keypair, destAddress: walletViewProvider.address);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return TransactionInProgressScreen(transactionStatus: transactionStatus, transType: 'cert');
                        },
                      ),
                    );
                  } catch (e) {
                    if (e is NotMemberException) {
                      showConfirmationDialog(
                        context: context,
                        type: ConfirmationDialogType.error,
                        message: e.toString(),
                      );
                    } else if (e is CantBeCertException) {
                      showConfirmationDialog(
                        context: context,
                        type: ConfirmationDialogType.error,
                        message: e.toString(),
                      );
                    } else {
                      log.e(e);
                      showConfirmationDialog(
                        context: context,
                        type: ConfirmationDialogType.error,
                        message: e.toString(),
                      );
                      return;
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
            getButtonText(),
            textAlign: TextAlign.center,
            style: scaledTextStyle(fontSize: buttonFontSize, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
