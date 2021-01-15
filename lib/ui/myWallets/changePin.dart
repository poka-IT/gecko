import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';
import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen(
      {Key keyMyWallets, @required this.walletName, @required this.oldPin})
      : super(key: keyMyWallets);

  final String walletName;
  final oldPin;
  @override
  ChangePinScreenState createState() => ChangePinScreenState();
}

class ChangePinScreenState extends State<ChangePinScreen> {
  Directory appPath;
  TextEditingController _newPin = new TextEditingController();
  bool ischangedPin = false;
  NewWallet newWalletFile;

  Future<NewWallet> get badWallet => null;

  void initState() {
    super.initState();
    DubpRust.setup();
    changePin(widget.walletName, widget.oldPin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
            title: SizedBox(
          height: 25,
          child: Text(widget.walletName),
        )),
        body: Center(
            child: SafeArea(
                child: Column(children: <Widget>[
          SizedBox(height: 80),
          Text(
            'Veuillez tapper votre code secret pour en générer un nouveau :',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17.0,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400),
          ),
          SizedBox(height: 30),
          Container(
            child: Stack(
              alignment: Alignment.centerRight,
              children: <Widget>[
                TextField(
                    enabled: true,
                    controller: this._newPin,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(),
                    style: TextStyle(
                        fontSize: 30.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold)),
                IconButton(
                  icon: Icon(Icons.replay),
                  color: Color(0xffD28928),
                  onPressed: () {
                    changePin(widget.walletName, widget.oldPin);
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          SizedBox(
            width: 200,
            height: 50,
            child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  elevation: 12,
                  primary: Colors.green[400], //Color(0xffFFD68E), // background
                  onPrimary: Colors.black, // foreground
                ),
                onPressed: (ischangedPin)
                    ? () => storeWallet(widget.walletName)
                    : null,
                child: Text('Confirmer', style: TextStyle(fontSize: 28))),
          )
        ]))));
  }

  Future<NewWallet> changePin(_name, _oldPin) async {
    try {
      final appPath = await _localPath;
      final _walletFile = Directory('$appPath/wallets/$_name');
      final _dewif =
          File(_walletFile.path + '/wallet.dewif').readAsLinesSync()[0];

      newWalletFile = await DubpRust.changeDewifPin(
        dewif: _dewif,
        oldPin: _oldPin,
      );

      _newPin.text = newWalletFile.pin;
      ischangedPin = true;
      setState(() {});
      return newWalletFile;
    } catch (e) {
      print('Impossible de changer le code PIN.');
      return badWallet;
    }
  }

  Future storeWallet(_name) async {
    final appPath = await _localPath;
    final Directory walletNameDirectory = Directory('$appPath/wallets/$_name');
    final walletFile = File('${walletNameDirectory.path}/wallet.dewif');

    walletFile.writeAsString('${this.newWalletFile.dewif}');

    Navigator.pop(context);

    return _name;
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }
}
