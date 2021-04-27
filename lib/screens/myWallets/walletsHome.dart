import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/myWallets/walletOptions.dart';
import 'package:gecko/screens/onBoarding/0_noKeychainFound.dart';
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

    final int _currentChest = myWalletProvider.getCurrentChest();

    myWalletProvider.listWallets =
        myWalletProvider.readAllWallets(_currentChest);
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

    if (myWalletProvider.listWallets.isEmpty) {
      firstWalletDerivation = myWalletProvider.listWallets[0].derivation;

      myWalletProvider.getDefaultWallet();
    }

    log.d("${myWalletProvider.pinCode},${myWalletProvider.pinLenght}");

    return WillPopScope(
        onWillPop: () {
          Navigator.popUntil(
            context,
            ModalRoute.withName('/'),
          );
          return Future<bool>.value(true);
        },
        child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/'),
                    );
                  }),
              title: Text('Mes portefeuilles',
                  key: Key('myWallets'),
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
                    : myWalletsTiles(context))));
  }

  Widget myWalletsTiles(BuildContext context) {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    WalletOptionsProvider _walletOptions =
        Provider.of<WalletOptionsProvider>(context);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

    if (!isWalletsExists) {
      return Text('');
    }

    if (_myWalletProvider.listWallets.isEmpty) {
      return Expanded(
          child: Column(children: <Widget>[
        Center(
            child: Text(
          'Veuillez générer votre premier portefeuille',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
        )),
      ]));
    }

    List _listWallets = _myWalletProvider.listWallets;

    return GridView.count(
        crossAxisCount: 2,
        childAspectRatio: 1,
        crossAxisSpacing: 0,
        mainAxisSpacing: 0,
        children: <Widget>[
          for (WalletData _repository in _listWallets)
            Padding(
                padding: EdgeInsets.all(16),
                child: GestureDetector(
                    onTap: () async {
                      await _walletOptions.readLocalWallet(
                          context,
                          _repository,
                          _myWalletProvider.pinCode,
                          _myWalletProvider.pinLenght);
                      Navigator.push(
                          context,
                          SmoothTransition(
                              page: WalletOptions(
                            wallet: _repository,
                          )));

                      // Navigator.push(context,
                      //     MaterialPageRoute(builder: (context) {
                      //   return UnlockingWallet(wallet: _repository);
                      // }));
                    },
                    child: ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        child: Column(children: <Widget>[
                          Expanded(
                              child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                                gradient: RadialGradient(
                              radius: 1,
                              colors: [
                                Colors.green[100],
                                Colors.green[500],
                              ],
                            )),
                            child:
                                // SvgPicture.asset('assets/chopp-gecko2.png',
                                //         semanticsLabel: 'Gecko', height: 48),
                                Image.asset(
                              'assets/chopp-gecko2.png',
                            ),
                          )),
                          ListTile(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                    bottom: Radius.circular(12))),
                            // contentPadding: const EdgeInsets.only(left: 7.0),
                            tileColor: _repository.id() == defaultWallet.id()
                                ? Color(0xffD28928)
                                : Color(0xffFFD58D),
                            // leading: Text('IMAGE'),

                            // subtitle: Text(_repository.split(':')[3],
                            //     style: TextStyle(fontSize: 12.0, fontFamily: 'Monospace')),
                            title: Center(
                                child: Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 5),
                                    child: Text(_repository.name,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontSize: 16.0,
                                            color: _repository.id() ==
                                                    defaultWallet.id()
                                                ? Color(0xffF9F9F1)
                                                : Colors.black)))),
                            // dense: true,
                            onTap: () {
                              Navigator.push(
                                  context,
                                  SmoothTransition(
                                      page: WalletOptions(
                                    wallet: _repository,
                                  )));
                            },
                          )
                        ]))))
        ]);
  }

  Widget addNewDerivation(context, int _walletNbr) {
    final TextEditingController _newDerivationName = TextEditingController();
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    return AlertDialog(
      content: Stack(
        clipBehavior: Clip.hardEdge,
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
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 1,
                        primary: Color(0xffFFD68E), // background
                        onPrimary: Colors.black, // foreground
                      ),
                      onPressed: () async {
                        await _myWalletProvider
                            .generateNewDerivation(
                                context, _newDerivationName.text)
                            .then((_) => _newDerivationName.text == '');
                      },
                      child: Text("Créer")),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
