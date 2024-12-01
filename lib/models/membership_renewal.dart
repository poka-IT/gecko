// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/transaction_in_progress.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/membership_status.dart';

class MembershipRenewal {
  static RenewalInfo calculateRenewalInfo(MembershipStatus status, int renewalPeriodBlocks) {
    if (status.expireDate == null) {
      return RenewalInfo(canRenew: false);
    }

    final now = DateTime.now();
    final renewalPeriodInSeconds = renewalPeriodBlocks * 6;
    final renewalDate = status.expireDate!.subtract(Duration(seconds: renewalPeriodInSeconds));
    final isExpired = status.expireDate!.isBefore(now);
    final canRenew = now.isAfter(renewalDate) && !status.hasPendingRenewal;

    return RenewalInfo(
      expireDate: status.expireDate,
      renewalDate: renewalDate,
      isExpired: isExpired,
      canRenew: canRenew,
      hasPendingRenewal: status.hasPendingRenewal,
    );
  }

  static Future<void> executeRenewal(BuildContext context, String address) async {
    final answer = await confirmPopup(context, 'areYouSureYouWantToRenewMembership'.tr()) ?? false;
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
    if (info.expireDate == null) return const SizedBox.shrink();

    final text = info.hasPendingRenewal
        ? 'membershipRenewalPending'.tr()
        : info.isExpired
            ? 'membershipExpiredOn'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)])
            : info.canRenew
                ? 'membershipExpiresOnSimple'.tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!)])
                : 'membershipExpiresOn'
                    .tr(args: [DateFormat('dd/MM/yyyy').format(info.expireDate!), ((info.expireDate!.difference(info.renewalDate!)).inDays).toString()]);

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
  final DateTime? renewalDate;
  final bool isExpired;
  final bool canRenew;
  final bool hasPendingRenewal;

  RenewalInfo({
    this.expireDate,
    this.renewalDate,
    this.isExpired = false,
    this.canRenew = false,
    this.hasPendingRenewal = false,
  });
}
