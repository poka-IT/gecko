import 'package:bubble/bubble.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/stateful_wrapper.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/screens/animated_text.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/screens/search.dart';
import 'package:gecko/screens/settings.dart';
import 'package:flutter/services.dart';
import 'package:gecko/screens/substrate_sandbox.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    homeContext = context;
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context);
    Provider.of<ChestProvider>(context);
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    final bool isWalletsExists = _myWalletProvider.checkIfWalletExist();

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
                key: const Key('substrateSandbox'),
                title: const Text('Substrate debug'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const SubstrateSandBox();
                    }),
                  );
                },
              ),

              // ListTile(
              //   title: const Text('A propos'),
              //   onTap: () {
              //   },
              // ),
            ])),
            Align(
                alignment: FractionalOffset.bottomCenter,
                child: Text('Ğecko v$appVersion')),
            const SizedBox(height: 20)
          ],
        ),
      ),
      // bottomNavigationBar: _homeProvider.bottomBar(context, 1),
      backgroundColor: const Color(0xffF9F9F1),
      body: Builder(
        builder: (ctx) => StatefulWrapper(
            onInit: () {
              WidgetsBinding.instance.addPostFrameCallback((_) async {
                if (!_sub.sdkReady && !_sub.sdkLoading) await _sub.initApi();
                if (_sub.sdkReady && !_sub.nodeConnected) {
                  // Check if versionData non compatible, drop everything
                  if (walletBox.isNotEmpty &&
                      walletBox.getAt(0)!.version! < dataVersion) {
                    await infoPopup(context,
                        "La version de vos coffres n'est plus comptabile avec cette version de Ğecko.\nTous vos coffres vont être oubliés, vous devez les importer de nouveau.");
                    await walletBox.clear();
                    await chestBox.clear();
                    await configBox.delete('defaultWallet');
                    await _sub.deleteAllAccounts();
                    _myWalletProvider.rebuildWidget();
                  }

                  var connectivityResult =
                      await (Connectivity().checkConnectivity());
                  HomeProvider _homeProvider =
                      Provider.of<HomeProvider>(ctx, listen: false);
                  if (connectivityResult != ConnectivityResult.mobile &&
                      connectivityResult != ConnectivityResult.wifi) {
                    _homeProvider.changeMessage(
                        "Vous n'êtes pas connecté à internet", 0);
                    _sub.nodeConnected = false;
                  }

                  Connectivity()
                      .onConnectivityChanged
                      .listen((ConnectivityResult result) async {
                    log.d('Network changed: $result');
                    if (result == ConnectivityResult.none) {
                      _sub.nodeConnected = false;
                      await _sub.sdk.api.setting.unsubscribeBestNumber();
                      _homeProvider.changeMessage(
                          "Vous n'êtes pas connecté à internet", 0);
                      _sub.reload();
                    } else {
                      await _sub.connectNode(ctx);
                    }
                  });
                }
                DuniterIndexer _duniterIndexer =
                    Provider.of<DuniterIndexer>(ctx, listen: false);
                _duniterIndexer.checkIndexerEndpoint();
              });
            },
            child: isWalletsExists ? geckHome(context) : welcomeHome(context)
            // bottomNavigationBar: BottomNavigationBar(
            //   backgroundColor: backgroundColor,
            //   fixedColor: Colors.grey[850],
            //   unselectedItemColor: const Color(0xffBD935C),
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
            //     const BottomNavigationBarItem(
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

Widget geckHome(context) {
  MyWalletsProvider _myWalletProvider = Provider.of<MyWalletsProvider>(context);
  Provider.of<ChestProvider>(context);

  WalletsProfilesProvider _historyProvider =
      Provider.of<WalletsProfilesProvider>(context);
  final double statusBarHeight = MediaQuery.of(context).padding.top;
  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/home/background.jpg"),
        fit: BoxFit.cover,
      ),
    ),
    child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
          child:
              Image(image: AssetImage('assets/home/header.png'), height: 210),
        ),
      ]),
      Padding(
        padding: EdgeInsets.only(top: 15 * ratio),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          DefaultTextStyle(
            textAlign: TextAlign.center,
            style: const TextStyle(
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
            child: Consumer<HomeProvider>(builder: (context, _homeP, _) {
              return AnimatedFadeOutIn<String>(
                data: _homeP.homeMessage,
                duration: const Duration(milliseconds: 100),
                builder: (value) => Text(value),
              );
            }),
          ),
        ]),
      ),
      const SizedBox(height: 15),
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
            const Spacer(),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Column(children: <Widget>[
                Container(
                  child: ClipOval(
                    child: Material(
                      color: orangeC, // button color
                      child: InkWell(
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Image(
                                image:
                                    const AssetImage('assets/home/loupe.png'),
                                height: 62 * ratio),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) {
                                return const SearchScreen();
                              }),
                            );
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
                Text(
                  "Rechercher un\nportefeuille",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * ratio,
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
                          child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Image(
                                  image: const AssetImage(
                                      'assets/home/wallet.png'),
                                  height: 68 * ratio)),
                          onTap: () async {
                            WalletData? defaultWallet =
                                _myWalletProvider.getDefaultWallet();
                            String? _pin;
                            if (_myWalletProvider.pinCode == '') {
                              _pin = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (homeContext) {
                                    return UnlockingWallet(
                                        wallet: defaultWallet);
                                  },
                                ),
                              );
                            }
                            if (_pin != null ||
                                _myWalletProvider.pinCode != '') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) {
                                  return const WalletsHome();
                                }),
                              );
                            }
                            // log.d(_myWalletProvider.pinCode);

                            // Navigator.pushNamed(
                            //     context, '/mywallets')));
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
                Text(
                  "Gérer mes\nportefeuilles",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15 * ratio,
                      fontWeight: FontWeight.w500),
                )
              ])
            ]),
            Padding(
              padding: EdgeInsets.only(top: 35 * ratio),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(children: <Widget>[
                      Container(
                        child: ClipOval(
                          child: Material(
                            color: orangeC, // button color
                            child: InkWell(
                                child: Padding(
                                    padding: const EdgeInsets.all(18),
                                    child: Image(
                                        image: const AssetImage(
                                            'assets/home/qrcode.png'),
                                        height: 68 * ratio)),
                                onTap: () async {
                                  await _historyProvider.scan(context);
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
                      Text(
                        "Scanner un\nQR code",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15 * ratio,
                            fontWeight: FontWeight.w500),
                      )
                    ])
                  ]),
            ),
            SizedBox(height: isTall ? 80 : 40)
          ]),
        ),
      )
    ]),
  );
}

