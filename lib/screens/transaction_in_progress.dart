import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:provider/provider.dart';
// import 'package:gecko/models/home.dart';
// import 'package:provider/provider.dart';

// ignore: must_be_immutable
class TransactionInProgress extends StatelessWidget {
  const TransactionInProgress({Key? key, this.transType = 'pay'})
      : super(key: key);
  final String transType;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: true);
    WalletsProfilesProvider _walletViewProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    String _resultText;
    bool isLoading = true;
    // Map jsonResult;
    final _result = _sub.transactionStatus;

    log.d(_walletViewProvider.pubkey!);

    final from = _myWalletProvider.getDefaultWallet()!.name!;
    final to = getShortPubkey(_walletViewProvider.pubkey!);
    final amount = _walletViewProvider.payAmount.text;
    String _actionName = '';

    switch (transType) {
      case 'pay':
        {
          _actionName = 'Transaction';
        }
        break;
      case 'cert':
        {
          _actionName = 'Certification';
        }
        break;
      default:
        {
          _actionName = 'Transaction étrange';
        }
    }

    switch (_result) {
      case '':
        {
          _resultText = 'Envoi en cours ...';
        }
        break;
      case 'sent':
        {
          _resultText = 'En cours de validation ...';
        }
        break;
      default:
        {
          isLoading = false;
          // jsonResult = json.decode(_result);
          log.d(_result);
          if (_result.contains('blockHash: ')) {
            _resultText = '$_actionName validé !';
          } else {
            _resultText = "Une erreur s'est produite:\n\n$_result";
          }
        }
    }

    return WillPopScope(
        onWillPop: () {
          _sub.transactionStatus = '';
          Navigator.pop(context);
          Navigator.pop(context);
          if (_actionName == 'pay') {
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
                    children: <Widget>[Text('$_actionName en cours')]),
              )),
          body: SafeArea(
            child: Align(
                alignment: FractionalOffset.bottomCenter,
                child: Column(children: <Widget>[
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        yellowC,
                        const Color(0xfffafafa),
                      ],
                    )),
                    child: Column(children: <Widget>[
                      const SizedBox(height: 10),
                      if (transType == 'pay')
                        Text(
                          '$amount $currencyName',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                      if (transType == 'pay') const SizedBox(height: 10),
                      const Text(
                        'de',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(
                        from,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'vers',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18),
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
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: orangeC,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _resultText,
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
                          style: ElevatedButton.styleFrom(
                            elevation: 4,
                            primary: orangeC, // background
                            onPrimary: Colors.white, // foreground
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            if (_actionName == 'pay') {
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            'Fermer',
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
