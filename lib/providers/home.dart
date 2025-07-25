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
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart' as pp;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as old_provider;
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/wallet_header_data.dart';
import 'package:flutter/services.dart';

import 'package:gecko/providers/trm_data_provider.dart';

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

  String homeMessage = '';

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

  // Legacy method for backward compatibility
  Future changeCurrencyUnit(BuildContext context) async {
    // This method is now handled by the new currency display mode system
    // It cycles between G1 and DU modes for backward compatibility
    final container = ProviderContainer();
    try {
      final currentMode = container.read(currencyDisplayModeProvider);
      final newMode = currentMode == CurrencyDisplayMode.g1 ? CurrencyDisplayMode.du : CurrencyDisplayMode.g1;
      container.read(currencyDisplayModeProvider.notifier).setDisplayMode(newMode);
    } finally {
      container.dispose();
    }

    notifyListeners();
  }

  Future<String> getAppVersion() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final version = packageInfo.version;
    final buildNumber = packageInfo.buildNumber;

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

  /// Calculate the day of the year (1-365/366)
  int _getDayOfYear(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return difference + 1; // Add 1 because we want 1-based indexing
  }

  /// Get wisdom of the day from assets
  Future<String?> _getWisdomOfTheDay(String languageCode) async {
    try {
      // Try to load the wisdom file for the current language
      String filePath = 'assets/gecko-wisdom/$languageCode.txt';
      String content;

      try {
        content = await rootBundle.loadString(filePath);
      } catch (e) {
        // If the language file doesn't exist, fallback to French
        log.w('Wisdom file not found for language $languageCode, falling back to French');
        content = await rootBundle.loadString('assets/gecko-wisdom/fr.txt');
      }

      final lines = content.split('\n').where((line) => line.trim().isNotEmpty).toList();

      if (lines.isEmpty) {
        return null;
      }

      // Calculate day of year for today
      final today = DateTime.now();
      final dayOfYear = _getDayOfYear(today);

      // Select the appropriate line
      int lineIndex = (dayOfYear - 1);
      // In case the number of days in the year is less than the number of lines…
      lineIndex %= lines.length;

      return lines[lineIndex].trim();
    } catch (e) {
      log.e('Error loading wisdom of the day: $e');
      return null;
    }
  }

  /// Display Gecko wisdom of the day (easter egg)
  Future<void> showWisdomOfTheDay(BuildContext context) async {
    try {
      // Get current locale language code
      final currentLocale = context.locale;
      final languageCode = currentLocale.languageCode;

      // Get wisdom of the day
      final wisdom = await _getWisdomOfTheDay(languageCode);

      if (wisdom != null) {
        homeMessage = wisdom;
        notifyListeners();

        // Reset to normal message after 8 seconds
        await Future.delayed(const Duration(seconds: 8), () {
          // Check connection status before changing back to "noLizard"
          try {
            final duniterStatus = _container.read(duniterConnectionStatusProvider);
            final squidStatus = _container.read(squidConnectionStatusProvider);

            // Only show "noLizard" if we have a good connection
            if (duniterStatus == ConnectionStatus.connected && squidStatus == ConnectionStatus.connected) {
              homeMessage = "noLizard".tr();
              notifyListeners();
            }
          } catch (e) {
            log.w('Error checking connection status in wisdom easter egg: $e');
            // If we can't check status, go back to "noLizard" anyway for the easter egg
            homeMessage = "noLizard".tr();
            notifyListeners();
          }
        });
      }
    } catch (e) {
      log.e('Error in showWisdomOfTheDay: $e');
    }
  }

  Future<void> initHome({required BuildContext context, required WidgetRef ref}) async {
    final homeProvider = old_provider.Provider.of<HomeProvider>(context, listen: false);
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    // Check if versionData non compatible, drop everything
    if (configBox.get('dataVersion') == null) {
      configBox.put('dataVersion', dataVersion);
    }
    if (configBox.get('dataVersion') < dataVersion) {
      await showConfirmationDialog(
        context: context,
        message: "safeNotCompatibleMustReinstallGecko".tr(),
        confirmText: "gotit".tr(),
        barrierDismissible: false,
        hideCancelButton: true,
      );
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
      await avatarsCacheDirectory.create();
      g1WalletsBox = await Hive.openBox<G1WalletsList>("g1WalletsBox");
      contactsBox = await Hive.openBox<G1WalletsList>("contactsBox");

      myWalletProvider.reload();

      // await homeProvider.getValidEndpoints();
      if (configBox.get('isCacheChecked') == null) {
        configBox.put('isCacheChecked', false);
      }

      bool firstConnection = true;
      Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
        if (!firstConnection) {
          // ignore: avoid_print
          print('Network changed: $result');
        }
        firstConnection = false;

        if (result.contains(ConnectivityResult.none)) {
          homeProvider.changeMessage("notConnectedToInternet".tr());
          // Reset Durt connection status to trigger connectionStatusProvider update and show offline banner
          try {
            _container.read(durtProvider).resetConnectionStatus();
            // ignore: avoid_print
            print('🔴 Durt connection status reset due to network loss');
          } catch (e) {
            // ignore: avoid_print
            print('🔴 Error resetting Durt connection status: $e');
          }
        } else {
          homeProvider.changeMessage("connectionInProgress".tr());
          // Check if the phone is actually connected to the internet
          var connectivityResult = await (Connectivity().checkConnectivity());
          if (!connectivityResult.contains(ConnectivityResult.none)) {
            // Connect to Duniter network
            try {
              await _container.read(durtProvider).connect(verbose: false);
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
            await myWalletProvider.readAllWallets(ref: ref);
          }
        }
      }

      Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
    }
  }
}
