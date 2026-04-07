import 'package:durt2/durt2.dart' show IdtyStatus, MembershipStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/widgets/desktop/modals/transaction_progress_modal.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

class MembershipRenewal {
  static RenewalInfo calculateRenewalInfo(MembershipStatus status) {
    if (status.expireDate == null) {
      if (status.idtyStatus == IdtyStatus.expired) {
        return RenewalInfo(
          canRenew: !status.hasPendingRenewal,
          isExpired: true,
          hasPendingRenewal: status.hasPendingRenewal,
          autoRevocationDate: status.autoRevocationDate,
          pendingEvalEstimate: status.pendingEvalEstimate,
          disableReason: status.hasPendingRenewal ? RenewalDisableReason.pendingEvaluation : null,
        );
      }
      if (status.idtyStatus == IdtyStatus.revoked) {
        return RenewalInfo(canRenew: false, disableReason: RenewalDisableReason.identityRevoked);
      }
      if (status.idtyStatus == IdtyStatus.none || status.idtyStatus == IdtyStatus.unknown) {
        return RenewalInfo(canRenew: false, disableReason: RenewalDisableReason.identityNotMember);
      }
      return RenewalInfo(canRenew: false);
    }

    final now = DateTime.now();
    final isExpired = status.expireDate!.isBefore(now);

    // On peut renouveler si on est après la date de début de renouvellement
    final renewalStartReached = status.renewalStartDate?.isBefore(now) ?? false;
    final canRenew = !status.hasPendingRenewal && renewalStartReached;

    RenewalDisableReason? disableReason;
    if (!canRenew) {
      if (status.hasPendingRenewal) {
        disableReason = RenewalDisableReason.pendingEvaluation;
      } else if (!renewalStartReached) {
        disableReason = RenewalDisableReason.renewalPeriodNotReached;
      }
    }

    return RenewalInfo(
      expireDate: status.expireDate,
      isExpired: isExpired,
      canRenew: canRenew,
      hasPendingRenewal: status.hasPendingRenewal,
      renewalStartDate: status.renewalStartDate,
      autoRevocationDate: status.autoRevocationDate,
      pendingEvalEstimate: status.pendingEvalEstimate,
      disableReason: disableReason,
    );
  }

  static Future<void> executeRenewal(
    BuildContext context,
    WidgetRef ref,
    String address, {
    bool isExpired = false,
  }) async {
    final answer = await showConfirmationDialog(
      context: context,
      message: isExpired ? 'renewMembershipExpiredConfirm'.tr() : 'areYouSureYouWantToRenewMembership'.tr(),
      type: isExpired ? ConfirmationDialogType.warning : ConfirmationDialogType.question,
    );
    if (!answer) return;

    // ignore: use_build_context_synchronously
    final capturedPin = await PinCodeService.askPinCodeAndCapture(context);
    if (capturedPin == null) return;

    final keypair = await ref.read(walletServiceProvider).getKeyPairFromAddress(address: address, pinCode: capturedPin);
    final transactionStatus = ref.read(duniterServiceProvider).renewMembership(keypair);

    if (!context.mounted) return;
    navigateToTransactionProgress(
      context,
      transactionStatus: transactionStatus,
      transType: 'renewMembership',
      fromAddress: address,
      toAddress: address,
    );
  }

  static Widget buildExpirationText(RenewalInfo info, {double? width}) {
    if (info.expireDate == null && !info.isExpired) return const SizedBox.shrink();

    final isRenewalStartDateInFuture = info.renewalStartDate != null && info.renewalStartDate!.isAfter(DateTime.now());

    String text;
    if (info.hasPendingRenewal) {
      text = 'membershipRenewalPending'.tr();
    } else if (info.isExpired) {
      text = info.expireDate != null
          ? 'membershipExpiredOn'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)])
          : 'membershipExpired'.tr();
    } else if (!isRenewalStartDateInFuture) {
      text = 'membershipExpiresOnSimple'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)]);
    } else {
      text = 'membershipExpiresOn'.tr(
        args: [
          DateFormat('dd/MM/yyyy').format(info.expireDate!),
          DateFormat('dd/MM/yyyy').format(info.renewalStartDate!),
        ],
      );
    }

    final textWidget = Text(
      text,
      style: scaledTextStyle(
        fontSize: width != null ? 15 : 12,
        color: Colors.grey[500],
        fontStyle: width != null ? FontStyle.italic : null,
      ),
    );

    return width != null
        ? SizedBox(width: scaleSize(width), child: textWidget)
        : SizedBox(width: scaleSize(250), child: textWidget);
  }
}

enum RenewalDisableReason {
  pendingEvaluation,
  renewalPeriodNotReached,
  identityExpired,
  identityRevoked,
  identityNotMember,
}

class RenewalInfo {
  final DateTime? expireDate;
  final bool isExpired;
  final bool canRenew;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;
  final DateTime? autoRevocationDate;
  final DateTime? pendingEvalEstimate;
  final RenewalDisableReason? disableReason;

  RenewalInfo({
    this.expireDate,
    this.isExpired = false,
    this.canRenew = false,
    this.hasPendingRenewal = false,
    this.renewalStartDate,
    this.autoRevocationDate,
    this.pendingEvalEstimate,
    this.disableReason,
  });

  /// Whether the membership state warrants a visible alert.
  /// True when expired+renewable, or in the last half of the renewal window,
  /// or within 30 days of expiration.
  bool get shouldAlertExpiringSoon {
    if (isExpired && canRenew) return true;
    if (expireDate == null) return false;

    if (canRenew && renewalStartDate != null) {
      final renewalWindow = expireDate!.difference(renewalStartDate!);
      final threshold = renewalWindow ~/ 2;
      final timeLeft = expireDate!.difference(DateTime.now());
      return timeLeft <= threshold;
    }

    if (isExpired) return false;
    return expireDate!.difference(DateTime.now()).inDays <= 30;
  }
}
