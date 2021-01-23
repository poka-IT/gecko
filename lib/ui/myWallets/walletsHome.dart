import 'package:gecko/models/myWallets.dart';
import 'package:gecko/ui/myWallets/generateWalletsScreen.dart';
import 'package:gecko/ui/myWallets/myWalletsList.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dubp/dubp.dart';

class WalletsHome extends StatelessWidget with ChangeNotifier {
  MyWalletsProvider historyProvider = MyWalletsProvider();

  String generatedMnemonic;
  bool walletIsGenerated = false;
  NewWallet actualWallet;
  String newWalletName;

  bool hasError = false;
  String validPin = 'NO PIN';
  String currentText = "";
  var pinColor = Colors.grey[300];

  @override
  Widget build(BuildContext context) {
    historyProvider.getAppDirectory();
    return Scaffold(
        floatingActionButton: Visibility(
            visible: (historyProvider
                .checkIfWalletExist()), //!checkIfWalletExist('MonWallet') &&
            child: Container(
                height: 80.0,
                width: 80.0,
                child: FittedBox(
                    child: FloatingActionButton(
                        heroTag: "buttonGenerateWallet",
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              return GenerateWalletsScreen();
                            }),
                          );
                        },
                        child: Container(
                            height: 40.0,
                            width: 40.0,
                            child: Icon(Icons.person_add_alt_1_rounded,
                                color: Colors.grey[850])),
                        backgroundColor: Color(0xffEFEFBF))))),
        body: SafeArea(
            child: Column(children: <Widget>[
          Visibility(
              visible:
                  (!historyProvider.checkIfWalletExist() && !walletIsGenerated),
              child: Column(children: <Widget>[
                SizedBox(height: 120),
                Center(
                    child: Text("Vous n'avez encore généré aucun portefeuille.",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)),
                SizedBox(height: 80),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xffFFD68E), // background
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) {
                            return GenerateWalletsScreen();
                          }),
                        ),
                    child: Text('Générer un portefeuille',
                        style: TextStyle(fontSize: 20))),
                SizedBox(height: 15),
                Center(
                    child: Text("ou",
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center)),
                SizedBox(height: 15),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      primary: Color(0xffFFD68E), // background
                      onPrimary: Colors.black, // foreground
                    ),
                    onPressed: () => historyProvider.importWallet(),
                    child: Text('Importer un portefeuille existant',
                        style: TextStyle(fontSize: 20))),
              ])),
          Visibility(
              visible: historyProvider.checkIfWalletExist(),
              child: MyWalletsList())
        ])));
  }

  // Future resetWalletState() async {
  //   final bool _isExist = await checkIfWalletExist('MonWallet');
  //   print('The wallet exist in resetWalletState(): ' + _isExist.toString());
  //   // initState();
  //   // _keyMyWallets.currentState.setState(() {});
  //   // _keyMyWallets.currentState.initAppDirectory();
  //   setState(() {
  //     // getAllWalletsNames();
  //     // this.walletIsGenerated = true;
  //   });
  // }

}
