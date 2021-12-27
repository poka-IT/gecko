import 'dart:async';
import 'package:durt/durt.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:provider/provider.dart';

class ImportWalletScreen extends StatelessWidget {
  const ImportWalletScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GlobalKey _toolTipSecret = GlobalKey();
    Timer? _debounce;
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    _generateWalletProvider.pin.text = randomSecretCode(pinLength);
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
              Consumer<GenerateWalletsProvider>(
                  builder: (context, walletProvider, _) {
                return TextFormField(
                  autofocus: true,
                  onChanged: (text) {
                    if (_debounce?.isActive ?? false) {
                      _debounce!.cancel();
                    }
                    _debounce = Timer(const Duration(milliseconds: 600), () {
                      walletProvider
                          .generateCesiumWalletPubkey(
                              text, walletProvider.cesiumPWD.text)
                          .then((value) {
                        walletProvider.canImport = true;
                        walletProvider.reloadBuild();
                      });
                    });
                  },
                  keyboardType: TextInputType.text,
                  controller: walletProvider.cesiumID,
                  obscureText: !walletProvider
                      .isCesiumIDVisible, //This will obscure text dynamically
                  decoration: InputDecoration(
                    hintText: 'Entrez votre identifiant Cesium',
                    suffixIcon: IconButton(
                      icon: Icon(
                        walletProvider.isCesiumIDVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        walletProvider.cesiumIDisVisible();
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              Consumer<GenerateWalletsProvider>(
                  builder: (context, walletProvider, _) {
                return TextFormField(
                  onChanged: (text) {
                    if (_debounce?.isActive ?? false) {
                      _debounce!.cancel();
                    }
                    _debounce = Timer(const Duration(milliseconds: 600), () {
                      walletProvider
                          .generateCesiumWalletPubkey(
                              walletProvider.cesiumID.text, text)
                          .then((value) {
                        walletProvider.canImport = true;
                        walletProvider.reloadBuild();
                      });
                    });
                  },
                  keyboardType: TextInputType.text,
                  controller: walletProvider.cesiumPWD,
                  obscureText: !walletProvider
                      .isCesiumPWDVisible, //This will obscure text dynamically
                  decoration: InputDecoration(
                    hintText: 'Entrez votre mot de passe Cesium',
                    suffixIcon: IconButton(
                      icon: Icon(
                        walletProvider.isCesiumPWDVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.black,
                      ),
                      onPressed: () {
                        walletProvider.cesiumPWDisVisible();
                      },
                    ),
                  ),
                );
              }),
              const SizedBox(height: 15),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: _generateWalletProvider.cesiumPubkey.text));
                  _walletOptions.snackCopyKey(ctx);
                },
                child: Consumer<GenerateWalletsProvider>(
                    builder: (context, walletProvider, _) {
                  return Text(
                    _generateWalletProvider.cesiumPubkey.text,
                    style: const TextStyle(
                        fontSize: 14.0,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Monospace'),
                  );
                }),
              ),
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
                      _generateWalletProvider.changePinCode(reload: true);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Consumer<GenerateWalletsProvider>(
                  builder: (context, walletProvider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    primary: yellowC, // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: walletProvider.canImport
                      ? () async {
                          final chestKey =
                              await walletProvider.importCesiumWallet();
                          _myWalletProvider.rebuildWidget();

                          await Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return UnlockingWallet(
                                wallet: WalletData(chest: chestKey),
                                action: "mywallets",
                              );
                            }),
                            ModalRoute.withName('/'),
                          );
                          _generateWalletProvider.resetCesiumImportView();
                        }
                      : null,
                  child: const Text(
                    'Importer ce portefeuille Cesium',
                    style: TextStyle(fontSize: 20),
                  ),
                );
              }),
            ]),
          ),
        ),
      ),
    );
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
