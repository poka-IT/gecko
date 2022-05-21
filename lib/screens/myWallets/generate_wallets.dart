import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/screens/myWallets/confirm_wallet_storage.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class GenerateFastChestScreen extends StatelessWidget {
  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  final GlobalKey _toolTipSentence = GlobalKey();
  final GlobalKey _toolTipSecret = GlobalKey();

  GenerateFastChestScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context, listen: false);

    _generateWalletProvider.pin.text = kDebugMode && debugPin
        ? 'AAAAA'
        : _generateWalletProvider.changePinCode(reload: false);

    return WillPopScope(
      onWillPop: () {
        _generateWalletProvider.pin.text = '';
        _generateWalletProvider.mnemonicController.text = '';
        return Future<bool>.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  _generateWalletProvider.pin.text = '';
                  _generateWalletProvider.mnemonicController.text = '';
                  Navigator.of(context).pop();
                }),
            title: const SizedBox(
              height: 22,
              child: Text('Générer un coffre'),
            )),
        floatingActionButton: SizedBox(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "buttonGenerateWallet",
              onPressed: () {
                _generateWalletProvider.reloadBuild();
              },
              child: SizedBox(
                height: 40.0,
                width: 40.0,
                child: Icon(Icons.replay, color: Colors.grey[850]),
              ),
              backgroundColor:
                  floattingYellow, //smoothYellow, //Color.fromARGB(500, 204, 255, 255),
            ))),
        body: Builder(
          builder: (ctx) => SafeArea(
            child: Column(children: <Widget>[
              const SizedBox(height: 20),
              toolTips(_toolTipSentence, 'Phrase de restauration:',
                  "Notez et gardez cette phrase précieusement sur un papier, elle vous servira à restaurer votre portefeuille sur un autre appareil"),
              Consumer<GenerateWalletsProvider>(builder: (context, _gWP, _) {
                return FutureBuilder(
                    future: _gWP.generateWordList(context),
                    builder: (BuildContext context, AsyncSnapshot<List> _data) {
                      if (!_data.hasData) {
                        return const Text('');
                      } else {
                        return Text(_gWP.generatedMnemonic!,
                            maxLines: 3,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22.0,
                                color: Colors.black,
                                fontWeight: FontWeight.w400));
                      }
                    });
              }),
              const SizedBox(height: 8),
              toolTips(_toolTipSecret, 'Code secret:',
                  "Retenez bien votre code secret, il vous sera demandé à chaque paiement, ainsi que pour configurer votre portefeuille"),
              Stack(
                alignment: Alignment.centerRight,
                children: <Widget>[
                  TextField(
                      key: const Key('generatedPin'),
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
                      _generateWalletProvider.changePinCode(reload: false);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  key: const Key('storeKeychain'),
                  style: ElevatedButton.styleFrom(
                    primary: yellowC, // background
                    onPrimary: Colors.black, // foreground
                  ),
                  onPressed: _generateWalletProvider.walletIsGenerated
                      ? () async {
                          _generateWalletProvider.nbrWord =
                              _generateWalletProvider.getRandomInt();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return ConfirmStoreWallet(
                                  generatedMnemonic:
                                      _generateWalletProvider.generatedMnemonic,
                                  generatedWallet:
                                      _generateWalletProvider.actualWallet);
                            }),
                          );
                        }
                      : null,
                  child: const Text('Enregistrer ce coffre',
                      style: TextStyle(fontSize: 20))),
              const SizedBox(height: 20),
              GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) {
                        return PrintWallet(
                            _generateWalletProvider.generatedMnemonic);
                      }),
                    );
                  },
                  child: const Icon(Icons.print))
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

// ignore: must_be_immutable
class PrintWallet extends StatelessWidget {
  const PrintWallet(this.sentence, {Key? key}) : super(key: key);

  final String? sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                }),
            toolbarHeight: 60 * ratio,
            title: const Text('Imprimer ce coffre')),
        body: PdfPreview(
          build: (format) => _generateWalletProvider.printWallet(sentence),
        ),
      ),
    );
  }
}
