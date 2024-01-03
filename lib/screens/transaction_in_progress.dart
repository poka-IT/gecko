import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';

class TransactionInProgress extends StatelessWidget {
  final String transactionId;
  final String transType;
  final String? fromAddress, toAddress, toUsername;

  const TransactionInProgress({
    Key? key,
    required this.transactionId,
    this.transType = 'pay',
    this.fromAddress,
    this.toAddress,
    this.toUsername,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: true);

    final transactionDetails = TransactionDetails(
      transactionId: transactionId,
      fromAddress: fromAddress,
      toAddress: toAddress,
      toUsername: toUsername,
      sub: sub,
      transType: transType,
    );

    Widget getTransactionStatusIcon(TransactionDetails details) {
      switch (details.txStatus) {
        case TransactionStatus.loading:
          return ScaledSizedBox(
            height: 17,
            width: 17,
            child: const CircularProgressIndicator(
              color: orangeC,
              strokeWidth: 2,
            ),
          );
        case TransactionStatus.success:
          return Icon(
            Icons.done_all,
            size: scaleSize(32),
            color: Colors.greenAccent,
          );
        case TransactionStatus.failed:
          return Icon(
            Icons.close,
            size: scaleSize(32),
            color: Colors.redAccent,
          );
        case TransactionStatus.none:
        default:
          return const SizedBox.shrink();
      }
    }

    Widget buildTransactionStatus(TransactionDetails details) {
      return Column(
        children: [
          getTransactionStatusIcon(details),
          ScaledSizedBox(height: 7),
          if (details.txStatus != TransactionStatus.none)
            Text(
              transactionDetails.resultText,
              textAlign: TextAlign.center,
              style: scaledTextStyle(fontSize: 17),
            )
        ],
      );
    }

    return PopScope(
      onPopInvoked: (_) {
        sub.resetTransactionStatus();
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: scaleSize(57),
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'extrinsicInProgress'.tr(args: [
                      transactionDetails.actionMap[transType] ??
                          'strangeTransaction'.tr()
                    ]),
                    style: scaledTextStyle(fontSize: 20),
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
                  if (transType == 'pay')
                    Text(
                      transactionDetails.isUdUnit
                          ? 'ud'.tr(args: ['${transactionDetails.amount} '])
                          : '${transactionDetails.amount} $currencyName',
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                  if (transType == 'pay') ScaledSizedBox(height: 10),
                  Text(
                    'fromMinus'.tr(),
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(fontSize: 16),
                  ),
                  Text(
                    transactionDetails.fromAddress!,
                    textAlign: TextAlign.center,
                    style: scaledTextStyle(
                        fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                  Visibility(
                    visible: transactionDetails.fromAddress !=
                        transactionDetails.toAddress,
                    child: Column(
                      children: [
                        ScaledSizedBox(height: 10),
                        Text(
                          'toMinus'.tr(),
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(fontSize: 16),
                        ),
                        Text(
                          transactionDetails.toUsername!,
                          textAlign: TextAlign.center,
                          style: scaledTextStyle(
                              fontSize: 17, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  ScaledSizedBox(height: 20),
                ]),
              ),
              const Spacer(),
              buildTransactionStatus(transactionDetails),
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
                        sub.resetTransactionStatus();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'close'.tr(),
                        style: scaledTextStyle(
                            fontSize: 20, fontWeight: FontWeight.w600),
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

enum TransactionStatus { loading, failed, success, none }

class TransactionDetails {
  String? fromAddress, toAddress, toUsername, amount;
  bool isUdUnit = false;
  String resultText = '';
  TransactionStatus txStatus = TransactionStatus.none;

  TransactionDetails({
    required transactionId,
    required this.fromAddress,
    required this.toAddress,
    required this.toUsername,
    required SubstrateSdk sub,
    required String transType,
  }) {
    final walletProfiles =
        Provider.of<WalletsProfilesProvider>(homeContext, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(homeContext, listen: false);
    String defaultWalletAddress = myWalletProvider.getDefaultWallet().address;
    String defaultWalletName = myWalletProvider.getDefaultWallet().name!;
    String? walletDataName =
        myWalletProvider.getWalletDataByAddress(toAddress ?? '')?.name;

    fromAddress = fromAddress ??
        g1WalletsBox.get(defaultWalletAddress)?.username ??
        defaultWalletName;
    toAddress = toAddress ?? walletProfiles.address;
    toUsername = toUsername ?? walletDataName ?? getShortPubkey(toAddress!);

    amount = walletProfiles.payAmount.text;
    isUdUnit = configBox.get('isUdUnit') ?? false;

    if (sub.transactionStatus.containsKey(transactionId)) {
      calculateTransactionStatus(
          sub.transactionStatus[transactionId], transType);
    }
  }

  void calculateTransactionStatus(String? result, String transType) {
    if (result == null) {
      txStatus = TransactionStatus.none;
    } else if (result.contains('blockHash: ')) {
      txStatus = TransactionStatus.success;
      resultText = 'extrinsicValidated'
          .tr(args: [actionMap[transType] ?? 'strangeTransaction'.tr()]);
    } else if (result.contains('Exception: ')) {
      txStatus = TransactionStatus.failed;
      String exception = result.split('Exception: ')[1];
      resultText = resultMap[exception] ?? exception;
    } else {
      txStatus = TransactionStatus.loading;
      resultText = resultMap[result] ?? 'Unknown status: $result';
    }
  }

  Map<String, String> actionMap = {
    'pay': 'transaction'.tr(),
    'cert': 'certification'.tr(),
    'comfirmIdty': 'identityConfirm'.tr(),
    'revokeIdty': 'revokeAdhesion'.tr(),
    'identityMigration': 'identityMigration'.tr(),
  };

  Map<String, String> resultMap = {
    'sending': 'sending'.tr(),
    'Ready': 'propagating'.tr(),
    'Broadcast': 'validating'.tr(),
    'cert.NotRespectCertPeriod': '24hbetweenCerts'.tr(),
    'identity.CreatorNotAllowedToCreateIdty': '24hbetweenCerts'.tr(),
    'cert.CannotCertifySelf': 'canNotCertifySelf'.tr(),
    'identity.IdtyNameAlreadyExist': 'nameAlreadyExist'.tr(),
    'balances.KeepAlive': '2GDtoKeepAlive'.tr(),
    '1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low':
        'youHaveToFeedThisAccountBeforeUsing'.tr(),
    'Token.FundsUnavailable': 'fundsUnavailable'.tr(),
    'Exception: timeout': 'execTimeoutOver'.tr(),
  };
}
