import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

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
  TextEditingController _enterPin = new TextEditingController();
  String validPin = 'NO PIN';

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
      SizedBox(height: 12),
      new RaisedButton(
          onPressed: () => generateMnemonic(),
          child: Text('Générer un wallet', style: TextStyle(fontSize: 20))),
      SizedBox(height: 20),
      TextField(
          controller: this._enterPin,
          onChanged: (validPin) {
            this.validPin = validPin ?? 'NO PIN';
            print('PIN: ' + this.validPin);
          },
          maxLines: 1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            hintText: 'Tappez votre code PIN',
            hintStyle: TextStyle(fontSize: 15),
            contentPadding: EdgeInsets.symmetric(horizontal: 7, vertical: 15),
          ),
          style: TextStyle(
              fontSize: 20.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      new RaisedButton(
          onPressed: () => readLocalWallet(this.validPin.toUpperCase()),
          child: Text('Lire le wallet local', style: TextStyle(fontSize: 20))),
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
      this._dewif.text = newWallet.dewif;
      this._pin.text = newWallet.pin;
    });

    return walletFile.writeAsString('${newWallet.dewif}');
  }

  Future getPubkeyFromDewif(_dewif, _pin) async {
    String _pubkey;
    RegExp regExp = new RegExp(
      r'^[A-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(_pin) == true && _pin.length == 6) {
      print("Le format du code PIN est correct.");
    } else {
      print('Format de code PIN invalide');
      return 'false';
    }
    try {
      _pubkey = await DubpRust.getDewifPublicKey(dewif: _dewif, pin: _pin);
      setState(() {
        this._pubkey.text = _pubkey;
      });

      return _pubkey;
    } catch (e, stack) {
      print('Bad PIN code !');
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      return 'false';
    }
  }

  Future readLocalWallet(String _pin) async {
    // print(pin);
    try {
      final file = await _localWallet;
      String _localDewif = await file.readAsString();
      String _localPubkey;

      // _localPubkey = await getPubkeyFromDewif(_localDewif, _pin)?

      if ((_localPubkey = await getPubkeyFromDewif(_localDewif, _pin)) !=
          'false') {
        setState(() {
          this._mnemonic.text = '';
          this._pubkey.text = _localPubkey;
          this._dewif.text = _localDewif;
          this._pin.text = _pin;
        });

        return _localDewif;
      } else {
        throw 'Bad pubkey';
      }
    } catch (e) {
      print('ERROR READING FILE: $e');
      return 0;
    }
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
