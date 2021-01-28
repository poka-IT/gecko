import 'package:gecko/models/generateWallets.dart';
import 'package:gecko/screens/myWallets/confirmWalletStorage.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:super_tooltip/super_tooltip.dart';

// ignore: must_be_immutable
class GenerateWalletsScreen extends StatelessWidget {
  SuperTooltip tooltip;
  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  @override
  Widget build(BuildContext context) {
    GenerateWalletsProvider _generateWalletProvider =
        Provider.of<GenerateWalletsProvider>(context);
    _generateWalletProvider.generateMnemonic();
    print('IS GENERATED ? : ' +
        _generateWalletProvider.walletIsGenerated.toString());
    return Scaffold(
        appBar: AppBar(
            title: SizedBox(
          height: 22,
          child: Text('Générer un portefeuille'),
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
        body: SafeArea(
          child: Column(children: <Widget>[
            SizedBox(height: 20),
            Tooltip(
              message:
                  "C'est votre RIB en Ğ1, les gens l'utiliseront pour vous payer",
              child: Text(
                'Clé publique:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
            ),
            TextField(
                enabled: false,
                controller: _generateWalletProvider.pubkey,
                maxLines: 1,
                textAlign: TextAlign.center,
                decoration: InputDecoration(),
                style: TextStyle(
                    fontSize: 14.0,
                    color: Colors.black,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Tooltip(
              message:
                  "Notez et gardez cette phrase précieusement sur un papier, elle vous servira à restaurer votre portefeuille sur un autre appareil",
              child: Text(
                'Phrase de restauration:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
            ),
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
            Tooltip(
              message:
                  "Retenez bien votre code secret, il vous sera demandé à chaque paiement, ainsi que pour configurer votre portefeuille",
              child: Text(
                'Code secret:',
                style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
            ),
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
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            new ElevatedButton(
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
                                    _generateWalletProvider.generatedMnemonic,
                                generatedWallet:
                                    _generateWalletProvider.actualWallet);
                          }),
                        );
                      }
                    : null,
                child: Text('Enregistrer ce portefeuille',
                    style: TextStyle(fontSize: 20))),
            SizedBox(height: 20)
          ]),
        ));
  }
}
