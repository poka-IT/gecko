import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:sentry/sentry.dart' as sentry;

class GenerateWalletScreen extends StatefulWidget {
  @override
  _GenerateWalletScreen createState() => _GenerateWalletScreen();
}

class _GenerateWalletScreen extends State<GenerateWalletScreen> {
  void initState() {
    super.initState();
    DubpRust.setup();
  }

  TextEditingController _mnemonic = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _dewif = new TextEditingController();
  TextEditingController _pin = new TextEditingController();

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
          controller: this._dewif,
          maxLines: 3,
          textAlign: TextAlign.center,
          decoration: InputDecoration(),
          style: TextStyle(fontSize: 12.0, color: Colors.red)),
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
      new RaisedButton(
          onPressed: () => generateMnemonic(),
          child: Text('Générer un wallet', style: TextStyle(fontSize: 20))),
    ]));
  }

  Future generateMnemonic() async {
    String generatedMnemonic;
    try {
      generatedMnemonic = await DubpRust.genMnemonic(language: Language.french);
    } catch (e, stack) {
      print(e);
      await sentry.Sentry.captureException(
        e,
        stackTrace: stack,
      );
    }

    // setState(() {
    //   this._mnemonic.text = generatedMnemonic;
    // });
    generateWallet(generatedMnemonic);
  }

  Future generateWallet(generatedMnemonic) async {
    NewWallet newWallet;
    try {
      newWallet = await DubpRust.genWalletFromMnemonic(
          language: Language.french, mnemonic: generatedMnemonic);
    } catch (e, stack) {
      print(e);
      await sentry.Sentry.captureException(
        e,
        stackTrace: stack,
      );
    }

    setState(() {
      this._mnemonic.text = generatedMnemonic;
      this._pubkey.text = newWallet.publicKey;
      this._dewif.text = newWallet.dewif;
      this._pin.text = newWallet.pin;
    });
  }
}
