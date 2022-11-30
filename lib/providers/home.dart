// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'dart:math';
// import 'package:audioplayers/audio_cache.dart';
// import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/screens/myWallets/wallets_home.dart';
import 'package:gecko/screens/search.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class HomeProvider with ChangeNotifier {
  bool? isSearching;
  Icon searchIcon = const Icon(Icons.search);
  final TextEditingController searchQuery = TextEditingController();
  Widget appBarTitle = Text('Ğecko', style: TextStyle(color: Colors.grey[850]));
  String homeMessage = "loading".tr();
  String defaultMessage = "noLizard".tr();

  Future<void> initHive() async {
    late Directory hivePath;

    if (!kIsWeb) {
      if (Platform.isLinux || Platform.isMacOS) {
        final home = Platform.environment['HOME'];
        hivePath = Directory('$home/.gecko/db');
      } else if (Platform.isWindows) {
        final home = Platform.environment['UserProfile'];
        hivePath = Directory('$home/.gecko/db');
      } else if (Platform.isAndroid || Platform.isIOS) {
        final home = await pp.getApplicationDocumentsDirectory();
        hivePath = Directory('${home.path}/db');
      }
      if (!await hivePath.exists()) {
        await hivePath.create(recursive: true);
      }
      await Hive.initFlutter(hivePath.path);
    } else {
      await Hive.initFlutter();
    }

    // Init app folders
    final documentDir = await getApplicationDocumentsDirectory();
    imageDirectory = Directory('${documentDir.path}/images');

    if (!await imageDirectory.exists()) {
      await imageDirectory.create();
    }
  }

  Future changeCurrencyUnit(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    await configBox.put('isUdUnit', !isUdUnit);
    balanceCache = {};
    sub.getBalanceRatio();
    notifyListeners();
  }

  Future<String> getAppVersion() async {
    String version;
    String buildNumber;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildNumber = kDebugMode
        ? packageInfo.buildNumber
        : (int.parse(packageInfo.buildNumber) - 1000).toString();

    notifyListeners();
    return '$version+$buildNumber';
  }

  Future changeMessage(String newMessage, int seconds) async {
    homeMessage = newMessage;
    notifyListeners();
    await Future.delayed(Duration(seconds: seconds));
    if (seconds != 0) homeMessage = defaultMessage;
    notifyListeners();
  }

  Future<List?> getValidEndpoints() async {
    await configBox.delete('endpoint');
    if (!configBox.containsKey('autoEndpoint')) {
      configBox.put('autoEndpoint', true);
    }

    List listEndpoints = [];
    if (!configBox.containsKey('endpoint') ||
        configBox.get('endpoint') == [] ||
        configBox.get('endpoint') == '') {
      listEndpoints = await rootBundle
          .loadString('config/gdev_endpoints.json')
          .then((jsonStr) => jsonDecode(jsonStr));
      listEndpoints.shuffle();
      configBox.put('endpoint', listEndpoints);
    }

    log.i('ENDPOINT: $listEndpoints');
    return listEndpoints;
  }

  T getRandomElement<T>(List<T> list) {
    final random = Random();
    var i = random.nextInt(list.length);
    return list[i];
  }

  void handleSearchStart() {
    isSearching = true;
    notifyListeners();
  }

  // void playSound(String customSound, double volume) async {
  //   await player.play('$customSound.wav',
  //       volume: volume, mode: PlayerMode.LOW_LATENCY, stayAwake: false);
  // }

  Widget bottomAppBar(BuildContext context) {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    WalletsProfilesProvider historyProvider =
        Provider.of<WalletsProfilesProvider>(context, listen: false);

    final size = MediaQuery.of(context).size;

    const bool showBottomBar = true;

    return Visibility(
      visible: showBottomBar,
      child: Container(
        color: yellowC,
        width: size.width,
        height: 80,
        child:
            // Stack(
            //   children: [
            //     // CustomPaint(
            //     //   size: Size(size.width, 110),
            //     //   painter: CustomRoundedButton(),
            //     // ),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
          // SizedBox(width: 0),
          const Spacer(),
          const SizedBox(width: 11),
          IconButton(
            key: keyAppBarSearch,
            iconSize: 40,
            icon: const Image(image: AssetImage('assets/loupe-noire.png')),
            onPressed: () {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
              Navigator.push(
                context,
                MaterialPageRoute(builder: (homeContext) {
                  return const SearchScreen();
                }),
              );
            },
          ),
          const SizedBox(width: 22),
          const Spacer(),
          IconButton(
            key: keyAppBarQrcode,
            iconSize: 70,
            icon: const Image(image: AssetImage('assets/qrcode-scan.png')),
            onPressed: () async {
              Navigator.popUntil(
                context,
                ModalRoute.withName('/'),
              );
              historyProvider.scan(homeContext);
            },
          ),
          const Spacer(),
          const SizedBox(width: 15),
          IconButton(
            key: keyAppBarChest,
            iconSize: 60,
            icon: const Image(image: AssetImage('assets/wallet.png')),
            onPressed: () async {
              WalletData? defaultWallet = myWalletProvider.getDefaultWallet();
              String? pin;
              if (myWalletProvider.pinCode == '') {
                pin = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (homeContext) {
                      return UnlockingWallet(wallet: defaultWallet);
                    },
                  ),
                );
              }

              if (pin != null || myWalletProvider.pinCode != '') {
                Navigator.popUntil(
                  context,
                  ModalRoute.withName('/'),
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) {
                    return const WalletsHome();
                  }),
                );
              }
            },
          ),
          const Spacer(),
        ]),
      ),
    );
  }

  void reload() {
    notifyListeners();
  }
}
