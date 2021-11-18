import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/change_pin.dart';
import 'package:gecko/models/my_wallets.dart';
import 'dart:io';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChangePinScreen extends StatelessWidget with ChangeNotifier {
  ChangePinScreen(
      {Key keyMyWallets,
      @required this.walletName,
      @required this.walletProvider})
      : super(key: keyMyWallets);
  final String walletName;
  final MyWalletsProvider walletProvider;
  Directory appPath;
  NewWallet _newWalletFile;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ChangePinProvider _changePin = Provider.of<ChangePinProvider>(context);
    // _walletOptions.changePin(walletName, oldPin);
    // _walletOptions.newPin.text = _tmpPin;
    return WillPopScope(
      onWillPop: () {
        _changePin.newPin.text = '';
        return Future<bool>.value(true);
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _changePin.newPin.text = '';
                  Navigator.of(context).pop();
                }),
            title: SizedBox(
              height: 22,
              child: Text(walletName),
            )),
        body: Center(
          child: SafeArea(
            child: Column(children: <Widget>[
              const SizedBox(height: 80),
              Text(
                'Choisissez un code secret autogénéré :',
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
                      controller: _changePin.newPin,
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
                      _newWalletFile =
                          await _changePin.changePin(walletProvider.pinCode);
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
                  onPressed: _changePin.newPin.text != ''
                      ? () {
                          _changePin.newPin.text = '';
                          _changePin.storeNewPinChest(context, _newWalletFile);
                          walletProvider.pinCode = _changePin.newPin.text;
                        }
                      : null,
                  child: const Text(
                    'Confirmer',
                    style: TextStyle(fontSize: 28),
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
