// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers_deprecated/my_wallets.dart';
import 'package:gecko/services/app_info_service.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/services/storage_init_service.dart';
import 'package:gecko/services/wisdom_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart' as old_provider;

/// Provider for AppInfoService
final appInfoServiceProvider = Provider<AppInfoService>((ref) {
  return AppInfoService();
});

/// Provider for WisdomService
final wisdomServiceProvider = Provider<WisdomService>((ref) {
  return WisdomService();
});

/// Provider for StorageInitService
final storageInitServiceProvider = Provider<StorageInitService>((ref) {
  return StorageInitService();
});

/// Provider for ImageCacheService
final imageCacheServiceProvider = Provider<ImageCacheService>((ref) {
  return ImageCacheService();
});

/// Provider for the app version string
final appVersionProvider = FutureProvider<String>((ref) async {
  final appInfoService = ref.watch(appInfoServiceProvider);
  await appInfoService.init();
  return appInfoService.appVersion;
});

/// Home message state and notifier
class HomeMessageNotifier extends StateNotifier<String> {
  Timer? _resetTimer;

  HomeMessageNotifier() : super('');

  /// Change the home message
  Future<void> changeMessage(String newMessage, [bool reset = false]) async {
    state = newMessage;

    if (reset) {
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 5), () {
        // Check connection status before changing to "noLizard"
        // Only set "noLizard" if both Duniter and Squid are in good state
        try {
          final container = ProviderContainer();
          final duniterStatus = container.read(duniterConnectionStatusProvider);
          final squidStatus = container.read(squidConnectionStatusProvider);

          // Only show "noLizard" if we have a good connection
          if (duniterStatus == d.ConnectionStatus.connected && squidStatus == d.ConnectionStatus.connected) {
            state = "noLizard".tr();
          }
          // If connections are bad, keep the current message (which should reflect the connection state)
          container.dispose();
        } catch (e) {
          log.w('Error checking connection status in changeMessage: $e');
          // If we can't check status, don't change the message to be safe
        }
      });
    }
  }

  /// Show wisdom of the day easter egg
  Future<void> showWisdomOfTheDay(BuildContext context) async {
    try {
      // Get current locale language code
      final currentLocale = context.locale;
      final languageCode = currentLocale.languageCode;

      // Get wisdom of the day
      final wisdomService = WisdomService();
      final wisdom = await wisdomService.getWisdomOfTheDay(languageCode);

      if (wisdom != null) {
        state = wisdom;

        // Reset to normal message after 8 seconds
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(seconds: 8), () {
          // Check connection status before changing back to "noLizard"
          try {
            final container = ProviderContainer();
            final duniterStatus = container.read(duniterConnectionStatusProvider);
            final squidStatus = container.read(squidConnectionStatusProvider);

            // Only show "noLizard" if we have a good connection
            if (duniterStatus == d.ConnectionStatus.connected && squidStatus == d.ConnectionStatus.connected) {
              state = "noLizard".tr();
            }
            container.dispose();
          } catch (e) {
            log.w('Error checking connection status in wisdom easter egg: $e');
            // If we can't check status, go back to "noLizard" anyway for the easter egg
            state = "noLizard".tr();
          }
        });
      }
    } catch (e) {
      log.e('Error in showWisdomOfTheDay: $e');
    }
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }
}

/// Provider for home message state
final homeMessageProvider = StateNotifierProvider<HomeMessageNotifier, String>((ref) {
  return HomeMessageNotifier();
});

/// App initialization state
class AppInitState {
  final bool isStorageInitialized;
  final bool isAppVersionLoaded;
  final bool isConnected;
  final String? error;

  const AppInitState({
    required this.isStorageInitialized,
    required this.isAppVersionLoaded,
    required this.isConnected,
    this.error,
  });

  bool get isCompleted => isStorageInitialized && isAppVersionLoaded && isConnected && error == null;

  AppInitState copyWith({bool? isStorageInitialized, bool? isAppVersionLoaded, bool? isConnected, String? error}) {
    return AppInitState(
      isStorageInitialized: isStorageInitialized ?? this.isStorageInitialized,
      isAppVersionLoaded: isAppVersionLoaded ?? this.isAppVersionLoaded,
      isConnected: isConnected ?? this.isConnected,
      error: error ?? this.error,
    );
  }
}

