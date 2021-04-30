import 'package:flutter/services.dart';
import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/myWallets/confirmWalletStorage.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

// ignore: must_be_immutable
class GenerateWalletsScreen extends StatelessWidget {
  SuperTooltip tooltip;
  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  GlobalKey _toolTipSentence = GlobalKey();
  GlobalKey _toolTipSecret = GlobalKey();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    _generateWalletProvider.generateMnemonic();

    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Générer un trousseau'),
        )),
        floatingActionButton: Container(
            height: 80.0,
            width: 80.0,
            child: FittedBox(
                child: FloatingActionButton(
              heroTag: "buttonGenerateWallet",
              onPressed: () => _generateWalletProvider.generateMnemonic(),
              child: Container(
                height: 40.0,
                width: 40.0,
                child: Icon(Icons.replay, color: Colors.grey[850]),
              ),
              backgroundColor: Color(
                  0xffEFEFBF), //Color(0xffFFD68E), //Color.fromARGB(500, 204, 255, 255),
            ))),
        body: Builder(
            builder: (ctx) => SafeArea(
                  child: Column(children: <Widget>[
                    SizedBox(height: 20),
                    toolTips(_toolTipSentence, 'Phrase de restauration:',
                        "Notez et gardez cette phrase précieusement sur un papier, elle vous servira à restaurer votre portefeuille sur un autre appareil"),
                    TextField(
                        enabled: false,
                        controller: _generateWalletProvider.mnemonicController,
                        maxLines: 3,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.all(15.0),
                        ),
                        style: TextStyle(
                            fontSize: 22.0,
                            color: Colors.black,
                            fontWeight: FontWeight.w400)),
                    SizedBox(height: 8),
                    toolTips(_toolTipSecret, 'Code secret:',
                        "Retenez bien votre code secret, il vous sera demandé à chaque paiement, ainsi que pour configurer votre portefeuille"),
                    Container(
                      child: Stack(
                        alignment: Alignment.centerRight,
                        children: <Widget>[
                          TextField(
                              key: Key('generatedPin'),
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
                              _generateWalletProvider.changePinCode(
                                  reload: false);
                            },
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                        key: Key('storeKeychain'),
                        style: ElevatedButton.styleFrom(
                          primary: Color(0xffFFD68E), // background
                          onPrimary: Colors.black, // foreground
                        ),
                        onPressed: _generateWalletProvider.walletIsGenerated
                            ? () {
                                _generateWalletProvider.nbrWord =
                                    _generateWalletProvider.getRandomInt();
                                Navigator.push(
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
                              }
                            : null,
                        child: Text('Enregistrer ce trousseau',
                            style: TextStyle(fontSize: 20))),
                    SizedBox(height: 20),
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
                        child: Icon(Icons.print))
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

// ignore: must_be_immutable
class PrintWallet extends StatelessWidget {
  PrintWallet(this.sentence);

  final String sentence;

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Imprimer ce trousseau')),
        body: PdfPreview(
          build: (format) => _generateWalletProvider.printWallet(sentence),
        ),
      ),
    );
  }
}
