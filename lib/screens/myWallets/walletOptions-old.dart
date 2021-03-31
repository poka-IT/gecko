import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class WalletOptionsOld extends StatelessWidget with ChangeNotifier {
  WalletOptionsOld(
      {Key keyMyWallets,
      @required this.walletNbr,
      @required this.walletName,
      @required this.derivation})
      : super(key: keyMyWallets);
  int walletNbr;
  String walletName;
  int derivation;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    print("Build walletOptions");
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    // _walletOptions.isWalletUnlock = false;
    print("Is unlock ? ${_walletOptions.isWalletUnlock}");

    final int _currentChest = _myWalletProvider.getCurrentChest();

    return WillPopScope(
        onWillPop: () {
          _walletOptions.isWalletUnlock = false;
          Navigator.popUntil(
            context,
            ModalRoute.withName('/mywallets'),
          );
          return Future<bool>.value(true);
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    _walletOptions.isWalletUnlock = false;
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/mywallets'),
                    );
                  }),
              title: SizedBox(
                height: 22,
                child: Text(walletName),
              )),
          body: Builder(
              builder: (ctx) => SafeArea(
                    child: Column(children: <Widget>[
                      Expanded(
                          child: Column(children: <Widget>[
                        SizedBox(height: 15),
                        Text(
                          'Clé publique:',
                          style: TextStyle(
                              fontSize: 15.0,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400),
                        ),
                        SizedBox(height: 15),
                        GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: _walletOptions.pubkey.text));
                              _walletOptions.snackCopyKey(ctx);
                            },
                            child: Text(
                              _walletOptions.pubkey.text,
                              style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Monospace'),
                            )),
                        Expanded(
                            child: Align(
                                alignment: Alignment.bottomCenter,
                                child: SizedBox(
                                    height: 50,
                                    width: 300,
                                    child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          elevation: 5,
                                          primary: Color(
                                              0xffFFD68E), //Color(0xffFFD68E), // background
                                          onPrimary: Colors.black, // foreground
                                        ),
                                        onPressed: () => _walletOptions
                                                .renameWalletAlerte(
                                                    context,
                                                    walletName,
                                                    walletNbr,
                                                    derivation)
                                                .then((_result) {
                                              if (_result == true) {
                                                WidgetsBinding.instance
                                                    .addPostFrameCallback((_) {
                                                  _myWalletProvider
                                                          .listWallets =
                                                      _myWalletProvider
                                                          .readAllWallets(
                                                              _currentChest);
                                                  _myWalletProvider
                                                      .rebuildWidget();
                                                });
                                                Navigator.popUntil(
                                                  context,
                                                  ModalRoute.withName(
                                                      '/mywallets'),
                                                );
                                              }
                                            }),
                                        child: Text('Renommer ce portefeuille',
                                            style: TextStyle(fontSize: 20)))))),
                        SizedBox(height: 30),
                        SizedBox(
                            height: 50,
                            width: 300,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  elevation: 6,
                                  primary: Colors
                                      .redAccent, //Color(0xffFFD68E), // background
                                  onPrimary: Colors.black, // foreground
                                ),
                                onPressed: () async {
                                  await _walletOptions.deleteWallet(
                                      context,
                                      _myWalletProvider.getWalletData(
                                          _walletOptions.walletID));
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _myWalletProvider.listWallets =
                                        _myWalletProvider
                                            .readAllWallets(_currentChest);
                                    _myWalletProvider.rebuildWidget();
                                  });
                                },
                                child: Text('Supprimer ce portefeuille',
                                    style: TextStyle(fontSize: 20)))),
                        SizedBox(height: 50),
                        Text(
                          'Portefeuille déverrouillé',
                          style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w700,
                              fontSize: 15),
                        ),
                        SizedBox(height: 10)
                      ])),
                    ]),
                  )),
        ));
  }
}
