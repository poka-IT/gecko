import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key keyGenWallet}) : super(key: keyGenWallet);
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void initState() {
    super.initState();
  }

  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  String newWalletName;

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];
  Directory appPath;

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
                                _deleteWallet()
                              },
                          child: Text(
                              "EFFACER TOUS MES PORTEFEUILLES, LE TEMPS DE L'ALPHA",
                              style: TextStyle(fontSize: 20)))))),
          SizedBox(height: 50),
        ]));
  }

  Future<int> _deleteWallet() async {
    try {
      final appPath = await _localPath;
      final _walletsFolder = Directory('$appPath/wallets');
      print('DELETE THAT ?: $_walletsFolder');

      final bool _answer = await _confirmDeletingWallets();

      if (_answer) {
        _walletsFolder.deleteSync(recursive: true);
        _walletsFolder.createSync();
        Navigator.pop(context);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<bool> _confirmDeletingWallets() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              'Êtes-vous sûr de vouloir supprimer tous vos portefeuilles ?'),
          content: SingleChildScrollView(child: Text('')),
          actions: <Widget>[
            TextButton(
              child: Text("Non"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              child: Text("Oui"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
