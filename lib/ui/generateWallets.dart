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

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  String generatedMnemonic;
  NewWallet actualWallet;
  final formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Column(children: <Widget>[
      SizedBox(height: 8),
      Text(
        'Clé publique:',
        style: TextStyle(
            fontSize: 15.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400),
      ),
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
      SizedBox(height: 8),
      Text(
        'Phrase secrète:',
        style: TextStyle(
            fontSize: 15.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400),
      ),
      TextField(
          enabled: false,
          controller: this._mnemonicController,
          maxLines: 3,
          textAlign: TextAlign.center,
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(15.0),
          ),
          style: TextStyle(
              fontSize: 22.0,
              color: Colors.black,
              fontWeight: FontWeight.w400)),
      SizedBox(height: 8),
      Text(
        'Code PIN:',
        style: TextStyle(
            fontSize: 15.0,
            color: Colors.grey[600],
            fontWeight: FontWeight.w400),
      ),
      TextField(
          enabled: false,
          controller: this._pin,
          maxLines: 1,
          textAlign: TextAlign.center,
          decoration: InputDecoration(),
          style: TextStyle(
              fontSize: 30.0,
              color: Colors.black,
              fontWeight: FontWeight.bold)),
      SizedBox(height: 12),
      new RaisedButton(
          color: Color(0xffFFD68E),
          onPressed: () => generateMnemonic(),
          child: Text('Générer un wallet', style: TextStyle(fontSize: 20))),
      SizedBox(height: 30),
      Expanded(
          child: Align(
              alignment: Alignment.bottomCenter,
              child: new RaisedButton(
                  color: Color(0xffFFD68E),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return ValidStoreWalletScreen(
                            generatedMnemonic: this.generatedMnemonic,
                            generatedWallet:
                                this.actualWallet); //, this.actualWallet);
                      }),
                    ).then((value) => setState(() {
                          if (value) {
                            _pin.clear();
                            _mnemonicController.clear();
                            _pubkey.clear();
                          }
                        }));
                  },
                  child: Text('Enregistrer ce wallet',
                      style: TextStyle(fontSize: 20))))),
      SizedBox(height: 15)
    ]));
  }

  Future generateMnemonic() async {
    try {
      this.generatedMnemonic =
          await DubpRust.genMnemonic(language: Language.french);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }
    this.actualWallet = await generateWallet(this.generatedMnemonic);
    return this.generatedMnemonic;
  }

  Future generateWallet(generatedMnemonic) async {
    try {
      this.actualWallet = await DubpRust.genWalletFromMnemonic(
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
      this._mnemonicController.text = generatedMnemonic;
      this._pubkey.text = actualWallet.publicKey;
      this._pin.text = actualWallet.pin;
    });

    return actualWallet;
  }
}

class ValidStoreWalletScreen extends StatefulWidget {
  final String generatedMnemonic;
  final NewWallet generatedWallet;

  ValidStoreWalletScreen(
      {Key validationKey,
      @required this.generatedMnemonic,
      @required this.generatedWallet})
      : super(key: validationKey);

  @override
  _ValidStoreWalletScreen createState() => _ValidStoreWalletScreen();
}

class _ValidStoreWalletScreen extends State<ValidStoreWalletScreen> {
  void initState() {
    super.initState();
    // DubpRust.setup();
    this._mnemonicController.text = widget.generatedMnemonic;
    this._pubkey.text = widget.generatedWallet.publicKey;
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(children: <Widget>[
          TextField(
              enabled: false,
              controller: this._mnemonicController,
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
          new RaisedButton(
              color: Color(0xffFFD68E),
              onPressed: () => storeWallet(widget.generatedWallet),
              child: Text('Confirmer', style: TextStyle(fontSize: 20))),
        ]),
      ),
    );
  }

  Future storeWallet(actualWallet) async {
    final walletFile = await _localWallet;
    walletFile.writeAsString('${widget.generatedWallet.dewif}');
    _pin.clear();
    Navigator.pop(context, true);
    FocusScope.of(context).unfocus();
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
