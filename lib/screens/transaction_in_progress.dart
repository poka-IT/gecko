import 'package:easy_localization/easy_localization.dart';

import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

class TransactionInProgress extends StatelessWidget {
  const TransactionInProgress(
      {Key? key, this.transType = 'pay', this.fromAddress, this.toAddress})
      : super(key: key);
  final String transType;
  final String? fromAddress;
  final String? toAddress;

  @override
  Widget build(BuildContext context) {
    SubstrateSdk sub = Provider.of<SubstrateSdk>(context, listen: true);
    WalletsProfilesProvider walletViewProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    bool isValid = false;

    String resultText;
    bool isLoading = true;
    // Map jsonResult;
    final result = sub.transactionStatus;

    // sub.spawnBlock();

    log.d(walletViewProvider.address);

    final from = fromAddress ?? myWalletProvider.getDefaultWallet().name!;
    final to = toAddress ?? getShortPubkey(walletViewProvider.address);
    final amount = walletViewProvider.payAmount.text;
    String actionName = '';
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;

    switch (transType) {
      case 'pay':
        {
          actionName = 'transaction'.tr();
        }
        break;
      case 'cert':
        {
          actionName = 'certification'.tr();
        }
        break;
      case 'comfirmIdty':
        {
          actionName = "identityConfirm".tr();
        }
        break;
      case 'revokeIdty':
        {
          actionName = "revokeAdhesion".tr();
        }
        break;
      case 'identityMigration':
        {
          actionName = "identityMigration".tr();
        }
        break;
      default:
        {
          actionName = 'strangeTransaction'.tr();
        }
    }

    switch (result) {
      case '':
        {
          resultText = 'sending'.tr();
        }
        break;
      case 'Ready':
        {
          resultText = 'propagating'.tr();
        }
        break;
      case 'Broadcast':
        {
          resultText = 'validating'.tr();
        }
        break;
      default:
        {
          isLoading = false;
          // jsonResult = json.decode(_result);
          log.d(result);
          if (result.contains('blockHash: ')) {
            isValid = true;
            resultText = 'extrinsicValidated'.tr(args: [actionName]);
            log.i(
                'g1migration Bloc of last transaction: ${sub.blocNumber} --- $result');
          } else {
            isValid = false;
            resultText = "${"anErrorOccurred".tr()}:\n";
            final List exceptionSplit = result.split('Exception: ');
            String exception;
            if (exceptionSplit.length > 1) {
              exception = exceptionSplit[1];
            } else {
              exception = exceptionSplit[0];
            }
            // log.d('expection: $_exception');
            switch (exception) {
              case 'cert.NotRespectCertPeriod':
              case 'identity.CreatorNotAllowedToCreateIdty':
                {
                  resultText = "24hbetweenCerts".tr();
                }
                break;
              case 'cert.CannotCertifySelf':
                {
                  resultText = "canNotCertifySelf".tr();
                }
                break;
              case 'identity.IdtyNameAlreadyExist':
                {
                  resultText = "nameAlreadyExist".tr();
                }
                break;
              case 'balances.KeepAlive':
                {
                  resultText = "2GDtoKeepAlive".tr();
                }
                break;
              case '1010: Invalid Transaction: Inability to pay some fees , e.g. account balance too low':
                {
                  resultText = "youHaveToFeedThisAccountBeforeUsing".tr();
                }
                break;

              case 'timeout':
                {
                  resultText += "execTimeoutOver".tr();
                }
                break;
              default:
                {
                  resultText += "\n$exception";
                }
                break;
            }
          }
        }
    }

    return WillPopScope(
        onWillPop: () {
          sub.transactionStatus = '';
          Navigator.pop(context);
          if (transType == 'pay' || transType == 'identityMigration') {
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
                      Text('extrinsicInProgress'.tr(args: [actionName]))
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
                        to,
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
                            if (transType == 'pay' ||
                                transType == 'identityMigration') {
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
        ));
  }
}
