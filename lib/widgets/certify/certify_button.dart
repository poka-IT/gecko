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

class CertifyButton extends ConsumerStatefulWidget {
  const CertifyButton(this.address, {super.key, this.isRenewal = false, this.idtyStatus = IdtyStatus.unknown});
  final String address;
  final bool isRenewal;
  final IdtyStatus idtyStatus;

  @override
  ConsumerState<CertifyButton> createState() => _CertifyButtonState();
}

class _CertifyButtonState extends ConsumerState<CertifyButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    String getButtonText() {
      if (widget.idtyStatus == IdtyStatus.none) {
        return "createThisIdentity".tr();
      } else if (widget.isRenewal) {
        return "renewCertification".tr();
      } else {
        return "certify".tr();
      }
    }

    return ProfileActionButton(
      buttonKey: keyCertify,
      onTap: () => _onTap(context),
      backgroundColor: const Color(0xffFFD58D),
      label: getButtonText(),
      child: Padding(padding: EdgeInsets.all(scaleSize(4)), child: Image.asset('assets/gecko_certify.png')),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);
    try {
      final walletName = ref.read(squidServiceProvider).walletNameIndexer[widget.address];
      final message = walletName != null
          ? '${'confirmCertification'.tr()}\n\n**$walletName**\n\n${getShortPubkey(widget.address)}'
          : '${'confirmCreateIdentity'.tr()}\n\n**${getShortPubkey(widget.address)}**';

      final result = await showConfirmationDialog(
        context: context,
        title: walletName != null ? 'certification'.tr() : 'identityCreation'.tr(),
        message: message,
        type: walletName != null ? ConfirmationDialogType.question : ConfirmationDialogType.info,
        checkboxLabel: 'certifyUniqueIdentity'.tr(),
      );

      if (!result) return;

      // ignore: use_build_context_synchronously
      if (!await PinCodeService.askPinCode(context)) return;
      if (!mounted) return;
      final identityWallet = await ref.read(effectiveCertificationWalletProvider.future);

      if (identityWallet == null) {
        throw Exception('Identity wallet not found');
      }

      try {
        if (!mounted) return;
        await CertificationTransactionHelper.executeCertification(
          context: context,
          ref: ref,
          issuerAddress: identityWallet.address,
          targetAddress: widget.address,
        );
      } catch (e) {
        if (e is! NotMemberException && e is! CantBeCertException) log.e(e);
        if (!context.mounted) return;
        showConfirmationDialog(context: context, type: ConfirmationDialogType.error, message: e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
