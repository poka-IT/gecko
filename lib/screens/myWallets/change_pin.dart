import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:durt/durt.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/stateful_wrapper.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'dart:io';

import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChangePinScreen extends StatelessWidget with ChangeNotifier {
  ChangePinScreen(
      {Key? keyMyWallets,
      required this.walletName,
      required this.walletProvider})
      : super(key: keyMyWallets);
  final String? walletName;
  final MyWalletsProvider walletProvider;
  Directory? appPath;

  TextEditingController newPin = TextEditingController();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    return WillPopScope(
      onWillPop: () {
        newPin.text = '';
        return Future<bool>.value(true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          elevation: 1,
          toolbarHeight: 60 * ratio,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                newPin.text = '';
                Navigator.of(context).pop();
              }),
          title: SizedBox(
            height: 22,
            child: Text(walletName!),
          ),
        ),
        body: Center(
          child: SafeArea(
            child: Column(children: <Widget>[
              StatefulWrapper(
                onInit: () {
                  newPin.text = randomSecretCode(pinLength);
                },
                child: Container(),
              ),
              const SizedBox(height: 80),
              Text(
                'choosePassword'.tr(),
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              const SizedBox(height: 30),
              Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      enabled: false,
                      controller: newPin,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(),
                      style: const TextStyle(
                          fontSize: 30.0,
                          color: Colors.black,
                          fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.replay),
                    color: orangeC,
                    onPressed: () async {
                      newPin.text = randomSecretCode(pinLength);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 12,
                    primary: Colors.green[400], //smoothYellow, // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: () async {
                    WalletData defaultWallet =
                        _myWalletProvider.getDefaultWallet();

                    String? _pin;
                    if (_myWalletProvider.pinCode == '') {
                      _pin = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (homeContext) {
                            return UnlockingWallet(wallet: defaultWallet);
                          },
                        ),
                      );
                    }
                    if (_pin != null || _myWalletProvider.pinCode != '') {
                      await _sub.changePassword(context, defaultWallet.address!,
                          walletProvider.pinCode, newPin.text);
                      walletProvider.pinCode = newPin.text;
                      newPin.text = '';
                      Navigator.pop(context);
                    }
                  },
                  child: Text(
                    'confirm'.tr(),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              )
            ]),
          ),
        ),
      ),
    );
  }
}
