import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/myWallets.dart';
import 'package:gecko/models/walletData.dart';
import 'package:gecko/models/walletOptions.dart';
import 'package:flutter/material.dart';
import 'package:gecko/screens/commonElements.dart';
import 'package:gecko/screens/myWallets/chooseChest.dart';
import 'package:gecko/screens/myWallets/walletOptions.dart';
import 'package:gecko/screens/onBoarding/0_noKeychainFound.dart';
import 'package:provider/provider.dart';

class WalletsHome extends StatelessWidget {
  final _derivationKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context);

    final int _currentChest = myWalletProvider.getCurrentChest();

    myWalletProvider.listWallets =
        myWalletProvider.readAllWallets(_currentChest);
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

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
              key: Key('myWallets'), style: TextStyle(color: Colors.grey[850])),
          backgroundColor: Color(0xffFFD58D),
        ),
        body: SafeArea(
          child:
              !isWalletsExists ? NoKeyChainScreen() : myWalletsTiles(context),
        ),
      ),
    );
  }

  Widget chestOptions(BuildContext context) {
    return Column(children: [
      SizedBox(
          height: 90,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              primary: floattingYellow, // background
              onPrimary: Colors.black, // foreground
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) {
                return ChooseChest();
              }),
            ),
            child: Text(
              "Changer de coffre",
              style: TextStyle(fontSize: 16),
            ),
          ))
    ]);
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

    return CustomScrollView(slivers: <Widget>[
      SliverGrid.count(
          key: Key('listWallets'),
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
                    await _walletOptions.readLocalWallet(context, _repository,
                        _myWalletProvider.pinCode, _myWalletProvider.pinLenght);
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
                        tileColor: _repository.id()[1] == defaultWallet.id()[1]
                            ? orangeC
                            : Color(0xffFFD58D),
                        // leading: Text('IMAGE'),

                        // subtitle: Text(_repository.split(':')[3],
                        //     style: TextStyle(fontSize: 12.0, fontFamily: 'Monospace')),
                        title: Center(
                            child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 5),
                                child: Text(_repository.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontSize: 16.0,
                                        color: _repository.id()[1] ==
                                                defaultWallet.id()[1]
                                            ? Color(0xffF9F9F1)
                                            : Colors.black)))),
                        // dense: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            SmoothTransition(
                              page: WalletOptions(
                                wallet: _repository,
                              ),
                            ),
                          );
                        },
                      )
                    ]),
                  ),
                ),
              ),
            addNewDerivation(context)
          ]),
      // SliverToBoxAdapter(child: Spacer()),
      SliverPadding(
        padding: EdgeInsets.symmetric(horizontal: 30),
        sliver: SliverToBoxAdapter(child: chestOptions(context)),
      ),
    ]);
  }

  Widget addNewDerivation(context) {
    return Padding(
        padding: EdgeInsets.all(16),
        child: ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: Column(children: <Widget>[
              Expanded(
                child: InkWell(
                    key: Key('addDerivation'),
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return addNewDerivationPopup(context);
                          });
                    },
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(color: floattingYellow),
                      child: Center(
                          child: Text(
                        '+',
                        style: TextStyle(
                            fontSize: 150,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFFCB437)),
                      )),
                    )),
              )
            ])));
  }

  Widget addNewDerivationPopup(context) {
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
                    key: Key('DerivationNameKey'),
                    controller: _newDerivationName,
                    textAlign: TextAlign.center,
                    autofocus: true,
                  ),
                ),
                SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      key: Key('validDerivation'),
                      style: ElevatedButton.styleFrom(
                        elevation: 1,
                        primary: yellowC, // background
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
