import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/transaction_content.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
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
      return const Scaffold(
        body: Center(
          child: Loading(
            size: 25,
          ),
        ),
      );
    }

    if (sub.transactionStatus.containsKey(widget.transactionId)) {
      txContent = sub.transactionStatus[widget.transactionId]!;
    }

    if (txContent!.status == TransactionStatus.success) {
      resultText = 'extrinsicValidated'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]);
    } else if (txContent!.status == TransactionStatus.failed) {
      resultText = errorTransactionMap[txContent!.error] ?? txContent!.error!;
    } else {
      resultText = statusStatusMap[txContent!.status] ?? 'Unknown status: ${txContent!.status}';
    }

    Widget buildTransactionStatus() {
      return Column(
        children: [
          TransactionStatusIcon(txContent!.status),
          ScaledSizedBox(height: 7),
          if (txContent!.status != TransactionStatus.none)
            Text(
              resultText,
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 16),
            )
        ],
      );
    }

    return PopScope(
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: scaleSize(57),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Text(
                'extrinsicInProgress'.tr(args: [actionMap[widget.transType] ?? 'strangeTransaction'.tr()]),
                style: scaledTextStyle(fontSize: 19),
              )
            ])),
        body: SafeArea(
          child: Align(
            alignment: FractionalOffset.bottomCenter,
            child: Column(children: <Widget>[
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                    gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    yellowC,
                    backgroundColor,
                  ],
                )),
                child: Column(children: <Widget>[
                  ScaledSizedBox(height: 10),
                  if (widget.transType == 'pay')
                    Text(
                      isUdUnit ? 'ud'.tr(args: ['$amount ']) : '$amount $currencyName',
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                  if (widget.transType == 'pay') ScaledSizedBox(height: 10),
                  Text(
                    'fromMinus'.tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(fontSize: 15),
                  ),
                  Text(
                    fromAddressFormat,
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  Visibility(
                    visible: fromAddressFormat != toAddressFormat,
                    child: Column(
                      children: [
                        ScaledSizedBox(height: 10),
                        Text(
                          'toMinus'.tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: 15),
                        ),
                        Text(
                          toUsernameFormat,
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: 20),
                ]),
              ),
              const Spacer(),
              buildTransactionStatus(),
              const Spacer(),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ScaledSizedBox(
                    width: 300,
                    height: 55,
                    child: ElevatedButton(
                      key: keyCloseTransactionScreen,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        elevation: 4,
                        backgroundColor: orangeC,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'close'.tr(),
                        style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
              ScaledSizedBox(height: 80)
            ]),
          ),
        ),
      ),
    );
  }
}
