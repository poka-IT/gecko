import 'dart:async';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_options.dart';
import 'package:provider/provider.dart';

class ImportWalletScreen extends StatelessWidget {
  const ImportWalletScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GlobalKey _toolTipSecret = GlobalKey();
    Timer _debounce;
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);

    return WillPopScope(
        onWillPop: () {
          _generateWalletProvider.resetCesiumImportView();
          return Future<bool>.value(true);
        },
        child: Scaffold(
            appBar: AppBar(
                toolbarHeight: 60 * ratio,
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      _generateWalletProvider.resetCesiumImportView();
                      Navigator.of(context).pop();
                    }),
                title: const SizedBox(
                  height: 22,
                  child: Text('Importer un portefeuille'),
                )),
            body: Builder(
                builder: (ctx) => SafeArea(
                      child: Column(children: <Widget>[
                        const SizedBox(height: 20),
                        TextFormField(
                          onChanged: (text) {
                            if (_debounce?.isActive ?? false) {
                              _debounce.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 200), () {
                              _generateWalletProvider
                                  .generateCesiumWalletPubkey(text,
                                      _generateWalletProvider.cesiumPWD.text)
                                  .then((value) {
                                _generateWalletProvider.canImport = true;
                                _generateWalletProvider.reloadBuild();
                              });
                            });
                          },
                          keyboardType: TextInputType.text,
                          controller: _generateWalletProvider.cesiumID,
                          obscureText: !_generateWalletProvider
                              .isCesiumIDVisible, //This will obscure text dynamically
                          decoration: InputDecoration(
                            hintText: 'Entrez votre identifiant Cesium',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _generateWalletProvider.isCesiumIDVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                _generateWalletProvider.cesiumIDisVisible();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          onChanged: (text) {
                            if (_debounce?.isActive ?? false) {
                              _debounce.cancel();
                            }
                            _debounce =
                                Timer(const Duration(milliseconds: 200), () {
                              _generateWalletProvider
                                  .generateCesiumWalletPubkey(
                                      _generateWalletProvider.cesiumID.text,
                                      text)
                                  .then((value) {
                                _generateWalletProvider.canImport = true;
                                _generateWalletProvider.reloadBuild();
                              });
                            });
                          },
                          keyboardType: TextInputType.text,
                          controller: _generateWalletProvider.cesiumPWD,
                          obscureText: !_generateWalletProvider
                              .isCesiumPWDVisible, //This will obscure text dynamically
                          decoration: InputDecoration(
                            hintText: 'Entrez votre mot de passe Cesium',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _generateWalletProvider.isCesiumPWDVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.black,
                              ),
                              onPressed: () {
                                _generateWalletProvider.cesiumPWDisVisible();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                  text: _generateWalletProvider
                                      .cesiumPubkey.text));
                              _walletOptions.snackCopyKey(ctx);
                            },
                            child: Text(
                              _generateWalletProvider.cesiumPubkey.text,
                              style: const TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Monospace'),
                            )),
                        const SizedBox(height: 20),
                        toolTips(_toolTipSecret, 'Code secret:',
                            "Retenez bien votre code secret, il vous sera demandé à chaque paiement, ainsi que pour configurer votre portefeuille"),
                        Stack(
                          alignment: Alignment.centerRight,
                          children: <Widget>[
                            TextField(
                                enabled: false,
                                controller: _generateWalletProvider.pin,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(),
                                style: const TextStyle(
                                    fontSize: 30.0,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold)),
                            IconButton(
                              icon: const Icon(Icons.replay),
                              color: orangeC,
                              onPressed: () {
                                _generateWalletProvider.changePinCode(
                                    reload: true);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: yellowC, // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: _generateWalletProvider.canImport
                                ? () {
                                    _generateWalletProvider
                                        .importCesiumWallet()
                                        .then((value) {
                                      _myWalletProvider.rebuildWidget();
                                      _generateWalletProvider
                                          .resetCesiumImportView();
                                      Navigator.popUntil(
                                        context,
                                        ModalRoute.withName('/'),
                                      );
                                    });
                                  }
                                : null,
                            child: const Text('Importer ce portefeuille Cesium',
                                style: TextStyle(fontSize: 20))),
                      ]),
                    ))));
  }

  Widget toolTips(_key, _text, _message) {
    return GestureDetector(
        onTap: () {
          final dynamic _toolTip = _key.currentState;
          _toolTip.ensureTooltipVisible();
        },
        child: Tooltip(
            padding: const EdgeInsets.all(10),
            key: _key,
            showDuration: const Duration(seconds: 5),
            message: _message,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const SizedBox(width: 20),
                  Column(children: <Widget>[
                    SizedBox(
                        width: 30,
                        height: 25,
                        child:
                            Icon(Icons.info_outline, size: 22, color: orangeC)),
                    const SizedBox(height: 1)
                  ]),
                  Text(
                    _text,
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400),
                  ),
                  const SizedBox(width: 45)
                ])));
  }
}
