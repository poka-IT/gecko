import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/changePin.dart';
import 'dart:io';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ChangePinScreen extends StatelessWidget with ChangeNotifier {
  ChangePinScreen(
      {Key keyMyWallets, @required this.walletName, @required this.oldPin})
      : super(key: keyMyWallets);
  final String walletName;
  final oldPin;
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
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
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
              SizedBox(height: 80),
              Text(
                'Choisissez un code secret autogénéré :',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              SizedBox(height: 30),
              Container(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: <Widget>[
                    TextField(
                        enabled: true,
                        controller: _changePin.newPin,
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(),
                        style: TextStyle(
                            fontSize: 30.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: Icon(Icons.replay),
                      color: orangeC,
                      onPressed: () async {
                        _newWalletFile =
                            await _changePin.changePin(walletName, oldPin);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),
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
                            _changePin.storeNewPinChest(
                                context, _newWalletFile);
                          }
                        : null,
                    child: Text('Confirmer', style: TextStyle(fontSize: 28))),
              )
            ])))));
  }
}
