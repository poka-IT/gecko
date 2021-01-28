import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:gecko/models/myWallets.dart';
import 'dart:io';

// ignore: must_be_immutable
class SettingsScreen extends StatelessWidget {
  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  String newWalletName;

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];
  Directory appPath;

  MyWalletsProvider _myWallets = MyWalletsProvider();

  @override
  Widget build(BuildContext context) {
    // getAppDirectory();
    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Paramètres'),
        )),
        body: Column(children: <Widget>[
          SizedBox(height: 20),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                      height: 100,
                      width: 1000,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Colors
                                .redAccent, //Color(0xffFFD68E), // background
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () => {
                                print('Suppression de tous les wallets'),
                                _myWallets.deleteAllWallet(context)
                              },
                          child: Text(
                              "EFFACER TOUS MES PORTEFEUILLES, LE TEMPS DE L'ALPHA",
                              style: TextStyle(fontSize: 20)))))),
          SizedBox(height: 50),
        ]));
  }
}
