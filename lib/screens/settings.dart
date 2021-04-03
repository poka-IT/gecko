import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/screens/myWallets/generateWallets.dart';
import 'dart:io';
import 'package:gecko/screens/myWallets/importWallet.dart';
import 'package:gecko/globals.dart';

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
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    // getAppDirectory();
    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Paramètres'),
        )),
        body: Column(children: <Widget>[
          SizedBox(height: 40),
          SizedBox(
              height: 50,
              width: 500,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: Color(0xFFFFCA6F), // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return ImportWalletScreen();
                        }),
                      ).then((value) => {
                            if (value == true) {Navigator.pop(context)}
                          }),
                  child: Text("Importer un portefeuille Cesium",
                      style: TextStyle(fontSize: 15)))),
          SizedBox(height: 20),
          SizedBox(
              height: 50,
              width: 500,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: Color(0xFFFFCA6F), // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return GenerateWalletsScreen();
                        }),
                      ).then((value) => {
                            if (value == true) {Navigator.pop(context)}
                          }),
                  child: Text("Générer un nouveau trousseau",
                      style: TextStyle(fontSize: 15)))),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                      height: 100,
                      width: 500,
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Colors.redAccent, // background
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () async => {
                                log.i('Suppression de tous les wallets'),
                                await _myWallets.deleteAllWallet(context)
                              },
                          child: Text(
                              "EFFACER TOUS MES PORTEFEUILLES, LE TEMPS DE L'ALPHA",
                              style: TextStyle(fontSize: 20)))))),
          SizedBox(height: 50),
        ]));
  }
}
