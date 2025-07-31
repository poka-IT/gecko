// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show IdtyStatus, MembershipStatus;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

class MembershipRenewal {
  static RenewalInfo calculateRenewalInfo(MembershipStatus status) {
    if (status.expireDate == null) {
      return status.idtyStatus == IdtyStatus.expired
          ? RenewalInfo(canRenew: true, isExpired: true, hasPendingRenewal: status.hasPendingRenewal)
          : RenewalInfo(canRenew: false);
    }

    final now = DateTime.now();
    final isExpired = status.expireDate!.isBefore(now);

    // On peut renouveler si on est après la date de début de renouvellement
    final canRenew = !status.hasPendingRenewal && (status.renewalStartDate?.isBefore(now) ?? false);

    return RenewalInfo(
      expireDate: status.expireDate,
      isExpired: isExpired,
      canRenew: canRenew,
      hasPendingRenewal: status.hasPendingRenewal,
      renewalStartDate: status.renewalStartDate,
    );
  }

  static Future<void> executeRenewal(BuildContext context, WidgetRef ref, String address) async {
    final answer = await showConfirmationDialog(
      context: context,
      message: 'areYouSureYouWantToRenewMembership'.tr(),
      type: ConfirmationDialogType.question,
    );
    if (!answer) return;

    if (!await PinCodeService.askPinCode()) return;

    final keypair = await ref
        .read(walletServiceProvider)
        .getKeyPairFromAddress(address: address, pinCode: PinCodeService.pinCode);
    final transactionStatus = ref.read(duniterServiceProvider).renewMembership(keypair);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return TransactionInProgressScreen(
            transactionStatus: transactionStatus,
            transType: 'renewMembership',
            fromAddress: getShortPubkey(address),
            toAddress: getShortPubkey(address),
          );
        },
      ),
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

class RenewalInfo {
  final DateTime? expireDate;
  final bool isExpired;
  final bool canRenew;
  final bool hasPendingRenewal;
  final DateTime? renewalStartDate;

  RenewalInfo({
    this.expireDate,
    this.isExpired = false,
    this.canRenew = false,
    this.hasPendingRenewal = false,
    this.renewalStartDate,
  });
}
