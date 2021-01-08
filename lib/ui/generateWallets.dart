import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class GenerateWalletScreen extends StatefulWidget {
  @override
  _GenerateWalletState createState() => _GenerateWalletState();
}

class _GenerateWalletState extends State<GenerateWalletScreen> {
  void initState() {
    super.initState();
    DubpRust.setup();
  }

  TextEditingController _mnemonic = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(children: <Widget>[
      TextField(
          enabled: false,
          controller: this._mnemonic,
          maxLines: 2,
          textAlign: TextAlign.center,
          decoration: InputDecoration(),
          style: TextStyle(
              fontSize: 15.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      TextField(
          enabled: false,
          controller: this._pubkey,
          maxLines: 1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(),
          style: TextStyle(
              fontSize: 14.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      TextField(
          enabled: false,
          controller: this._pin,
          maxLines: 1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(),
          style: TextStyle(
              fontSize: 20.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      new RaisedButton(
          onPressed: () => generateMnemonic(),
          child: Text('Générer un wallet', style: TextStyle(fontSize: 20))),
      SizedBox(height: 20)
    ]));
  }

  Future generateMnemonic() async {
    String generatedMnemonic;
    try {
      generatedMnemonic = await DubpRust.genMnemonic(language: Language.french);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }

    generateWallet(generatedMnemonic);
  }

  Future generateWallet(generatedMnemonic) async {
    final walletFile = await _localWallet;
    NewWallet newWallet;
    try {
      newWallet = await DubpRust.genWalletFromMnemonic(
          language: Language.french, mnemonic: generatedMnemonic);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }

    setState(() {
      this._mnemonic.text = generatedMnemonic;
      this._pubkey.text = newWallet.publicKey;
      this._pin.text = newWallet.pin;
    });

    return walletFile.writeAsString('${newWallet.dewif}');
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localWallet async {
    final path = await _localPath;
    return File('$path/wallet.dewif');
  }
}
