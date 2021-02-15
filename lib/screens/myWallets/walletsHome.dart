import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:gecko/screens/myWallets/generateWallets.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/walletOptions.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class WalletsHome extends StatelessWidget {
  final _derivationKey = GlobalKey<FormState>();

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
                          showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return addNewDerivation(context, 1);
                              });
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
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

    if (!isWalletsExists) {
      return Text('');
    }

    if (_myWalletProvider.listWallets == '') {
      return Expanded(
          child: Center(
              child: Text(
        'Veuillez générer votre premier portefeuille',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      )));
    }

    List _listWallets = _myWalletProvider.listWallets.split('\n');

    return Expanded(
        child: ListView(children: <Widget>[
      SizedBox(height: 8),
      for (String _repository in _listWallets)
        ListTile(
          contentPadding: const EdgeInsets.only(left: 7.0),
          leading: Padding(
              padding: const EdgeInsets.all(6.0),
              child: Text("0 Ğ1", style: TextStyle(fontSize: 14.0))),
          // subtitle: Text(_repository.split(':')[3],
          //     style: TextStyle(fontSize: 12.0, fontFamily: 'Monospace')),
          title:
              Text(_repository.split(':')[1], style: TextStyle(fontSize: 16.0)),
          dense: true,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) {
              return WalletOptions(
                  walletNbr: int.parse(_repository.split(':')[0]),
                  walletName: _repository.split(':')[1],
                  derivation: int.parse(_repository.split(':')[2]));
            }));
          },
        )
    ]));
  }

  Widget addNewDerivation(context, int _walletNbr) {
    final TextEditingController _newDerivationName = TextEditingController();
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    return AlertDialog(
      content: Stack(
        overflow: Overflow.visible,
        children: <Widget>[
          Form(
            key: _derivationKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('Nom du portefeuille:'),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: _newDerivationName,
                    textAlign: TextAlign.center,
                    autofocus: true,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text("Créer"),
                    color: Color(0xffFFD68E),
                    onPressed: () async {
                      await _myWalletProvider
                          .generateNewDerivation(
                              context, _newDerivationName.text, _walletNbr)
                          .then((_) => _newDerivationName.text == '');
                    },
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
