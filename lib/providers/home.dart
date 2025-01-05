import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/widgets/wallet_header.dart';
import 'package:gecko/models/wallet_header_data.dart';

class HomeProvider with ChangeNotifier {
  bool? isSearching;
  Icon searchIcon = const Icon(Icons.search);
  final searchQuery = TextEditingController();
  Widget appBarTitle = Text('Ğecko', style: TextStyle(color: Colors.grey[850]));
  String homeMessage = "loading".tr();
  final homeMessages = ["loading".tr()]; // 3D message log, not used
  String defaultMessage = "noLizard".tr();
  bool isWalletBoxInit = false;

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
    avatarsDirectory = Directory('${documentDir.path}/avatars');
    avatarsCacheDirectory = Directory('${documentDir.path}/avatarsCache');

    if (!await avatarsDirectory.exists()) {
      await avatarsDirectory.create();
    }

    // Register Hive adapters
    Hive.registerAdapter(WalletHeaderDataAdapter());
    Hive.registerAdapter(BigIntAdapter());
    Hive.registerAdapter(WalletDataAdapter());
    Hive.registerAdapter(ChestDataAdapter());
    Hive.registerAdapter(G1WalletsListAdapter());
    Hive.registerAdapter(IdAdapter());
    Hive.registerAdapter(IdtyStatusAdapter());

    // Open required boxes synchronously
    chestBox = await Hive.openBox<ChestData>("chestBox");
    configBox = await Hive.openBox("configBox");

    // Initialize other boxes asynchronously
    unawaited(WalletHeader.initializeBox());
  }

  Future changeCurrencyUnit(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final walletOptions = Provider.of<WalletOptionsProvider>(context, listen: false);
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    await configBox.put('isUdUnit', !isUdUnit);
    walletOptions.balanceCache = {};
    sub.getBalanceRatio();
    notifyListeners();
  }

  Future<String> getAppVersion() async {
    String version;
    String buildNumber;
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildNumber = kDebugMode ? packageInfo.buildNumber : (int.parse(packageInfo.buildNumber) - 1000).toString();

    notifyListeners();
    return '$version+$buildNumber';
  }

  Future changeMessage(String newMessage, [bool reset = false]) async {
    homeMessage = newMessage;
    notifyListeners();
    if (reset) {
      await Future.delayed(const Duration(seconds: 5), () {
        homeMessage = "noLizard".tr();
        notifyListeners();
      });
    }
  }

  Future<List?> getValidEndpoints() async {
    await configBox.delete('endpoint');
    if (!configBox.containsKey('autoEndpoint')) {
      configBox.put('autoEndpoint', true);
    }

    List listEndpoints = [];
    if (!configBox.containsKey('endpoint') || configBox.get('endpoint') == [] || configBox.get('endpoint') == '') {
      listEndpoints = await rootBundle.loadString('config/gdev_endpoints.json').then((jsonStr) => jsonDecode(jsonStr));
      listEndpoints.shuffle();
      configBox.put('endpoint', listEndpoints);
    }

    return listEndpoints;
  }

  T getRandomElement<T>(List<T> list) {
    final random = Random();
    var i = random.nextInt(list.length);
    return list[i];
  }

  // void playSound(String customSound, double volume) async {
  //   await player.play('$customSound.wav',
  //       volume: volume, mode: PlayerMode.LOW_LATENCY, stayAwake: false);
  // }

  void reload() {
    notifyListeners();
  }
}
