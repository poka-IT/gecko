import 'package:flutter/services.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/myWallets/unlockingWallet.dart';
import 'package:gecko/screens/onBoarding/1_noKeychainFound.dart';
import 'package:provider/provider.dart';

// ignore: must_be_immutable
class WalletsHome extends StatelessWidget {
  final _derivationKey = GlobalKey<FormState>();
  int firstWalletDerivation;

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);
    _walletOptions.isWalletUnlock = false;
    myWalletProvider.listWallets = myWalletProvider.getAllWalletsNames();
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

    if (myWalletProvider.listWallets != '') {
      firstWalletDerivation =
          int.parse(myWalletProvider.listWallets.split('\n')[0].split(':')[2]);
    }

    return Scaffold(
        appBar: AppBar(
          title: Text('Mes portefeuilles',
              style: TextStyle(color: Colors.grey[850])),
          backgroundColor: Color(0xffFFD58D),
        ),
        floatingActionButton: Visibility(
            visible: (isWalletsExists && firstWalletDerivation != -1),
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
                            height: 40,
                            width: 40,
                            child: Icon(Icons.person_add_alt_1_rounded,
                                color: Colors.grey[850])),
                        backgroundColor: Color(0xffEFEFBF))))),
        body: SafeArea(
            child: !isWalletsExists
                ? NoKeyChainScreen()
                : myWalletsList(context)));
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
              return UnlockingWallet(
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
