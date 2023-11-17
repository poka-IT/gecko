// ignore_for_file: use_build_context_synchronously

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:gecko/widgets/home_buttons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProviderInit =
          Provider.of<HomeProvider>(context, listen: false);
      final sub = Provider.of<SubstrateSdk>(context, listen: false);
      final duniterIndexer =
          Provider.of<DuniterIndexer>(context, listen: false);
      final myWalletProvider =
          Provider.of<MyWalletsProvider>(context, listen: false);

      final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

      // Check if versionData non compatible, drop everything
      if (configBox.get('dataVersion') == null) {
        configBox.put('dataVersion', dataVersion);
      }
      if (isWalletsExists && (configBox.get('dataVersion')) < dataVersion) {
        if (!sub.sdkReady && !sub.sdkLoading) sub.initApi();
        await infoPopup(context, "chestNotCompatibleMustReinstallGecko".tr());
        await Hive.deleteBoxFromDisk('walletBox');
        await Hive.deleteBoxFromDisk('chestBox');
        chestBox = await Hive.openBox<ChestData>("chestBox");
        await configBox.delete('defaultWallet');
        if (!sub.sdkReady && !sub.sdkLoading) await sub.initApi();
        await sub.deleteAllAccounts();
        configBox.put('dataVersion', dataVersion);
        myWalletProvider.reload();
      } else {
        if (!sub.sdkReady && !sub.sdkLoading) await sub.initApi();
      }

      if (sub.sdkReady && !sub.nodeConnected) {
        walletBox = await Hive.openBox<WalletData>("walletBox");
        await Hive.deleteBoxFromDisk('g1WalletsBox');
        g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");
        contactsBox = await Hive.openBox<G1WalletsList>("contactsBox");

        homeProviderInit.isWalletBoxInit = true;
        myWalletProvider.reload();

        duniterIndexer.getValidIndexerEndpoint();

        await homeProviderInit.getValidEndpoints();
        if (configBox.get('isCacheChecked') == null) {
          configBox.put('isCacheChecked', false);
        }

        HomeProvider homeProvider =
            Provider.of<HomeProvider>(context, listen: false);
        Connectivity()
            .onConnectivityChanged
            .listen((ConnectivityResult result) async {
          log.d('Network changed: $result');
          if (result == ConnectivityResult.none) {
            sub.nodeConnected = false;
            await sub.sdk.api.setting.unsubscribeBestNumber();
            homeProvider.changeMessage("notConnectedToInternet".tr(), 0);
            sub.reload();
          } else {
            // Check if the phone is actually connected to the internet
            var connectivityResult = await (Connectivity().checkConnectivity());
            if (connectivityResult != ConnectivityResult.none) {
              await sub.connectNode(context);
            }
          }
        });
      }
      // _duniterIndexer.checkIndexerEndpointBackground();
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    homeContext = context;

    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    Provider.of<ChestProvider>(context);
    final bool isWalletsExists = myWalletProvider.checkIfWalletExist();

    isTall = false;
    ratio = 1;
    if (MediaQuery.of(context).size.height >= 930) {
      isTall = true;
      ratio = 1.125;
    }

    //TODO: finish to implement multiqueries

    // final sub = Provider.of<SubstrateSdk>(context, listen: false);
    // sub.getBalanceMulti([
    //   '5CQ8T4qpbYJq7uVsxGPQ5q2df7x3Wa4aRY6HUWMBYjfLZhnn',
    //   '5Dq8xjvkmbz7q4g2LbZgyExD26VSCutfEc6n4W4AfQeVHZqz'
    // ]);

    return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MainDrawer(isWalletsExists: isWalletsExists),
        backgroundColor: const Color(0xffF9F9F1),
        body: isWalletsExists ? geckHome(context) : welcomeHome(context));
  }
}

Widget geckHome(context) {
  Provider.of<ChestProvider>(context);

  final statusBarHeight = MediaQuery.of(context).padding.top;
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
              key: keyDrawerMenu,
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
            child: Consumer<HomeProvider>(builder: (context, homeP, _) {
              return AnimatedFadeOutIn<String>(
                data: homeP.homeMessage,
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
          child: const HomeButtons(),
        ),
      )
    ]),
  );
}

Widget welcomeHome(context) {
  final statusBarHeight = MediaQuery.of(context).padding.top;

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
              key: keyDrawerMenu,
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
            "fastAppDescription".tr(args: [currencyName]),
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
                        child: BubbleSpeak(text: "noLizard".tr()),
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
                    key: keyOnboardingNewChest,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white, elevation: 4,
                      backgroundColor: orangeC, // foreground
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
                    child: Text(
                      'createWallet'.tr(),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                SizedBox(height: 25 * ratio),
                SizedBox(
                  width: 410,
                  height: 70,
                  child: OutlinedButton(
                    key: keyRestoreChest,
                    style: OutlinedButton.styleFrom(
                        side: const BorderSide(width: 4, color: orangeC)),
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
                      "restoreWallet".tr(),
                      style: const TextStyle(
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
