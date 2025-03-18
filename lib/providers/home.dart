import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/certification_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, setEquals;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/services/network_config_service.dart';

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
    Hive.registerAdapter(CertificationDataAdapter());

    // Open required boxes synchronously
    chestBox = await Hive.openBox<ChestData>("chestBox");
    configBox = await Hive.openBox("configBox");

    // Check if walletHeaderDataVersion non compatible, drop wallet_header_cache
    if (configBox.get('walletHeaderDataVersion') == null || configBox.get('walletHeaderDataVersion') < walletHeaderDataVersion) {
      await Hive.deleteBoxFromDisk('wallet_header_cache');
      configBox.put('walletHeaderDataVersion', walletHeaderDataVersion);
    }

    walletHeaderDataBox = await Hive.openBox<WalletHeaderData>("wallet_header_cache");
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

  bool _isValidEndpointsList(dynamic endpoints) {
    if (endpoints == null) return false;
    if (endpoints is! List) return false;
    if (endpoints.isEmpty) return false;
    return endpoints.every((e) => e is String && e.startsWith('ws'));
  }

  Future<List<String>> _fetchRemoteEndpoints() async {
    try {
      final config = await NetworkConfigService.getNetworkConfig();
      if (config.rpc.isEmpty) throw 'No RPC endpoints found';
      return config.rpc;
    } catch (e) {
      log.e('Erreur fetch remote endpoints: $e');
      rethrow;
    }
  }

  Future<void> _updateEndpointsInBackground(List<String> currentEndpoints) async {
    try {
      final remoteEndpoints = await _fetchRemoteEndpoints();

      // Comparer les listes sans tenir compte de l'ordre
      final currentSet = Set.from(currentEndpoints);
      final remoteSet = Set.from(remoteEndpoints);

      if (!setEquals(currentSet, remoteSet)) {
        remoteEndpoints.shuffle();
        await configBox.put('endpoint', remoteEndpoints);
        log.i('Endpoints mis à jour en background');
      }
    } catch (e) {
      log.e('Erreur update background: $e');
    }
  }

  Future<List<String>> getValidEndpoints() async {
    // 0. Set automode if not set
    if (!configBox.containsKey('autoEndpoint')) {
      configBox.put('autoEndpoint', true);
    }

    // 1. Vérification rapide de la configBox
    final existingEndpoints = configBox.get('endpoint');
    if (_isValidEndpointsList(existingEndpoints)) {
      // Lancer la mise à jour en background
      unawaited(_updateEndpointsInBackground(List<String>.from(existingEndpoints)));
      return List<String>.from(existingEndpoints);
    }

    try {
      // 2. Tentative de fetch distant
      final endpoints = await _fetchRemoteEndpoints();
      endpoints.shuffle();
      await configBox.put('endpoint', endpoints);
      return endpoints;
    } catch (e) {
      // 3. Fallback sur le fichier local
      try {
        final localEndpoints = await rootBundle.loadString('config/gdev_endpoints.json').then((jsonStr) => List<String>.from(jsonDecode(jsonStr)));

        localEndpoints.shuffle();
        await configBox.put('endpoint', localEndpoints);
        return localEndpoints;
      } catch (e) {
        log.e('Erreur critique endpoints: $e');
        return configBox.get('endpoint') ?? [];
      }
    }
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
