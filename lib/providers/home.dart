import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:durt2/durt2.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/my_wallets.dart' show MyWalletsProvider;
import 'package:gecko/providers/v2s_datapod.dart' show V2sDatapodProvider;
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';

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

  String homeMessage = "loading".tr();

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
  }

  Future changeCurrencyUnit(BuildContext context) async {
    final bool isUdUnit = configBox.get('isUdUnit') ?? false;
    await configBox.put('isUdUnit', !isUdUnit);

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
        // Check connection status before changing to "noLizard"
        // Only set "noLizard" if both Duniter and Squid are in good state
        try {
          final duniterStatus = _container.read(duniterConnectionStatusProvider);
          final squidStatus = _container.read(squidConnectionStatusProvider);

          // Only show "noLizard" if we have a good connection
          if (duniterStatus == ConnectionStatus.connected && squidStatus == ConnectionStatus.connected) {
            homeMessage = "noLizard".tr();
            notifyListeners();
          }
          // If connections are bad, keep the current message (which should reflect the connection state)
        } catch (e) {
          log.w('Error checking connection status in changeMessage: $e');
          // If we can't check status, don't change the message to be safe
        }
      });
    }
  }

  void reload() {
    notifyListeners();
  }

  Future<void> initHome({required BuildContext context, required WidgetRef ref}) async {
    final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
    final datapod = old_provider.Provider.of<V2sDatapodProvider>(context, listen: false);

    // Check if versionData non compatible, drop everything
    if (configBox.get('dataVersion') == null) {
      configBox.put('dataVersion', dataVersion);
    }
    if (configBox.get('dataVersion') < dataVersion) {
      // ignore: use_build_context_synchronously
      await infoPopup(context, "chestNotCompatibleMustReinstallGecko".tr());
      await datapod.deleteAvatarsDirectory();
      await avatarsDirectory.create();
      await configBox.delete('defaultWallet');
      await configBox.clear();
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await Hive.deleteBoxFromDisk('contactsBox');
      await Hive.deleteBoxFromDisk('wallet_header_cache');

      g1WalletsBox = await Hive.openBox('g1WalletsBox');
      contactsBox = await Hive.openBox('contactsBox');
      walletHeaderDataBox = await Hive.openBox('wallet_header_cache');

      await _container.read(walletServiceProvider).clearWallets();
      configBox.put('dataVersion', dataVersion);
      myWalletProvider.reload();
    }

    walletHeaderDataBox = await Hive.openBox<WalletHeaderData>("wallet_header_cache");

    if (!_container.read(durtProvider).isConnected) {
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await datapod.deleteAvatarsCacheDirectory();
      await avatarsCacheDirectory.create();
      g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");
      contactsBox = await Hive.openBox<G1WalletsList>("contactsBox");

      myWalletProvider.reload();

      // await homeProvider.getValidEndpoints();
      if (configBox.get('isCacheChecked') == null) {
        configBox.put('isCacheChecked', false);
      }

      Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
        // ignore: avoid_print
        print('Network changed: $result');
        if (result.contains(ConnectivityResult.none)) {
          homeProvider.changeMessage("notConnectedToInternet".tr());
        } else {
          homeProvider.changeMessage("connectionInProgress".tr());
          // Check if the phone is actually connected to the internet
          var connectivityResult = await (Connectivity().checkConnectivity());
          if (!connectivityResult.contains(ConnectivityResult.none)) {
            // Connect to Duniter network
            try {
              await _container.read(durtProvider).connect();
              // ignore: avoid_print
              print('💡 Successfully connected to Duniter');
            } catch (e) {
              // ignore: avoid_print
              print('🔴 Failed to connect to Duniter: $e');

              // Check if this is a genesis validation error
              if (e.toString().contains('genesis hash') || e.toString().contains('genesis validation')) {
                homeProvider.changeMessage("networkGenesisError".tr());
              } else {
                homeProvider.changeMessage("networkConnectionError".tr());
              }
            }

            ref.watch(connectionStatusProvider);

            // Load wallets list
            await myWalletProvider.readAllWallets();
          }
        }
      }

      Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
    }
  }
}
