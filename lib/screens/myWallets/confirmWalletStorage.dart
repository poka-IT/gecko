import 'package:dubp/dubp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class ConfirmStoreWallet extends StatelessWidget with ChangeNotifier {
  ConfirmStoreWallet({
    Key validationKey,
    @required this.generatedMnemonic,
    @required this.generatedWallet,
  }) : super(key: validationKey);

  String generatedMnemonic;
  NewWallet generatedWallet;

  TextEditingController _mnemonicController = TextEditingController();
  TextEditingController _pubkey = TextEditingController();
  TextEditingController _inputRestoreWord = TextEditingController();
  TextEditingController walletName = TextEditingController();
  FocusNode _wordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    print("JE BUILD !!!");

    this._mnemonicController.text = generatedMnemonic;
    this._pubkey.text = generatedWallet.publicKey;
    return WillPopScope(
        onWillPop: () {
          _generateWalletProvider.isAskedWordValid = false;
          _generateWalletProvider.askedWordColor = Colors.black;
          return Future<bool>.value(true);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generateWalletProvider.isAskedWordValid = false;
                    _generateWalletProvider.askedWordColor = Colors.black;
                  }),
              title: SizedBox(
                height: 22,
                child: Text('Confirmez ce portefeuille'),
              )),
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
                'Quel est le ${_generateWalletProvider.nbrWord + 1}ème mot de votre phrase de restauration ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 17.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
              TextFormField(
                  focusNode: _wordFocus,
                  autofocus: true,
                  enabled: !_generateWalletProvider.isAskedWordValid,
                  controller: this._inputRestoreWord,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _generateWalletProvider.checkAskedWord(
                        value, _mnemonicController.text);
                  },
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(),
                  style: TextStyle(
                      fontSize: 30.0,
                      color: _generateWalletProvider.askedWordColor,
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
              TextFormField(
                  focusNode: _generateWalletProvider.walletNameFocus,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp('[A-Za-z|0-9|\\-|_| ]')),
                  ],
                  controller: this.walletName,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    _generateWalletProvider.nameChanged();
                  },
                  maxLines: 1,
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
                              primary: Colors.green[
                                  400], //Color(0xffFFD68E), // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: (_generateWalletProvider
                                        .isAskedWordValid &&
                                    this.walletName.text != '')
                                ? () {
                                    _generateWalletProvider.storeWallet(
                                        generatedWallet,
                                        walletName.text,
                                        context);
                                    _generateWalletProvider.isAskedWordValid =
                                        false;
                                    _generateWalletProvider.askedWordColor =
                                        Colors.black;
                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      _myWalletProvider.listWallets =
                                          _myWalletProvider
                                              .getAllWalletsNames();
                                      _myWalletProvider.rebuildWidget();
                                    });
                                  }
                                : null,
                            child: Text('Confirmer',
                                style: TextStyle(fontSize: 28))),
                      ))),
              SizedBox(height: 70),
              Text('TRICHE PENDANT ALPHA: ' + this._mnemonicController.text,
                  style: TextStyle(
                      fontSize: 10.0,
                      color: Colors.black,
                      fontWeight: FontWeight.normal)),
            ]),
          ),
        ));
  }
}
