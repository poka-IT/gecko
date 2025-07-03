import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:durt2/durt2.dart' show Networks;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/duniter_indexer.dart';
import 'package:gecko/providers/my_wallets.dart' show MyWalletsProvider;
import 'package:gecko/providers/v2s_datapod.dart' show V2sDatapodProvider;
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/widgets/commons/common_elements.dart' show infoPopup;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, setEquals;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:gecko/services/network_config.service.dart';

class HomeProvider with ChangeNotifier {
  late ProviderContainer _container;

  HomeProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

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
    Hive.registerAdapter(G1WalletsListAdapter());
    Hive.registerAdapter(IdAdapter());

    // Open required boxes synchronously
    configBox = await Hive.openBox("configBox");

    // Check if walletHeaderDataVersion non compatible, drop wallet_header_cache
    if (configBox.get('walletHeaderDataVersion') == null ||
        configBox.get('walletHeaderDataVersion') < walletHeaderDataVersion) {
      await Hive.deleteBoxFromDisk('wallet_header_cache');
      configBox.put('walletHeaderDataVersion', walletHeaderDataVersion);
    }

    walletHeaderDataBox = await Hive.openBox<WalletHeaderData>("wallet_header_cache");
  }

  Future changeCurrencyUnit(BuildContext context) async {
    final walletOptions = old_provider.Provider.of<WalletOptionsProvider>(context, listen: false);
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    await configBox.put('isUdUnit', !isUdUnit);
    walletOptions.balanceCache = {};
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
        // await configBox.put('endpoint', remoteEndpoints);
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
    final existingEndpoints = Networks.listDuniterEndpoints;
    if (_isValidEndpointsList(existingEndpoints)) {
      // Lancer la mise à jour en background
      unawaited(_updateEndpointsInBackground(List<String>.from(existingEndpoints)));
      return List<String>.from(existingEndpoints);
    }

    try {
      // 2. Tentative de fetch distant
      final endpoints = await _fetchRemoteEndpoints();
      endpoints.shuffle();
      // await configBox.put('endpoint', endpoints);
      return endpoints;
    } catch (e) {
      // 3. Fallback sur le fichier local
      try {
        final localEndpoints = await rootBundle
            .loadString('config/gdev_endpoints.json')
            .then((jsonStr) => List<String>.from(jsonDecode(jsonStr)));

        localEndpoints.shuffle();
        // await configBox.put('endpoint', localEndpoints);
        return localEndpoints;
      } catch (e) {
        log.e('Erreur critique endpoints: $e');
        return Networks.listDuniterEndpoints;
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

  Future<void> initHome(BuildContext context) async {
    final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final datapod = old_provider.Provider.of<V2sDatapodProvider>(context, listen: false);

    // Check if versionData non compatible, drop everything
    if (configBox.get('dataVersion') == null) {
      configBox.put('dataVersion', dataVersion);
    }
    if (myWalletProvider.isWalletsExists && (configBox.get('dataVersion')) < dataVersion) {
      // if (!sub.sdkReady && !sub.sdkLoading) sub.initApi();
      // ignore: use_build_context_synchronously
      await infoPopup(context, "chestNotCompatibleMustReinstallGecko".tr());
      await datapod.deleteAvatarsDirectory();
      await avatarsDirectory.create();
      await configBox.delete('defaultWallet');
      // if (!sub.sdkReady && !sub.sdkLoading) await sub.initApi();
      await _container.read(walletServiceProvider).clearWallets();
      configBox.put('dataVersion', dataVersion);
      myWalletProvider.reload();
    } else {
      // if (!sub.sdkReady && !sub.sdkLoading) await sub.initApi();
    }

    if (!_container.read(durtProvider).isConnected) {
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await datapod.deleteAvatarsCacheDirectory();
      await avatarsCacheDirectory.create();
      g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");
      contactsBox = await Hive.openBox<G1WalletsList>("contactsBox");

      homeProvider.isWalletBoxInit = true;
      myWalletProvider.reload();

      // await homeProvider.getValidEndpoints();
      if (configBox.get('isCacheChecked') == null) {
        configBox.put('isCacheChecked', false);
      }

      // Connect to Duniter network
      await _container.read(durtProvider).connect();

      // Load wallets list
      await myWalletProvider.readAllWallets();

      //Connect to Indexer
      // ignore: use_build_context_synchronously
      final duniterIndexer = old_provider.Provider.of<DuniterIndexer>(context, listen: false);
      await duniterIndexer.getValidIndexerEndpoint();

      // // Test multi balances - TODO: Re-implement if needed

      // Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
      //   log.i('Network changed: $result');
      //   if (result.contains(ConnectivityResult.none)) {
      //     // Handle disconnection - TODO: Re-implement if needed
      //     homeProvider.changeMessage("notConnectedToInternet".tr());
      //       //   } else {
      //     // Check if the phone is actually connected to the internet
      //     var connectivityResult = await (Connectivity().checkConnectivity());
      //     if (!connectivityResult.contains(ConnectivityResult.none)) {
      //       await sub.connectNode();

      //       // Load wallets list
      //       // myWalletProvider.readAllWallets(myWalletProvider.getCurrentSafe);

      //       //Connect to Indexer
      //       await duniterIndexer.getValidIndexerEndpoint();
      //     }
      //   }
      // }

      // Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
    }
  }
}
