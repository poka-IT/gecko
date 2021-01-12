import 'dart:io';
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
  }

  TextEditingController _mnemonicController = new TextEditingController();
  TextEditingController _pubkey = new TextEditingController();
  TextEditingController _pin = new TextEditingController();
  String walletName = 'MonWallet';
  List _listWallets = [];

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
          new ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Color(0xffFFD68E), // background
                onPrimary: Colors.black, // foreground
              ),
              onPressed: () => storeWallet(),
              child: Text('Confirmer', style: TextStyle(fontSize: 20))),
        ]),
      ),
    );
  }

  Future storeWallet() async {
    final appPath = await _localPath;
    final walletFile = File('$appPath/wallets/${this.walletName}/wallet.dewif');

    final isExist = await Directory('$appPath/wallets').exists();
    if (isExist == false) {
      new Directory('$appPath/wallets').createSync();
    }

    new Directory('$appPath/wallets/${this.walletName}').createSync();
    walletFile.writeAsString('${widget.generatedWallet.dewif}');
    _pin.clear();

    await getAllWalletsNames();
    Navigator.pop(context, true);
    Navigator.pop(context, true);
    // setState(() {});
    // FocusScope.of(context).unfocus();

    return this.walletName;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List> getAllWalletsNames() async {
    final _appPath = await getApplicationDocumentsDirectory();
    // List _listWallets = [];
    // _listWallets.add('tortuuue');
    this._listWallets.clear();
    print(_appPath);

    _appPath
        .list(recursive: false, followLinks: false)
        .listen((FileSystemEntity entity) {
      print(entity.path.split('/').last);
      this._listWallets.add(entity.path.split('/').last);
    });

    return _listWallets;
    // final _local = await _appPath.path.list().toList();
  }
}
