import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/utils.dart';
import 'package:gecko/widgets/commons/loading.dart';
import 'package:gecko/widgets/transaction_status.dart';
import 'package:gecko/widgets/transaction_status_icon.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class TransactionInProgress extends StatefulWidget {
  final String transactionId;
  final String transType;
  final String? fromAddress, toAddress, toUsername;

  const TransactionInProgress({
    super.key,
    required this.transactionId,
    this.transType = 'pay',
    this.fromAddress,
    this.toAddress,
    this.toUsername,
  });

  @override
  State<TransactionInProgress> createState() => _TransactionInProgressState();
}

class _TransactionInProgressState extends State<TransactionInProgress> {
  String resultText = '';
  late String fromAddressFormat;
  late String toAddressFormat;
  late String toUsernameFormat;
  late String amount;
  late bool isUdUnit;
  TransactionContent? txContent;

  @override
  void initState() {
    final walletProfiles = Provider.of<WalletsProfilesProvider>(homeContext, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(homeContext, listen: false);

    String defaultWalletAddress = myWalletProvider.getDefaultWallet().address;
    String defaultWalletName = myWalletProvider.getDefaultWallet().name!;
    String? walletDataName = myWalletProvider.getWalletDataByAddress(widget.toAddress ?? '')?.name;

    fromAddressFormat = widget.fromAddress ?? g1WalletsBox.get(defaultWalletAddress)?.username ?? defaultWalletName;
    toAddressFormat = widget.toAddress ?? walletProfiles.address;
    toUsernameFormat = widget.toUsername ?? walletDataName ?? getShortPubkey(toAddressFormat);

    amount = walletProfiles.payAmount.text;
    isUdUnit = configBox.get('isUdUnit') ?? false;
    waitForTransactionStatus();
    super.initState();
  }

  void waitForTransactionStatus() async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    while (!sub.transactionStatus.containsKey(widget.transactionId)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }

    setState(() {
      txContent = sub.transactionStatus[widget.transactionId]!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: true);

    if (txContent == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Loading(
            size: 30,
          ),
        ),
      );
    }

    if (sub.transactionStatus.containsKey(widget.transactionId)) {
      txContent = sub.transactionStatus[widget.transactionId]!;
    }

    if (txContent!.status == TransactionStatus.success) {
      if (widget.transType == 'renewMembership') {
        resultText = 'membershipRenewalConfirmed'.tr();
      } else {
        resultText = 'extrinsicValidated'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]);
      }
    } else if (txContent!.status == TransactionStatus.failed) {
      final errorParts = txContent!.error?.split('Exception: ');
      final error = errorParts != null && errorParts.length > 1 ? errorParts[1] : txContent!.error;
      resultText = errorTransactionMap[error] ?? error!;
    } else {
      resultText = statusStatusMap[txContent!.status] ?? 'Unknown status: ${txContent!.status}';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: headerColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(
          'extrinsicInProgress'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]),
          style: scaledTextStyle(
            fontSize: 16,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: headerColor,
            padding: EdgeInsets.symmetric(
              horizontal: scaleSize(24),
              vertical: scaleSize(16),
            ),
            child: Column(
              children: [
                Text(
                  'fromMinus'.tr(),
                  style: scaledTextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
                ScaledSizedBox(height: 4),
                Text(
                  fromAddressFormat,
                  style: scaledTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (fromAddressFormat != toAddressFormat) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                    child: Container(
                      height: 1,
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                  Text(
                    'toMinus'.tr(),
                    style: scaledTextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                  ScaledSizedBox(height: 4),
                  Text(
                    toUsernameFormat,
                    style: scaledTextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: scaleSize(52),
                  height: scaleSize(52),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.black12,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: TransactionStatusIcon(txContent!.status),
                  ),
                ),
                if (txContent!.status != TransactionStatus.none) ...[
                  ScaledSizedBox(height: 24),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: scaleSize(32)),
                    child: Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(scaleSize(24)),
            child: SizedBox(
              width: double.infinity,
              height: scaleSize(48),
              child: ElevatedButton(
                key: keyCloseTransactionScreen,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE65100),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'close'.tr(),
                  style: scaledTextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
