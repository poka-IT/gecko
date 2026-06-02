import 'package:durt2/durt2.dart' show IdtyStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/exceptions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/currency_provider.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
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
      // Re-read the freshest status at click time. The widget prop was set
      // during a previous build and may lag behind the stream (e.g., the
      // parent rebuilt with `IdtyStatus.unknown` while data was loading).
      // Acting on a stale status can produce inconsistent wording or worse,
      // claim "create identity" for an identity that already exists.
      final freshStatus = ref.read(smartIdtyStatusStreamProvider(widget.address)).asData?.value ?? widget.idtyStatus;

      if (freshStatus == IdtyStatus.unknown) {
        if (!context.mounted) return;
        await showConfirmationDialog(
          context: context,
          message: 'identityStatusSyncing'.tr(),
          type: ConfirmationDialogType.warning,
          hideCancelButton: true,
        );
        return;
      }

      // Switch the confirmation wording on the actual on-chain status, not on
      // whether the indexer has a cached name. A name may be missing briefly
      // after a network switch or when Squid hasn't replicated yet; that must
      // not make us claim we're "creating" an identity that already exists.
      final isCreatingIdentity = freshStatus == IdtyStatus.none;
      final walletName = ref.read(squidServiceProvider).walletNameIndexer[widget.address];
      final shortPubkey = getShortPubkey(widget.address);

      // Avoid rendering the pubkey twice when we have no name to show: the
      // bold identifier line is enough on its own.
      final String baseMessage;
      if (isCreatingIdentity) {
        baseMessage = '${'confirmCreateIdentity'.tr()}\n\n**$shortPubkey**';
      } else if (walletName != null) {
        baseMessage = '${'confirmCertification'.tr()}\n\n**$walletName**\n\n$shortPubkey';
      } else {
        baseMessage = '${'confirmCertification'.tr()}\n\n**$shortPubkey**';
      }

      // For expired and confirmed-but-not-yet-member identities, enrich the
      // confirmation with contextual guidance so the user understands what
      // their certification will trigger (cert only, cert + distance eval, …).
      final contextualHint = _buildContextualHint(freshStatus);
      final message = contextualHint != null ? '$baseMessage\n\n$contextualHint' : baseMessage;

      if (!context.mounted) return;
      final result = await showConfirmationDialog(
        context: context,
        title: isCreatingIdentity ? 'identityCreation'.tr() : 'certification'.tr(),
        message: message,
        type: isCreatingIdentity ? ConfirmationDialogType.info : ConfirmationDialogType.question,
        checkboxLabel: 'certifyUniqueIdentity'.tr(),
      );

      if (!result) return;
      // The confirmation dialog is awaited; the widget may have been disposed
      // meanwhile. Guard before reusing `context` so we never hand a detached
      // context to the PIN flow (was AXIOM-TEAM-PE: "No ProviderScope found").
      if (!context.mounted) return;

      // Capture the PIN locally so it survives the async gap until the
      // certification helper reaches its crypto step (see askPinCodeAndCapture).
      final capturedPin = await PinCodeService.askPinCodeAndCapture(context);
      if (capturedPin == null) return;
      if (!mounted) return;
      final identityWallet = await ref.read(effectiveCertificationWalletProvider.future);

      if (identityWallet == null) {
        throw Exception('Identity wallet not found');
      }

      try {
        if (!mounted) return;
        if (!context.mounted) return;
        await CertificationTransactionHelper.executeCertification(
          context: context,
          ref: ref,
          issuerAddress: identityWallet.address,
          targetAddress: widget.address,
          pinCode: capturedPin,
          targetUsername: walletName,
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

  /// Build a contextual hint that explains what this certification will
  /// achieve on-chain, tailored to where the target is in its membership
  /// lifecycle:
  ///   - `expired`   → re-membership path ("regain membership")
  ///   - `confirmed` → first-time membership path ("become a member")
  ///   - anything else (validated member, new identity, …) → no hint
  ///
  /// Within the two eligible statuses, the wording branches on whether this
  /// very certification will bring the target to the minCerts threshold
  /// (which triggers an auto-bundled distance evaluation via durt2) or
  /// whether more certifications will still be needed afterwards.
  ///
  /// Kept best-effort: if cert counters or currency params are not loaded
  /// yet, we fall back to no hint rather than block the flow.
  String? _buildContextualHint(IdtyStatus status) {
    final String needsMoreKey;
    final String willTriggerKey;
    switch (status) {
      case IdtyStatus.expired:
        needsMoreKey = 'certifyExpiredNeedsMore';
        willTriggerKey = 'certifyExpiredWillTriggerDistance';
      case IdtyStatus.confirmed:
        needsMoreKey = 'certifyConfirmedNeedsMore';
        willTriggerKey = 'certifyConfirmedWillTriggerDistance';
      default:
        return null;
    }

    final certData = ref.read(smartCertificationStreamProvider(widget.address)).asData?.value;
    final minCerts = ref.read(currencyDataProvider).asData?.value.wotParams.sigQtyRule;
    if (certData == null || minCerts == null) return null;

    final receivedCount = certData.receivedCount;
    final afterMyCert = receivedCount + 1;

    if (afterMyCert >= minCerts) {
      return willTriggerKey.tr(
        namedArgs: {'received': receivedCount.toString(), 'after': afterMyCert.toString(), 'min': minCerts.toString()},
      );
    }

    final remaining = minCerts - afterMyCert;
    return needsMoreKey.tr(
      namedArgs: {
        'received': receivedCount.toString(),
        'after': afterMyCert.toString(),
        'min': minCerts.toString(),
        'remaining': remaining.toString(),
      },
    );
  }
}
