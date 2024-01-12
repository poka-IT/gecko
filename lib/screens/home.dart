import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:flutter/material.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/v2s_datapod.dart';
import 'package:gecko/widgets/bubble_speak.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:gecko/widgets/buttons/home_buttons.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
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
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final sub = Provider.of<SubstrateSdk>(context, listen: false);
      final duniterIndexer =
          Provider.of<DuniterIndexer>(context, listen: false);
      final myWalletProvider =
          Provider.of<MyWalletsProvider>(context, listen: false);
      final datapod = Provider.of<V2sDatapodProvider>(context, listen: false);

      final bool isWalletsExists = myWalletProvider.isWalletsExists();

      // Check if versionData non compatible, drop everything
      if (configBox.get('dataVersion') == null) {
        configBox.put('dataVersion', dataVersion);
      }
      if (isWalletsExists && (configBox.get('dataVersion')) < dataVersion) {
        if (!sub.sdkReady && !sub.sdkLoading) sub.initApi();
        await infoPopup(context, "chestNotCompatibleMustReinstallGecko".tr());
        await Hive.deleteBoxFromDisk('walletBox');
        await Hive.deleteBoxFromDisk('chestBox');
        await datapod.deleteAvatarsDirectory();
        await avatarsDirectory.create();
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
        await datapod.deleteAvatarsCacheDirectory();
        await avatarsCacheDirectory.create();
        g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");
        contactsBox = await Hive.openBox<G1WalletsList>("contactsBox");

        homeProvider.isWalletBoxInit = true;
        myWalletProvider.reload();

        duniterIndexer.getValidIndexerEndpoint().then((validIndexerEndpoint) {
          final wsLinkIndexer = WebSocketLink(
            'wss://$validIndexerEndpoint/v1/graphql',
          );

          const headerWebsocket =
              datapodEndpoint == '10.0.2.2:8080' ? 'ws' : 'wss';
          final wsLinkDatapod = WebSocketLink(
            '$headerWebsocket://$datapodEndpoint/v1/graphql',
          );

          duniterIndexer.indexerClient = GraphQLClient(
            cache: GraphQLCache(),
            link: wsLinkIndexer,
          );

          datapod.datapodClient = GraphQLClient(
            cache: GraphQLCache(),
            link: wsLinkDatapod,
          );
        });

        await homeProvider.getValidEndpoints();
        if (configBox.get('isCacheChecked') == null) {
          configBox.put('isCacheChecked', false);
        }

        Connectivity()
            .onConnectivityChanged
            .listen((ConnectivityResult result) async {
          log.i('Network changed: $result');
          if (result == ConnectivityResult.none) {
            sub.nodeConnected = false;
            await sub.sdk.api.setting.unsubscribeBestNumber();
            homeProvider.changeMessage("notConnectedToInternet".tr(), 0);
            sub.reload();
          } else {
            // Check if the phone is actually connected to the internet
            var connectivityResult = await (Connectivity().checkConnectivity());
            if (connectivityResult != ConnectivityResult.none) {
              await sub.connectNode();
            }
          }
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    homeContext = context;

    final myWalletProvider = Provider.of<MyWalletsProvider>(context);
    Provider.of<ChestProvider>(context);
    final isWalletsExists = myWalletProvider.isWalletsExists();

    isTall = (MediaQuery.of(context).size.height /
            MediaQuery.of(context).size.width) >
        1.75;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MainDrawer(isWalletsExists: isWalletsExists),
        backgroundColor: yellowC,
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
          top: statusBarHeight + scaleSize(10),
          left: scaleSize(15),
          child: Builder(
            builder: (context) => IconButton(
              key: keyDrawerMenu,
              icon: Icon(
                Icons.menu,
                color: Colors.black,
                size: scaleSize(35),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        Align(
          child: Image(
              image: const AssetImage('assets/home/header.png'),
              height: scaleSize(165)),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 15),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          DefaultTextStyle(
            textAlign: TextAlign.center,
            style: scaledTextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              shadows: <Shadow>[
                const Shadow(
                  offset: Offset(0, 0),
                  blurRadius: 20,
                  color: Colors.black,
                ),
                const Shadow(
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
      ScaledSizedBox(height: 15),
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
          top: statusBarHeight + scaleSize(10),
          left: scaleSize(15),
          child: Builder(
            builder: (context) => IconButton(
              key: keyDrawerMenu,
              icon: Icon(
                Icons.menu,
                color: Colors.black,
                size: scaleSize(35),
              ),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        Align(
          child: Image(
              image: const AssetImage('assets/home/header.png'),
              height: scaleSize(165)),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(
            "fastAppDescription".tr(args: [currencyName]),
            textAlign: TextAlign.center,
            style: scaledTextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              shadows: const <Shadow>[
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
                const Spacer(flex: 4),
                Row(children: <Widget>[
                  Expanded(
                    child: Stack(children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: scaleSize(55)),
                        child: Image(
                          image: const AssetImage(
                              'assets/home/gecko-bienvenue.png'),
                          height: scaleSize(180),
                        ),
                      ),
                      Positioned(
                        left: scaleSize(160),
                        top: 10,
                        child: BubbleSpeakWithTail(text: "noLizard".tr()),
                      ),
                    ]),
                  ),
                ]),
                ScaledSizedBox(
                  width: 330,
                  height: 60,
                  child: ElevatedButton(
                    key: keyOnboardingNewChest,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      elevation: 4,
                      backgroundColor: orangeC,
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
                      style: scaledTextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w600,
                          color: Colors.white),
                    ),
                  ),
                ),
                ScaledSizedBox(height: scaleSize(25)),
                ScaledSizedBox(
                  width: 330,
                  height: 60,
                  child: OutlinedButton(
                    key: keyRestoreChest,
                    style: OutlinedButton.styleFrom(
                        side: BorderSide(width: scaleSize(4), color: orangeC)),
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
                      style: scaledTextStyle(
                          fontSize: 21,
                          color: orangeC,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const Spacer(flex: 3),
              ]),
            ),
          ),
        ),
      )
    ]),
  );
}
