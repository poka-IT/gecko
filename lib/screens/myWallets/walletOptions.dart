import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

// ignore: must_be_immutable
class WalletOptions extends StatelessWidget with ChangeNotifier {
  WalletOptions(
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

    final int _currentChest = _myWalletProvider.getCurrentChest();
    final String shortPubkey =
        _walletOptions.getShortPubkey(_walletOptions.pubkey.text);

    return WillPopScope(
        onWillPop: () {
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
                    child: Expanded(
                      child: Column(children: <Widget>[
                        SizedBox(height: 25),
                        Row(children: <Widget>[
                          SizedBox(width: 25),
                          Image.asset(
                            'assets/chopp-gecko2.png',
                          ),
                          Image.asset(
                            'assets/walletOptions/camera.png',
                          ),
                          // SizedBox(width: 20),
                          Column(children: <Widget>[
                            Row(children: <Widget>[
                              Column(children: <Widget>[
                                SizedBox(
                                    width: 250,
                                    child: Text(
                                      walletName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 27),
                                    )),
                                SizedBox(height: 5),
                                Text(
                                  '500 DU',
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.black),
                                ),
                                SizedBox(height: 5),
                                Image.asset(
                                  'assets/walletOptions/icon_oeuil.png',
                                ),
                              ]),
                              SizedBox(width: 0),
                              Column(children: <Widget>[
                                Image.asset(
                                  'assets/walletOptions/edit.png',
                                ),
                                SizedBox(
                                  height: 60,
                                )
                              ])
                            ]),
                          ]),
                        ]),
                        Image.asset(
                          'assets/walletOptions/QR_icon.png',
                        ),
                        SizedBox(height: 15),
                        Row(children: <Widget>[
                          SizedBox(width: 30),
                          Image.asset(
                            'assets/walletOptions/key.png',
                          ),
                          SizedBox(width: 10),
                          Text("${shortPubkey.split(':')[0]}:",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Monospace',
                                  color: Colors.black)),
                          Text(shortPubkey.split(':')[1],
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Monospace')),
                          SizedBox(width: 15),
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: new BorderRadius.circular(8),
                                ),
                                elevation: 1,
                                primary: Color(0xffD28928), // background
                                onPrimary: Colors.black, // foreground
                              ),
                              onPressed: () {
                                print('COPY PUBKEY');
                              },
                              child: Text('Copier',
                                  style: TextStyle(
                                      fontSize: 15, color: Colors.grey[50]))),
                        ]),
                        SizedBox(height: 10),
                        Row(children: <Widget>[
                          SizedBox(width: 30),
                          Image.asset(
                            'assets/walletOptions/clock.png',
                          ),
                          SizedBox(width: 10),
                          Text('Historique des transactions',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black)),
                        ]),
                        SizedBox(height: 15),
                        Row(children: <Widget>[
                          SizedBox(width: 35),
                          Image.asset(
                            'assets/walletOptions/android-checkmark.png',
                          ),
                          SizedBox(width: 10),
                          Text('Portefeuille par defaut',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.black)),
                        ]),
                        SizedBox(height: 15),
                        Row(children: <Widget>[
                          SizedBox(width: 30),
                          Image.asset(
                            'assets/walletOptions/trash.png',
                          ),
                          SizedBox(width: 10),
                          Text('Supprimer ce portefeuille',
                              style: TextStyle(
                                  fontSize: 20, color: Color(0xffD80000))),
                        ]),
                      ]),
                    ),
                  )),
        ));
  }
}
