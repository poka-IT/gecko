import 'package:dubp/dubp.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_provider.dart';
import 'package:gecko/models/history.dart';
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
    // HomeProvider _homeProvider = Provider.of<HomeProvider>(context);
    HistoryProvider _historyProvider = Provider.of<HistoryProvider>(context);
    HistoryProvider _historyStatic = HistoryProvider('');
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    Provider.of<ChestProvider>(context);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

    var statusBarHeight = MediaQuery.of(context).padding.top;

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
      backgroundColor: const Color(0xffF9F9F1),
      body: Builder(
        builder: (ctx) => StatefulWrapper(
          onInit: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              DubpRust.setup();
              _historyStatic.snackNode(ctx);
            });
          },
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/home/background.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Stack(children: <Widget>[
                    Positioned(
                      top: statusBarHeight + 10,
                      left: 15,
                      child: Builder(
                        builder: (context) => IconButton(
                          key: const Key('drawerMenu'),
                          icon: const Icon(
                            Icons.menu,
                            color: Colors.white,
                            size: 35,
                          ),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                    const Align(
                      child: Image(
                          image: AssetImage('assets/home/header.png'),
                          height: 210),
                    ),
                  ]),
                  Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const <Widget>[
                          Text(
                            "y'a pas de lézard ;-)",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              shadows: <Shadow>[
                                Shadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 20,
                                  color: Colors.black,
                                ),
                                Shadow(
                                  offset: Offset(0, 0),
                                  blurRadius: 20,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          )
                        ]),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                      ),
                      child: Column(children: <Widget>[
                        Padding(
                          padding: EdgeInsets.only(top: isTall ? 240 : 130),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Column(children: <Widget>[
                                  Container(
                                    child: ClipOval(
                                      child: Material(
                                        color: orangeC, // button color
                                        child: InkWell(
                                            child: const Padding(
                                                padding: EdgeInsets.all(18),
                                                child: Image(
                                                    image: AssetImage(
                                                        'assets/home/loupe.png'),
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
                                      color: Colors.black,
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 2,
                                            offset: Offset(1, 1.5),
                                            spreadRadius: 0.5)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Rechercher un\nportfeuille",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500),
                                  )
                                ]),
                                const SizedBox(width: 120),
                                Column(children: <Widget>[
                                  Container(
                                    child: ClipOval(
                                      key: const Key('manageWallets'),
                                      child: Material(
                                        color: orangeC, // button color
                                        child: InkWell(
                                            child: const Padding(
                                                padding: EdgeInsets.all(18),
                                                child: Image(
                                                    image: AssetImage(
                                                        'assets/home/wallet.png'),
                                                    height: 75)),
                                            onTap: () {
                                              WalletData defaultWallet =
                                                  _myWalletProvider
                                                      .getDefaultWallet(
                                                          configBox.get(
                                                              'currentChest'));
                                              isWalletsExists
                                                  ? Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) {
                                                      return UnlockingWallet(
                                                        wallet: defaultWallet,
                                                        action: "mywallets",
                                                      );
                                                    }))

                                                  // Navigator.pushNamed(
                                                  //     context, '/mywallets')
                                                  : Navigator.push(context,
                                                      MaterialPageRoute(
                                                          builder: (context) {
                                                      return const NoKeyChainScreen();
                                                    }));
                                            }),
                                      ),
                                    ),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 2,
                                            offset: Offset(1, 1.5),
                                            spreadRadius: 0.5)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Gérer mes\nportefeuilles",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500),
                                  )
                                ])
                              ]),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Column(children: <Widget>[
                                  Container(
                                    child: ClipOval(
                                      child: Material(
                                        color: orangeC, // button color
                                        child: InkWell(
                                            child: const Padding(
                                                padding: EdgeInsets.all(22),
                                                child: Image(
                                                    image: AssetImage(
                                                        'assets/home/qrcode.png'),
                                                    height: 60)),
                                            onTap: () async {
                                              await _historyProvider
                                                  .scan(context);
                                            }),
                                      ),
                                    ),
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black,
                                      boxShadow: [
                                        BoxShadow(
                                            blurRadius: 2,
                                            offset: Offset(1, 1.5),
                                            spreadRadius: 0.5)
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Scanner un\nQR code",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w500),
                                  )
                                ])
                              ]),
                        ),
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
                  )
                ]),
          ),
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
