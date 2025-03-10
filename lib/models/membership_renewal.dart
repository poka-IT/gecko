// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/membership_status.dart';

class MembershipRenewal {
  static RenewalInfo calculateRenewalInfo(MembershipStatusDeprecated status, int renewalPeriodBlocks) {
    if (status.expireDate == null) {
      return status.idtyStatus == IdtyStatus.notMember
          ? RenewalInfo(
              canRenew: true,
              isExpired: true,
              hasPendingRenewal: status.hasPendingRenewal,
            )
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

  static Future<void> executeRenewal(BuildContext context, String address) async {
    final answer = await showConfirmationDialog(
      context: context,
      message: 'areYouSureYouWantToRenewMembership'.tr(),
      type: ConfirmationDialogType.question,
    );
    if (!answer) return;

    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    if (!await myWalletProvider.askPinCode()) return;

    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final transactionId = await sub.renewMembership(address, myWalletProvider.pinCode);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return TransactionInProgress(
          transactionId: transactionId,
          transType: 'renewMembership',
          fromAddress: getShortPubkey(address),
          toAddress: getShortPubkey(address),
        );
      }),
    );
  }

  static Widget buildExpirationText(RenewalInfo info, {double? width}) {
    if (info.expireDate == null && !info.isExpired) return const SizedBox.shrink();

    final isRenewalStartDateInFuture = info.renewalStartDate != null && info.renewalStartDate!.isAfter(DateTime.now());

    String text;
    if (info.hasPendingRenewal) {
      text = 'membershipRenewalPending'.tr();
    } else if (info.isExpired) {
      text = info.expireDate != null ? 'membershipExpiredOn'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)]) : 'membershipExpired'.tr();
    } else if (!isRenewalStartDateInFuture) {
      text = 'membershipExpiresOnSimple'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)]);
    } else {
      text = 'membershipExpiresOn'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!), DateFormat('dd/MM/yyyy').format(info.renewalStartDate!)]);
    }

    final textWidget = Text(
      text,
      style: scaledTextStyle(
        fontSize: width != null ? 15 : 12,
        color: Colors.grey[500],
        fontStyle: width != null ? FontStyle.italic : null,
      ),
    );

    return width != null ? SizedBox(width: scaleSize(width), child: textWidget) : SizedBox(width: scaleSize(250), child: textWidget);
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
