import 'dart:async';
import 'package:gecko/models/generateWallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:provider/provider.dart';

class ImportWalletScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    GlobalKey _toolTipSecret = GlobalKey();
    Timer _debounce;
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    return WillPopScope(
        onWillPop: () {
          _generateWalletProvider.cesiumID.text = '';
          _generateWalletProvider.cesiumPWD.text = '';
          _generateWalletProvider.cesiumPubkey.text = '';
          _generateWalletProvider.pin.text = '';
          _generateWalletProvider.canImport = false;
          _generateWalletProvider.isPinChanged = false;
          return Future<bool>.value(true);
        },
        child: Scaffold(
            appBar: AppBar(
                leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () {
                      _generateWalletProvider.cesiumID.text = '';
                      _generateWalletProvider.cesiumPWD.text = '';
                      _generateWalletProvider.cesiumPubkey.text = '';
                      _generateWalletProvider.pin.text = '';
                      _generateWalletProvider.canImport = false;
                      _generateWalletProvider.isPinChanged = false;
                      Navigator.of(context).pop();
                    }),
                title: SizedBox(
                  height: 22,
                  child: Text('Importer un portefeuille'),
                )),
            body: Builder(
                builder: (ctx) => SafeArea(
                      child: Column(children: <Widget>[
                        SizedBox(height: 20),
                        TextFormField(
                          onChanged: (text) {
                            if (_debounce?.isActive ?? false)
                              //   _generateWalletProvider.canImport = false;
                              // _generateWalletProvider.reloadBuild();
                              _debounce.cancel();
                            _debounce =
                                Timer(const Duration(milliseconds: 200), () {
                              print("ID Cesium tappé: $text");
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
                        SizedBox(height: 15),
                        TextFormField(
                          onChanged: (text) {
                            if (_debounce?.isActive ?? false)
                              //   _generateWalletProvider.canImport = false;
                              // _generateWalletProvider.reloadBuild();
                              _debounce.cancel();
                            _debounce =
                                Timer(const Duration(milliseconds: 200), () {
                              print("ID Cesium tappé: $text");
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
                        SizedBox(height: 15),
                        Text(
                          _generateWalletProvider.cesiumPubkey.text,
                          style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Monospace'),
                        ),
                        SizedBox(height: 20),
                        toolTips(_toolTipSecret, 'Code secret:',
                            "Retenez bien votre code secret, il vous sera demandé à chaque paiement, ainsi que pour configurer votre portefeuille"),
                        Container(
                          child: Stack(
                            alignment: Alignment.centerRight,
                            children: <Widget>[
                              TextField(
                                  enabled: false,
                                  controller: _generateWalletProvider.pin,
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
                                  _generateWalletProvider.changePinCode();
                                  _generateWalletProvider.isPinChanged = true;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Color(0xffFFD68E), // background
                              onPrimary: Colors.black, // foreground
                            ),
                            onPressed: _generateWalletProvider.canImport &&
                                    _generateWalletProvider.isPinChanged
                                ? () {
                                    _generateWalletProvider
                                        .importWallet(
                                            context,
                                            _generateWalletProvider
                                                .cesiumID.text,
                                            _generateWalletProvider
                                                .cesiumPWD.text)
                                        .then((value) {
                                      _myWalletProvider.rebuildWidget();
                                    });
                                  }
                                : null,
                            child: Text('Importer ce portefeuille Cesium',
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
            padding: EdgeInsets.all(10),
            key: _key,
            showDuration: Duration(seconds: 5),
            message: _message,
            child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  SizedBox(width: 20),
                  Column(children: <Widget>[
                    SizedBox(
                        width: 30,
                        height: 25,
                        child: Icon(Icons.info_outline,
                            size: 22, color: Color(0xffD28928))),
                    SizedBox(height: 1)
                  ]),
                  Text(
                    _text,
                    style: TextStyle(
                        fontSize: 15.0,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400),
                  ),
                  SizedBox(width: 45)
                ])));
  }
}
