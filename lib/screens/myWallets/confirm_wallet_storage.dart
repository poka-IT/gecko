import 'dart:async';

import 'package:dubp/dubp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_options.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
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

  final TextEditingController _mnemonicController = TextEditingController();
  final TextEditingController _inputRestoreWord = TextEditingController();
  TextEditingController walletName = TextEditingController();
  final FocusNode _wordFocus = FocusNode();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    final int _currentChest = _myWalletProvider.getCurrentChest();

    _mnemonicController.text = generatedMnemonic;
    return WillPopScope(
        onWillPop: () {
          _generateWalletProvider.isAskedWordValid = false;
          _generateWalletProvider.askedWordColor = Colors.black;
          return Future<bool>.value(true);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
              toolbarHeight: 60 * ratio,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _generateWalletProvider.isAskedWordValid = false;
                    _generateWalletProvider.askedWordColor = Colors.black;
                  }),
              title: const SizedBox(
                height: 22,
                child: Text('Enregistrer ce trousseau'),
              )),
          body: Center(
            child: Column(children: <Widget>[
              const SizedBox(height: 15),
              SizedBox(
                  width: 360,
                  child: Text(
                    'Quel est le ${_generateWalletProvider.nbrWord + 1}ème mot de votre phrase de restauration ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400),
                  )),
              TextFormField(
                  key: const Key('askedWord'),
                  focusNode: _wordFocus,
                  autofocus: true,
                  enabled: !_generateWalletProvider.isAskedWordValid,
                  controller: _inputRestoreWord,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _generateWalletProvider.checkAskedWord(
                        value, _mnemonicController.text);
                  },
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(),
                  style: TextStyle(
                      fontSize: 30.0,
                      color: _generateWalletProvider.askedWordColor,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              SizedBox(
                  width: 360,
                  child: Text(
                    'Choisissez un nom pour votre premier portefeuille :',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 17.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400),
                  )),
              TextFormField(
                  key: const Key('walletName'),
                  focusNode: _generateWalletProvider.walletNameFocus,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp('[A-Za-z|0-9|\\-|_| ]')),
                  ],
                  controller: walletName,
                  textInputAction: TextInputAction.next,
                  onChanged: (v) {
                    _generateWalletProvider.nameChanged();
                  },
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(),
                  style: const TextStyle(
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
                            key: const Key('confirmStorage'),
                            style: ElevatedButton.styleFrom(
                              elevation: 12,
                              primary: Colors
                                  .green[400], //smoothYellow, // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: (_generateWalletProvider
                                        .isAskedWordValid &&
                                    walletName.text != '')
                                ? () {
                                    _generateWalletProvider.storeHDWChest(
                                        generatedWallet,
                                        walletName.text,
                                        context);
                                    _generateWalletProvider.isAskedWordValid =
                                        false;
                                    _generateWalletProvider.askedWordColor =
                                        Colors.black;
                                    _myWalletProvider.listWallets =
                                        _myWalletProvider
                                            .readAllWallets(_currentChest);
                                    scheduleMicrotask(() {
                                      _walletOptions.reloadBuild();
                                      _myWalletProvider.rebuildWidget();
                                    });
                                    Navigator.pushAndRemoveUntil(context,
                                        MaterialPageRoute(builder: (context) {
                                      return UnlockingWallet(
                                        wallet:
                                            _myWalletProvider.getDefaultWallet(
                                                configBox.get('currentChest')),
                                        action: "mywallets",
                                      );
                                    }), ModalRoute.withName('/'));
                                  }
                                : null,
                            child: const Text('Confirmer',
                                style: TextStyle(fontSize: 28))),
                      ))),
              const SizedBox(height: 70),
              Text('TRICHE PENDANT ALPHA: ' + _mnemonicController.text,
                  style: const TextStyle(
                      fontSize: 10.0,
                      color: Colors.black,
                      fontWeight: FontWeight.normal)),
            ]),
          ),
        ));
  }
}
