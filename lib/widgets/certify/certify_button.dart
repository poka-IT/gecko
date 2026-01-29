// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/certify/certification_transaction_helper.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/profile_action_button.dart';

class CertifyButton extends ConsumerWidget {
  const CertifyButton(this.address, {super.key, this.isRenewal = false, this.idtyStatus = IdtyStatus.unknown});
  final String address;
  final bool isRenewal;
  final IdtyStatus idtyStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String getButtonText() {
      if (idtyStatus == IdtyStatus.none) {
        return "createThisIdentity".tr();
      } else if (isRenewal) {
        return "renewCertification".tr();
      } else {
        return "certify".tr();
      }
    }

    return ProfileActionButton(
      buttonKey: keyCertify,
      onTap: () => _onTap(context, ref),
      backgroundColor: const Color(0xffFFD58D),
      label: getButtonText(),
      child: Padding(padding: EdgeInsets.all(scaleSize(4)), child: Image.asset('assets/gecko_certify.png')),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
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

    if (!await PinCodeService.askPinCode()) return;
    final identityWallet = await ref.read(effectiveCertificationWalletProvider.future);

    if (identityWallet == null) {
      throw Exception('Identity wallet not found');
    }

    try {
      await CertificationTransactionHelper.executeCertification(
        context: context,
        ref: ref,
        issuerAddress: identityWallet.address,
        targetAddress: address,
      );
    } catch (e) {
      if (!context.mounted) {
        log.w('Context not mounted when error occurred: $e');
        return;
      }

      if (e is NotMemberException || e is CantBeCertException) {
        showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
      } else {
        log.e(e);
        showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
      }
    }
  }
}
