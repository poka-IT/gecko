import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
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
    bool isValid = false;
    bool isLoading = false;
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
      '': 'sending'.tr(),
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

    if (result.contains('blockHash: ')) {
      isValid = true;
      resultText = 'extrinsicValidated'
          .tr(args: [actionMap[transType] ?? 'strangeTransaction'.tr()]);
      log.i('Bloc of last transaction: ${sub.blocNumber} --- $result');
    } else if (result.contains('Exception: ')) {
      resultText = "${"anErrorOccurred".tr()}:\n";
      final String exception = result.split('Exception: ')[1];
      resultText = resultMap[exception] ?? "$resultText\n$exception";
      log.d('Error: $exception');
    } else {
      isLoading = true;
      resultText = resultMap[result] ?? 'unknown status...';
    }

    log.d("$transType :: ${actionMap[transType]} :: $result");

    return WillPopScope(
      onWillPop: () {
        sub.transactionStatus = '';
        Navigator.pop(context);
        if (transType == 'identityMigration') {
          Navigator.pop(context);
        }
        return Future<bool>.value(true);
      },
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: SizedBox(
              height: 22,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text('extrinsicInProgress'.tr(args: [
                      actionMap[transType] ?? 'strangeTransaction'.tr()
                    ]))
                  ]),
            )),
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
                    const SizedBox(height: 10),
                    if (transType == 'pay')
                      Text(
                        isUdUnit
                            ? 'ud'.tr(args: ['$amount '])
                            : '$amount $currencyName',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    if (transType == 'pay') const SizedBox(height: 10),
                    Text(
                      'fromMinus'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      from,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'toMinus'.tr(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                    Text(
                      toUsername ?? to,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
                // const SizedBox(height: 20, width: double.infinity),
                const Spacer(),
                Column(children: [
                  Visibility(
                    visible: isLoading,
                    child: const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        color: orangeC,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: !isLoading,
                    child: Icon(
                      isValid ? Icons.done_all : Icons.close,
                      size: 35,
                      color: isValid ? Colors.greenAccent : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    resultText,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 19 * ratio),
                  ),
                ]),
                const Spacer(),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: 380 * ratio,
                      height: 60 * ratio,
                      child: ElevatedButton(
                        key: keyCloseTransactionScreen,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, elevation: 4,
                          backgroundColor: orangeC, // foreground
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          sub.transactionStatus = '';
                          if (transType == 'identityMigration') {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          'close'.tr(),
                          style: TextStyle(
                              fontSize: 23 * ratio,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isTall ? 80 : 20)
              ])),
        ),
      ),
    );
  }
}
