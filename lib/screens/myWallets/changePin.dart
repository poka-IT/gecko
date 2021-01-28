import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:gecko/models/walletOptions.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
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
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    _walletOptions.changePin(walletName, oldPin);
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
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
                    controller: _walletOptions.newPin,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(),
                    style: TextStyle(
                        fontSize: 30.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.replay),
                  color: Color(0xffD28928),
                  onPressed: () async {
                    _newWalletFile =
                        await _walletOptions.changePin(walletName, oldPin);
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
                  primary: Colors.green[400], //Color(0xffFFD68E), // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: () => _walletOptions.storeWallet(
                    context, walletName, _newWalletFile),
                child: Text('Confirmer', style: TextStyle(fontSize: 28))),
          )
        ]))));
  }
}
