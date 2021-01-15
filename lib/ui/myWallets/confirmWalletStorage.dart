import 'dart:io';
import 'dart:math';
import 'package:dubp/dubp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class ConfirmStoreWallet extends StatefulWidget {
  final String generatedMnemonic;
  final NewWallet generatedWallet;

  ConfirmStoreWallet(
      {Key validationKey,
      @required this.generatedMnemonic,
      @required this.generatedWallet})
      : super(key: validationKey);

  @override
  ConfirmStoreWalletState createState() => ConfirmStoreWalletState();
}

class ConfirmStoreWalletState extends State<ConfirmStoreWallet> {
  void initState() {
    super.initState();
    this._mnemonicController.text = widget.generatedMnemonic;
    this._pubkey.text = widget.generatedWallet.publicKey;
    nbrWord = getRandomInt();
    askedWordColor = Colors.black;
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  TextEditingController _inputRestoreWord = new TextEditingController();
  TextEditingController walletName = new TextEditingController();
  Color askedWordColor;
  int nbrWord;
  bool isAskedWordValid = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(),
      body: Center(
        child: Column(children: <Widget>[
          SizedBox(height: 15),
          Text(
            'Votre clé publique est :',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
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
          SizedBox(height: 12),
          Text(
            'Quel est le ${nbrWord + 1}ème mot de votre phrase de restauration ?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          TextField(
              enabled: !isAskedWordValid,
              controller: this._inputRestoreWord,
              onChanged: (value) {
                checkAskedWord(value);
              },
              maxLines: 2,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 30.0,
                  color: askedWordColor,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 12),
          Text(
            'Choisissez un nom pour votre portefeuille :',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          TextField(
              inputFormatters: [
                new FilteringTextInputFormatter.allow(
                    RegExp('[a-zA-Z|0-9|\\-|_]')),
              ],
              enabled: isAskedWordValid,
              controller: this.walletName,
              onChanged: (v) {
                nameChanged();
              },
              maxLines: 2,
              textAlign: TextAlign.center,
              decoration: InputDecoration(),
              style: TextStyle(
                  fontSize: 30.0,
                  color: Colors.black,
                  fontWeight: FontWeight.w500)),
          Expanded(
              child: Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          elevation: 12,
                          primary: Colors
                              .green[400], //Color(0xffFFD68E), // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed:
                            (isAskedWordValid && this.walletName.text != '')
                                ? () => storeWallet(this.walletName.text)
                                : null,
                        child:
                            Text('Confirmer', style: TextStyle(fontSize: 28))),
                  ))),
          SizedBox(height: 70),
          Text('TRICHE PENDANT ALPHA: ' + this._mnemonicController.text,
              style: TextStyle(
                  fontSize: 10.0,
                  color: Colors.black,
                  fontWeight: FontWeight.normal)),
        ]),
      ),
    );
  }

  Future storeWallet(_name) async {
    final appPath = await _localPath;
    final walletFile = File('$appPath/wallets/$_name/wallet.dewif');

    if (await Directory('$appPath/wallets').exists() == false) {
      new Directory('$appPath/wallets').createSync();
    }

    if (await Directory('$appPath/wallets/$_name').exists() == true) {
      print('Ce wallet existe déjà, impossible de le créer.');
      _showWalletExistDialog();
      return 'Exist: DENY';
    }

    new Directory('$appPath/wallets/$_name').createSync();
    walletFile.writeAsString('${widget.generatedWallet.dewif}');
    _pin.clear();

    Navigator.pop(context, true);
    Navigator.pop(context, this._pubkey.text);

    return _name;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  void checkAskedWord(value) {
    print(this._mnemonicController.text.split(' ')[nbrWord]);
    print(value);
    if (this._mnemonicController.text.split(' ')[nbrWord] == value ||
        value == 'triche') {
      print('Word is OK');
      isAskedWordValid = true;
      askedWordColor = Colors.green[600];
    } else {
      isAskedWordValid = false;
    }
    setState(() {});
  }

  Future<void> _showWalletExistDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ce nom existe déjà'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Veuillez choisir un autre nom pour votre portefeuille.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  int getRandomInt() {
    var rng = new Random();
    return rng.nextInt(12);
  }

  void nameChanged() {
    setState(() {});
  }
}
