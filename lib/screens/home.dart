import 'package:dubp/dubp.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_provider.dart';
import 'package:gecko/models/history.dart';
import 'package:gecko/models/home.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/onBoarding/0_no_keychain_found.dart';
import 'dart:ui';
import 'package:gecko/screens/settings.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    HistoryProvider _historyStatic = HistoryProvider('');
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    Provider.of<ChestProvider>(context);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

    // walletBox.toMap().forEach((key, value) {
    //   if (value.chest == 0) {
    //     print('$key: ${value.derivation}');
    //   }
    // });

    isTall = false;
    ratio = 1;
    if (MediaQuery.of(context).size.height >= 930) {
      isTall = true;
      ratio = 1.125;
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      drawer: Drawer(
        child: Column(
          children: <Widget>[
            Expanded(
                child: ListView(padding: EdgeInsets.zero, children: <Widget>[
              DrawerHeader(
                child: Column(children: const <Widget>[
                  SizedBox(height: 0),
                  Image(
                      image: AssetImage('assets/icon/gecko_final.png'),
                      height: 130),
                ]),
                decoration: BoxDecoration(
                  color: orangeC,
                ),
              ),
              ListTile(
                key: const Key('parameters'),
                title: const Text('Paramètres'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return SettingsScreen();
                    }),
                  );
                },
              ),
              ListTile(
                title: const Text('A propos'),
                onTap: () {
                  // Update the state of the app.
                  // ...
                },
              ),
            ])),
            Align(
                alignment: FractionalOffset.bottomCenter,
                child: Text('Ğecko v$appVersion')),
            const SizedBox(height: 20)
          ],
        ),
      ),
      appBar: AppBar(
        toolbarHeight: 60 * ratio,
        leading: Builder(
            builder: (context) => IconButton(
                  key: const Key('drawerMenu'),
                  icon: Icon(Icons.menu, color: Colors.grey[850]),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                )),
        title: _homeProvider.appBarTitle,
        actions: [
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: IconButton(
                  key: const Key('searchIcon'),
                  icon: _homeProvider.searchIcon,
                  color: Colors.grey[850],
                  onPressed: () {
                    if (_homeProvider.searchIcon.icon == Icons.search) {
                      _homeProvider.searchIcon = Icon(
                        Icons.close,
                        color: Colors.grey[850],
                      );
                      _homeProvider.appBarTitle = TextField(
                        key: const Key('searchInput'),
                        autofocus: true,
                        controller: _homeProvider.searchQuery,
                        onChanged: (text) {
                          log.d("Clé tappé: $text");
                          final String searchResult =
                              _historyProvider.isPubkey(context, text);
                          if (searchResult != '') {
                            _homeProvider.currentIndex = 0;
                          }
                        },
                        style: TextStyle(
                          color: Colors.grey[850],
                        ),
                        decoration: InputDecoration(
                            prefixIcon:
                                Icon(Icons.search, color: Colors.grey[850]),
                            hintText: "Rechercher ...",
                            hintStyle: TextStyle(color: Colors.grey[850])),
                      );
                      _homeProvider.handleSearchStart();
                    } else {
                      _homeProvider.handleSearchEnd();
                    }
                  }))
        ],
        backgroundColor: const Color(0xffFFD58D),
      ),
      backgroundColor: const Color(0xffF9F9F1),
      body: Builder(
        builder: (ctx) => StatefulWrapper(
          onInit: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DubpRust.setup();
              _historyStatic.snackNode(ctx);
            });
          },
          child: Column(children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    SizedBox(width: 7),
                    Image(
                        image: AssetImage('assets/icon/gecko_final.png'),
                        height: 180),
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const <Widget>[
                    Text(
                      "y'a pas de lézard !",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 17,
                          fontStyle: FontStyle.italic),
                    )
                  ]),
            ),
            Padding(
              padding: EdgeInsets.only(top: isTall ? 70 : 60),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Container(
                        child: ClipOval(
                          child: Material(
                            color: const Color(0xffFFD58D), // button color
                            child: InkWell(
                                splashColor: orangeC, // inkwell color
                                child: const Padding(
                                    padding: EdgeInsets.all(22),
                                    child: Image(
                                        image: AssetImage(
                                            'assets/qrcode-scan.png'),
                                        height: 60)),
                                onTap: () async {
                                  await _historyProvider.scan(context);
                                }),
                          ),
                        ),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey,
                                blurRadius: 4.0,
                                offset: Offset(2.0, 2.5),
                                spreadRadius: 0.5)
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Payer par QR-Code",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      )
                    ])
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 50),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Container(
                        child: ClipOval(
                          child: Material(
                            color: const Color(0xffFFD58D), // button color
                            child: InkWell(
                                splashColor: orangeC, // inkwell color
                                child: const Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 16),
                                    child: Image(
                                        image:
                                            AssetImage('assets/blockchain.png'),
                                        height: 70)),
                                onTap: () {
                                  // Navigator.push(
                                  //   context,
                                  //   MaterialPageRoute(
                                  //       builder: (context) {
                                  //     return TemplateScreen();
                                  //   }),
                                  // );
                                }),
                          ),
                        ),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey,
                                blurRadius: 4.0,
                                offset: Offset(2.0, 2.5),
                                spreadRadius: 0.5)
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Explorer\n",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      )
                    ]),
                    const SizedBox(width: 140),
                    Column(children: <Widget>[
                      Container(
                        child: ClipOval(
                          key: const Key('manageWallets'),
                          child: Material(
                            color: const Color(0xffFFD58D), // button color
                            child: InkWell(
                                splashColor: orangeC, // inkwell color
                                child: const Padding(
                                    padding: EdgeInsets.all(23),
                                    child: Image(
                                        image: AssetImage('assets/lock.png'),
                                        height: 57)),
                                onTap: () {
                                  WalletData defaultWallet =
                                      _myWalletProvider.getDefaultWallet(
                                          configBox.get('currentChest'));
                                  isWalletsExists
                                      ? Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                          return UnlockingWallet(
                                            wallet: defaultWallet,
                                            action: "mywallets",
                                          );
                                        }))

                                      // Navigator.pushNamed(
                                      //     context, '/mywallets')
                                      : Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                          return const NoKeyChainScreen();
                                        }));
                                }),
                          ),
                        ),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.grey,
                                blurRadius: 4.0,
                                offset: Offset(2.0, 2.5),
                                spreadRadius: 0.5)
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Gérer mes\nportefeuilles",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      )
                    ])
                  ]),
            )
          ]),
          // bottomNavigationBar: BottomNavigationBar(
          //   backgroundColor: Color(0xffFFD58D),
          //   fixedColor: Colors.grey[850],
          //   unselectedItemColor: Color(0xffBD935C),
          //   type: BottomNavigationBarType.fixed,
          //   onTap: (index) {
          //     _homeProvider.currentIndex = index;
          //   },
          //   currentIndex: _homeProvider.currentIndex,
          //   items: [
          //     BottomNavigationBarItem(
          //       icon: Image.asset('assets/block-space-disabled.png', height: 26),
          //       activeIcon: Image.asset('assets/blockchain.png', height: 26),
          //       label: 'Explorateur',
          //     ),
          //     BottomNavigationBarItem(
          //       icon: Icon(Icons.lock),
          //       label: 'Mes portefeuilles',
          //     ),
          //   ],
          // ),
        ),
      ),
    );
  }
}

class StatefulWrapper extends StatefulWidget {
  final Function onInit;
  final Widget child;
  const StatefulWrapper({Key key, @required this.onInit, @required this.child})
      : super(key: key);
  @override
  _StatefulWrapperState createState() => _StatefulWrapperState();
}

class _StatefulWrapperState extends State<StatefulWrapper> {
  @override
  void initState() {
    if (widget.onInit != null) {
      widget.onInit();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
