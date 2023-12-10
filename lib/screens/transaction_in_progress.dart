import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';

class TransactionInProgress extends StatelessWidget {
  const TransactionInProgress(
      {Key? key,
      this.transType = 'pay',
      this.fromAddress,
      this.toAddress,
      this.toUsername})
      : super(key: key);
  final String transType;
  final String? fromAddress;
  final String? toAddress;
  final String? toUsername;

  @override
  Widget build(BuildContext context) {
    final sub = Provider.of<SubstrateSdk>(context, listen: true);
    final walletProfiles =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    var txStatus = TransactionStatus.none;
    final result = sub.transactionStatus;

    final from = fromAddress ??
        g1WalletsBox
            .get(myWalletProvider.getDefaultWallet().address)
            ?.username ??
        myWalletProvider.getDefaultWallet().name!;

    String to = toAddress ?? walletProfiles.address;
    to =
        myWalletProvider.getWalletDataByAddress(to)?.name ?? getShortPubkey(to);

    final amount = walletProfiles.payAmount.text;
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;

    final Map<String, String> actionMap = {
      'pay': 'transaction'.tr(),
      'cert': 'certification'.tr(),
      'comfirmIdty': 'identityConfirm'.tr(),
      'revokeIdty': 'revokeAdhesion'.tr(),
      'identityMigration': 'identityMigration'.tr(),
    };

    String resultText = '';
    final Map<String, String> resultMap = {
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

    if (result == null) {
      txStatus = TransactionStatus.none;
    } else if (result.contains('blockHash: ')) {
      txStatus = TransactionStatus.success;
      resultText = 'extrinsicValidated'
          .tr(args: [actionMap[transType] ?? 'strangeTransaction'.tr()]);
    } else if (result.contains('Exception: ')) {
      txStatus = TransactionStatus.failed;
      resultText = "${"anErrorOccurred".tr()}:\n";
      final String exception = result.split('Exception: ')[1];
      resultText = resultMap[exception] ?? "$resultText\n$exception";
      log.e('Error: $exception');
    } else {
      txStatus = TransactionStatus.loading;
      resultText = resultMap[result] ?? 'unknown status...';
    }

    log.d("$transType :: ${actionMap[transType]} :: $result");

    return PopScope(
      onPopInvoked: (_) {
        sub.transactionStatus = null;
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
                      actionMap[transType] ?? 'strangeTransaction'.tr()
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
                        isUdUnit
                            ? 'ud'.tr(args: ['$amount '])
                            : '$amount $currencyName',
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
                      from,
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(
                          fontSize: 17, fontWeight: FontWeight.w500),
                    ),
                    Visibility(
                      visible: from != to,
                      child: Column(
                        children: [
                          ScaledSizedBox(height: 10),
                          Text(
                            'toMinus'.tr(),
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(fontSize: 16),
                          ),
                          Text(
                            toUsername ?? to,
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
                Column(children: [
                  Visibility(
                    visible: txStatus == TransactionStatus.loading,
                    child: ScaledSizedBox(
                      height: 17,
                      width: 17,
                      child: const CircularProgressIndicator(
                        color: orangeC,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: txStatus == TransactionStatus.success,
                    child: Icon(
                      Icons.done_all,
                      size: scaleSize(32),
                      color: Colors.greenAccent,
                    ),
                  ),
                  Visibility(
                    visible: txStatus == TransactionStatus.failed,
                    child: Icon(
                      Icons.close,
                      size: scaleSize(32),
                      color: Colors.redAccent,
                    ),
                  ),
                  ScaledSizedBox(height: 10),
                  Visibility(
                    visible: txStatus != TransactionStatus.none,
                    child: Text(
                      resultText,
                      textAlign: TextAlign.center,
                      style: scaledTextStyle(fontSize: 17),
                    ),
                  ),
                ]),
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
                          foregroundColor: Colors.white, elevation: 4,
                          backgroundColor: orangeC, // foreground
                        ),
                        onPressed: () {
                          sub.transactionStatus = null;
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
              ])),
        ),
      ),
    );
  }
}

enum TransactionStatus { loading, failed, success, none }
