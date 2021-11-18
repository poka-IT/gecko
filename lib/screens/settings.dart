import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/home.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/screens/myWallets/generate_wallets.dart';
import 'dart:io';
import 'package:gecko/screens/myWallets/import_wallet.dart';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

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

  final MyWalletsProvider _myWallets = MyWalletsProvider();

  SettingsScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    HomeProvider _homeProvider = Provider.of<HomeProvider>(context);

    // getAppDirectory();
    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Paramètres'),
            )),
        body: Column(children: <Widget>[
          const SizedBox(height: 40),
          SizedBox(
              height: 70,
              width: 500,
              child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: yellowC, // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return const ImportWalletScreen();
                        }),
                      ).then((value) => {
                            if (value == true) {Navigator.pop(context)}
                          }),
                  child: const Text("Importer un portefeuille Cesium",
                      style: TextStyle(fontSize: 16)))),
          const SizedBox(height: 30),
          SizedBox(
              height: 70,
              width: 500,
              child: ElevatedButton(
                  key: const Key('generateKeychain'),
                  style: ElevatedButton.styleFrom(
                    elevation: 5,
                    primary: yellowC, // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) {
                          return GenerateFastChestScreen();
                        }),
                      ),
                  child: const Text("Générer un nouveau trousseau",
                      style: TextStyle(fontSize: 16)))),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                      height: 100,
                      width: 500,
                      child: ElevatedButton(
                          key: const Key('deleteAllWallets'),
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            primary: Colors.redAccent, // background
                            onPrimary: Colors.black, // foreground
                          ),
                          onPressed: () async => {
                                log.i('Suppression de tous les wallets'),
                                await _myWallets
                                    .deleteAllWallet(context)
                                    .then((v) => _homeProvider.rebuildWidget())
                              },
                          child: const Text("EFFACER TOUS MES PORTEFEUILLES",
                              style: TextStyle(fontSize: 20)))))),
          const SizedBox(height: 50),
        ]));
  }
}
