import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:gecko/extensions.dart';
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
import 'package:gecko/widgets/buttons/home_settings_button.dart';
import 'package:gecko/widgets/commons/animated_text.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:gecko/screens/myWallets/restore_chest.dart';
import 'package:gecko/screens/onBoarding/1.dart';
import 'package:gecko/widgets/drawer.dart';
import 'package:gecko/widgets/buttons/home_buttons.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final homeProvider = Provider.of<HomeProvider>(context, listen: false);
      final sub = Provider.of<SubstrateSdk>(context, listen: false);
      final duniterIndexer = Provider.of<DuniterIndexer>(context, listen: false);
      final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
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

        await homeProvider.getValidEndpoints();
        if (configBox.get('isCacheChecked') == null) {
          configBox.put('isCacheChecked', false);
        }

        Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
          log.i('Network changed: $result');
          if (result.contains(ConnectivityResult.none)) {
            sub.nodeConnected = false;
            await sub.sdk.api.setting.unsubscribeBestNumber();
            homeProvider.changeMessage("notConnectedToInternet".tr());
            sub.reload();
          } else {
            // Check if the phone is actually connected to the internet
            var connectivityResult = await (Connectivity().checkConnectivity());
            if (!connectivityResult.contains(ConnectivityResult.none)) {
              await sub.connectNode();

              // Load wallets list
              myWalletProvider.readAllWallets(myWalletProvider.getCurrentChest());

              //Connect to Indexer
              await duniterIndexer.getValidIndexerEndpoint();
            }
          }
        }

        Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
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

    isTall = (MediaQuery.of(context).size.height / MediaQuery.of(context).size.width) > 1.75;

    return Scaffold(
        resizeToAvoidBottomInset: false,
        drawer: MainDrawer(isWalletsExists: isWalletsExists),
        backgroundColor: context.colorScheme.secondary,
        body: isWalletsExists ? geckHome(context) : welcomeHome(context));
  }
}

Widget geckHome(BuildContext context) {
  Provider.of<ChestProvider>(context);

  final statusBarHeight = MediaQuery.of(context).padding.top;
  return Container(
    decoration: BoxDecoration(
      image: DecorationImage(
        opacity: 0.8,
        colorFilter: ColorFilter.mode(
          Colors.black.withValues(alpha: homeContext.isDarkTheme ? 0.8 : 0.4),
          BlendMode.colorDodge,
        ),
        image: AssetImage("assets/home/background.jpg"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Stack(children: <Widget>[
        Positioned(
          top: statusBarHeight + scaleSize(10),
          left: scaleSize(15),
          child: IconHomeSettings(),
        ),
        Align(
          child: Image(image: const AssetImage('assets/home/header.png'), height: scaleSize(165)),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 15),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          DefaultTextStyle(
            textAlign: TextAlign.center,
            style: scaledTextStyle(
              color: Colors.white,
              fontSize: 18,
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
                duration: const Duration(milliseconds: 200),
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
                Colors.black.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: const HomeButtons(),
        ),
      )
    ]),
  );
}

Widget welcomeHome(BuildContext context) {
  final statusBarHeight = MediaQuery.of(context).padding.top;

  return Container(
    decoration: const BoxDecoration(
      image: DecorationImage(
        image: AssetImage("assets/home/background.jpg"),
        fit: BoxFit.cover,
      ),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Stack(children: <Widget>[
        Positioned(
          top: statusBarHeight + scaleSize(10),
          left: scaleSize(15),
          child: IconHomeSettings(),
        ),
        Align(
          child: Image(image: const AssetImage('assets/home/header.png'), height: scaleSize(165)),
        ),
      ]),
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Expanded(
            child: Text(
              "fastAppDescription".tr(args: [currencyName]),
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                color: Colors.white,
                fontSize: isTall ? 19 : 17,
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
                Colors.black.withValues(alpha: 0.9),
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
                        padding: EdgeInsets.only(top: scaleSize(isTall ? 55 : 0)),
                        child: Image(
                          image: const AssetImage('assets/home/gecko-bienvenue.png'),
                          height: scaleSize(isTall ? 180 : 160),
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
                      backgroundColor: homeContext.colorScheme.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) return 0;
                          return 8;
                        },
                      ),
                      shadowColor: WidgetStateProperty.all(
                        Colors.black.withValues(alpha: 0.2),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const OnboardingStepOne(),
                        ),
                      );
                    },
                    child: Text(
                      'createWallet'.tr(),
                      style: scaledTextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
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
                      side: BorderSide(width: scaleSize(4), color: homeContext.colorScheme.primary),
                      padding: EdgeInsets.symmetric(vertical: scaleSize(8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                    ).copyWith(
                      elevation: WidgetStateProperty.resolveWith<double>(
                        (Set<WidgetState> states) {
                          if (states.contains(WidgetState.pressed)) return 0;
                          return 4;
                        },
                      ),
                      shadowColor: WidgetStateProperty.all(
                        Colors.black.withValues(alpha: 0.15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const RestoreChest(),
                        ),
                      );
                    },
                    child: Text(
                      "restoreWallet".tr(),
                      style: scaledTextStyle(fontSize: 20, color: homeContext.colorScheme.primary, fontWeight: FontWeight.w600),
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
