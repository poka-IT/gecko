import 'dart:io';
import 'dart:math';
import 'package:dubp/dubp.dart';
import 'package:flutter/material.dart';
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
  // GlobalKey<ValidStoreWalletState> _keyValidWallets = GlobalKey();
  void initState() {
    super.initState();
    // DubpRust.setup();
    this._mnemonicController.text = widget.generatedMnemonic;
    this._pubkey.text = widget.generatedWallet.publicKey;
    nbrWord = getRandomInt();
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  TextEditingController _inputRestoreWord = new TextEditingController();
  TextEditingController walletName = new TextEditingController();
  // List _listWallets = [];
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
                  color: Colors.black,
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
                                ? () => storeWallet()
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

  Future storeWallet() async {
    final appPath = await _localPath;
    final walletFile =
        // File('$appPath/wallets/${this.walletName.text}/wallet.dewif');
        File('$appPath/wallets/MonWallet/wallet.dewif');
    // TODO: Use custom wallet name for storage

    final isExist = await Directory('$appPath/wallets').exists();
    if (isExist == false) {
      new Directory('$appPath/wallets').createSync();
    }

    new Directory('$appPath/wallets/${this.walletName.text}').createSync();
    walletFile.writeAsString('${widget.generatedWallet.dewif}');
    _pin.clear();

    // await getAllWalletsNames();
    Navigator.pop(context, true);
    Navigator.pop(context, this._pubkey.text);
    // setState(() {});
    // FocusScope.of(context).unfocus();

    return this.walletName.text;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // Future<List> getAllWalletsNames() async {
  //   final _appPath = await getApplicationDocumentsDirectory();
  //   // List _listWallets = [];
  //   // _listWallets.add('tortuuue');
  //   this._listWallets.clear();
  //   print(_appPath);

  //   _appPath
  //       .list(recursive: false, followLinks: false)
  //       .listen((FileSystemEntity entity) {
  //     print(entity.path.split('/').last);
  //     this._listWallets.add(entity.path.split('/').last);
  //   });

  //   return _listWallets;
  //   // final _local = await _appPath.path.list().toList();
  // }

  void checkAskedWord(value) {
    print(this._mnemonicController.text.split(' ')[nbrWord]);
    print(value);
    if (this._mnemonicController.text.split(' ')[nbrWord] == value) {
      print('Word is OK');
      isAskedWordValid = true;
    } else {
      isAskedWordValid = false;
    }
    setState(() {});
  }

  int getRandomInt() {
    var rng = new Random();
    return rng.nextInt(12);
  }

  void nameChanged() {
    setState(() {});
  }
}
