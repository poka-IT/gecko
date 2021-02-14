import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:gecko/screens/myWallets/generateWallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/walletOptions.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class WalletsHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    _walletOptions.isWalletUnlock = false;
    myWalletProvider.listWallets = myWalletProvider.getAllWalletsNames();
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

    return Scaffold(
        floatingActionButton: Visibility(
            visible: (isWalletsExists),
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
              visible: (!isWalletsExists),
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
                    child: Text('Générer un trousseau',
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
                    onPressed: () => myWalletProvider.importWallet(),
                    child: Text('Importer un portefeuille existant',
                        style: TextStyle(fontSize: 20))),
              ])),
          Visibility(visible: isWalletsExists, child: myWalletsList(context))
        ])));
  }

  Widget myWalletsList(BuildContext context) {
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    List _listWallets = [];
    myWalletProvider.listWallets.forEach((_name, _pubkey) {
      _listWallets.add(_name);
    });

    return Column(children: <Widget>[
      SizedBox(height: 8),
      for (String _repository in _listWallets)
        ListTile(
          contentPadding: const EdgeInsets.all(5.0),
          leading: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Text("0 Ğ1", style: TextStyle(fontSize: 14.0))),
          title: Text(_repository, style: TextStyle(fontSize: 16.0)),
          subtitle: Text(myWalletProvider.listWallets[_repository],
              style: TextStyle(fontSize: 11.0)),
          dense: true,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return WalletOptions(walletName: _repository);
            }));
          },
        )
    ]);
  }
}