Widget welcomeHome(context) {
  final double statusBarHeight = MediaQuery.of(context).padding.top;

  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/home/background.jpg"),
        fit: BoxFit.cover,
      ),
    ),
    child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
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
          child:
              Image(image: AssetImage('assets/home/header.png'), height: 210),
        ),
      ]),
      Padding(
        padding: EdgeInsets.only(top: 1 * ratio),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(
            "L’application de paiement $currencyName\nplus rapide qu’un reptile du Vietnam",
            textAlign: TextAlign.center,
            style: const TextStyle(
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(children: <Widget>[
                const Spacer(),
                Row(children: <Widget>[
                  Expanded(
                    child: Stack(children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 55),
                        child: Image(
                          image: AssetImage('assets/home/gecko-bienvenue.png'),
                          height: 220,
                        ),
                      ),
                      Positioned(
                        left: 180,
                        child: bubbleSpeak("y'a pas de lézard !"),
                      ),
                      const Positioned(
                        left: 200,
                        top: 60,
                        child: Image(
                          image: AssetImage('assets/home/bout_de_bulle.png'),
                        ),
                      ),
                    ]),
                  ),
                ]),
                SizedBox(
                  width: 410,
                  height: 70,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 4,
                      primary: orangeC, // background
                      onPrimary: Colors.white, // foreground
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const OnboardingStepOne();
                          },
                        ),
                      );
                    },
                    child: const Text(
                      'Créer un portefeuille',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 25 * ratio),
                SizedBox(
                  width: 410,
                  height: 70,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(width: 4, color: orangeC)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) {
                            return const RestoreChest();
                          },
                        ),
                      );
                    },
                    child: Text(
                      "Restaurer mes portefeuilles",
                      style: TextStyle(
                          fontSize: 24,
                          color: orangeC,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: isTall ? 100 : 50)
              ]),
            ),
          ),
        ),
      )
    ]),
  );
}

Widget bubbleSpeak(String text, {double? long, Key? textKey}) {
  return Bubble(
    padding: long == null
        ? const BubbleEdges.all(20)
        : BubbleEdges.symmetric(horizontal: long, vertical: 30),
    elevation: 5,
    color: backgroundColor,
    child: Text(
      text,
      key: textKey,
      style: const TextStyle(
          color: Colors.black, fontSize: 21, fontWeight: FontWeight.w400),
    ),
  );
}
