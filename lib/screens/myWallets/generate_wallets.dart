import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/generate_wallets.dart';
import 'package:gecko/screens/myWallets/confirm_wallet_storage.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

// ignore: must_be_immutable
class GenerateFastChestScreen extends StatelessWidget {
  SuperTooltip tooltip;
  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  final GlobalKey _toolTipSentence = GlobalKey();
  final GlobalKey _toolTipSecret = GlobalKey();

  GenerateFastChestScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    _generateWalletProvider.genMnemonic();

    return Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const SizedBox(
              height: 22,
              child: Text('Générer un trousseau'),
            )),
        floatingActionButton: SizedBox(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "buttonGenerateWallet",
              onPressed: () => _generateWalletProvider.genMnemonic(),
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
                    TextField(
                        enabled: false,
                        controller: _generateWalletProvider.mnemonicController,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.all(15.0),
                        ),
                        style: const TextStyle(
                            fontSize: 22.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w400)),
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
                            _generateWalletProvider.changePinCode(
                                reload: false);
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
                                            _generateWalletProvider
                                                .generatedMnemonic,
                                        generatedWallet: _generateWalletProvider
                                            .actualWallet);
                                  }),
                                );
                                await Future.delayed(
                                    const Duration(milliseconds: 20));
                                // if (_generateWalletProvider.hasBeenStored) {
                                //   _generateWalletProvider.hasBeenStored = false;
                                //   await Navigator.pushAndRemoveUntil(context,
                                //       MaterialPageRoute(builder: (context) {
                                //     return UnlockingWallet(
                                //       wallet: _myWalletClass.getDefaultWallet(
                                //           configBox.get('currentChest')),
                                //       action: "mywallets",
                                //     );
                                //   }), ModalRoute.withName('/'));
                                // }
                              }
                            : null,
                        child: const Text('Enregistrer ce trousseau',
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
                )));
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
  const PrintWallet(this.sentence, {Key key}) : super(key: key);

  final String sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
            toolbarHeight: 60 * ratio,
            title: const Text('Imprimer ce trousseau')),
        body: PdfPreview(
          build: (format) => _generateWalletProvider.printWallet(sentence),
        ),
      ),
    );
  }
}