/// App initialization notifier
class AppInitNotifier extends StateNotifier<AppInitState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AppInitNotifier()
    : super(const AppInitState(isStorageInitialized: false, isAppVersionLoaded: false, isConnected: false));

  /// Initialize the application
  Future<void> initApp({required BuildContext context, required WidgetRef ref}) async {
    try {
      // Initialize storage
      final storageService = ref.read(storageInitServiceProvider);
      await storageService.initHive();
      state = state.copyWith(isStorageInitialized: true);

      // Load app version
      await ref.read(appVersionProvider.future);
      state = state.copyWith(isAppVersionLoaded: true);

      // Start preloading images in background (fire and forget)
      final imageService = ref.read(imageCacheServiceProvider);
      imageService.preloadCriticalImages(context).catchError((e) {
        log.w('Failed to preload images: $e');
      });

      // Handle data version compatibility and initialization
      await _handleDataVersionCompatibility(context, ref);

      // Setup connection handling
      await _setupConnectionHandling(context, ref);
    } catch (e) {
      log.e('Error during app initialization: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Handle data version compatibility
  Future<void> _handleDataVersionCompatibility(BuildContext context, WidgetRef ref) async {
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

      await ref.read(walletServiceProvider).clearWallets();
      configBox.put('dataVersion', dataVersion);

      // Reload wallets using old provider for now
      final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      myWalletProvider.reload();
    }

    walletHeaderDataBox = await Hive.openBox('wallet_header_cache');
  }

  /// Setup connection handling and network monitoring
  Future<void> _setupConnectionHandling(BuildContext context, WidgetRef ref) async {
    final homeMessageNotifier = ref.read(homeMessageProvider.notifier);

    if (!ref.read(durtProvider).isConnected) {
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await avatarsCacheDirectory.create();
      g1WalletsBox = await Hive.openBox('g1WalletsBox');
      contactsBox = await Hive.openBox('contactsBox');

      // Reload wallets using old provider for now
      final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
      myWalletProvider.reload();

      bool firstConnection = true;

      Future<void> updateConnectionStatus(List<ConnectivityResult> result) async {
        if (!firstConnection) {
          log.d('Network changed: $result');
        }
        firstConnection = false;

        if (result.contains(ConnectivityResult.none)) {
          await homeMessageNotifier.changeMessage("notConnectedToInternet".tr());
          // Reset Durt connection status to trigger connectionStatusProvider update and show offline banner
          try {
            ref.read(durtProvider).resetConnectionStatus();
            log.d('🔴 Durt connection status reset due to network loss');
          } catch (e) {
            log.e('🔴 Error resetting Durt connection status: $e');
          }
        } else {
          await homeMessageNotifier.changeMessage("connectionInProgress".tr());
          // Check if the phone is actually connected to the internet
          var connectivityResult = await (Connectivity().checkConnectivity());
          if (!connectivityResult.contains(ConnectivityResult.none)) {
            // Connect to Duniter network
            try {
              await ref.read(durtProvider).connect(verbose: false);
              log.d('💡 Successfully connected to Duniter');
              state = state.copyWith(isConnected: true);
            } catch (e) {
              log.e('🔴 Failed to connect to Duniter: $e');

              // Check if this is a genesis validation error
              if (e.toString().contains('genesis hash') || e.toString().contains('genesis validation')) {
                await homeMessageNotifier.changeMessage("networkGenesisError".tr());
              } else {
                await homeMessageNotifier.changeMessage("networkConnectionError".tr());
              }
            }

            // Load wallets list
            final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
            await myWalletProvider.readAllWallets(ref: ref);
          }
        }
      }

      _connectivitySubscription = Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
    } else {
      state = state.copyWith(isConnected: true);
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

/// Provider for app initialization state
final appInitProvider = StateNotifierProvider<AppInitNotifier, AppInitState>((ref) {
  return AppInitNotifier();
});
