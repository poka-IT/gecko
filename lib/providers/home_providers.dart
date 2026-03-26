import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:durt2/durt2.dart' as d;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/network_activity_provider.dart';
import 'package:gecko/providers/network_certifications_provider.dart';
import 'package:gecko/providers/network_identities_provider.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/home_alert_provider.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/squid_cache_buster.dart';
import 'package:gecko/services/config_service.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/services/app_info_service.dart';
import 'package:gecko/services/image_cache_service.dart';
import 'package:gecko/services/storage_init_service.dart';
import 'package:gecko/services/wisdom_service.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:graphql_flutter/graphql_flutter.dart' show FetchPolicy, QueryOptions, gql;
import 'package:hive_flutter/hive_flutter.dart';

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

/// Home message state and notifier.
///
/// Manages the message displayed on the home screen. Priority order:
/// 1. Connection status messages (set externally by [ConnectionStatusNotifier])
/// 2. Contextual alerts from [homeAlertProvider] (cert/membership expiration)
/// 3. Default "noLizard" message when everything is healthy
///
/// Temporary messages (connection, easter eggs) auto-reset to the current
/// alert or default message after a delay.
class HomeMessageNotifier extends Notifier<String> {
  Timer? _resetTimer;

  @override
  String build() {
    ref.onDispose(() => _resetTimer?.cancel());
    return '';
  }

  /// Returns the best idle message: alert if any, otherwise "noLizard".
  String _idleMessage() {
    try {
      final alert = ref.read(homeAlertProvider);
      if (alert.hasAlert) return alert.message;
    } catch (_) {
      // Provider not yet initialized — fall back to default
    }
    return "noLizard".tr();
  }

  /// Change the home message.
  ///
  /// When [reset] is true, the message auto-resets after 5 seconds to the
  /// current alert message (or "noLizard" if no alerts).
  Future<void> changeMessage(String newMessage, [bool reset = false]) async {
    state = newMessage;

    if (reset) {
      _resetTimer?.cancel();
      _resetTimer = Timer(const Duration(seconds: 5), () {
        try {
          final duniterStatus = ref.read(duniterConnectionStatusProvider);
          final squidStatus = ref.read(squidConnectionStatusProvider);

          if (duniterStatus == d.ConnectionStatus.connected && squidStatus == d.ConnectionStatus.connected) {
            state = _idleMessage();
          }
        } catch (e) {
          log.w('Error checking connection status in changeMessage: $e');
        }
      });
    }
  }

  /// Updates the home message to reflect the current alert state.
  ///
  /// Called by the home screen when the alert provider changes.
  /// Only updates if no connection issue is active (connection messages
  /// take absolute precedence).
  void syncWithAlert(HomeAlertState alert) {
    try {
      final duniterStatus = ref.read(duniterConnectionStatusProvider);
      final squidStatus = ref.read(squidConnectionStatusProvider);

      if (duniterStatus != d.ConnectionStatus.connected || squidStatus != d.ConnectionStatus.connected) {
        return; // Connection message takes precedence
      }
    } catch (_) {
      return;
    }

    state = alert.hasAlert ? alert.message : "noLizard".tr();
  }

  /// Show wisdom of the day easter egg.
  Future<void> showWisdomOfTheDay(BuildContext context) async {
    try {
      final currentLocale = context.locale;
      final languageCode = currentLocale.languageCode;

      final wisdomService = ref.read(wisdomServiceProvider);
      final wisdom = await wisdomService.getWisdomOfTheDay(languageCode);

      if (wisdom != null) {
        state = wisdom;

        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(seconds: 8), () {
          try {
            final duniterStatus = ref.read(duniterConnectionStatusProvider);
            final squidStatus = ref.read(squidConnectionStatusProvider);

            if (duniterStatus == d.ConnectionStatus.connected && squidStatus == d.ConnectionStatus.connected) {
              state = _idleMessage();
            }
          } catch (e) {
            log.w('Error checking connection status in wisdom easter egg: $e');
            state = _idleMessage();
          }
        });
      }
    } catch (e) {
      log.e('Error in showWisdomOfTheDay: $e');
    }
  }
}

/// Provider for home message state
final homeMessageProvider = NotifierProvider<HomeMessageNotifier, String>(HomeMessageNotifier.new);

class NetworkTotals {
  final int transactions;
  final int certifications;
  final int memberIdentities;
  final int unconfirmedIdentities;
  final int unvalidatedIdentities;
  final int expiredIdentities;

  const NetworkTotals({
    required this.transactions,
    required this.certifications,
    required this.memberIdentities,
    required this.unconfirmedIdentities,
    required this.unvalidatedIdentities,
    required this.expiredIdentities,
  });

  const NetworkTotals.empty()
    : this(
        transactions: 0,
        certifications: 0,
        memberIdentities: 0,
        unconfirmedIdentities: 0,
        unvalidatedIdentities: 0,
        expiredIdentities: 0,
      );

  int get identities => memberIdentities + unconfirmedIdentities + unvalidatedIdentities;
}

/// Fetches exact network totals from Squid using GraphQL connection totalCount,
/// independent from the paginated lists currently loaded in UI providers.
/// Throttled: skips re-fetch if last successful fetch was < 10 seconds ago.
DateTime _lastTotalsFetch = DateTime.fromMillisecondsSinceEpoch(0);
NetworkTotals? _lastTotalsResult;
String? _lastTotalsNetwork;

final networkTotalsProvider = FutureProvider<NetworkTotals>((ref) async {
  final currentNetwork = ref.watch(networkProvider).name;
  ref.watch(squidCacheBusterProvider);
  ref.watch(networkActivityProvider.select((state) => state.lastActivityId));
  ref.watch(networkIdentitiesProvider.select((state) => state.lastActivityId));
  ref.watch(networkCertificationsProvider.select((state) => state.lastActivityId));

  // Reset cache on network switch
  if (_lastTotalsNetwork != currentNetwork) {
    _lastTotalsResult = null;
    _lastTotalsNetwork = currentNetwork;
  }

  // Throttle: return cached result if last fetch was recent
  if (_lastTotalsResult != null && DateTime.now().difference(_lastTotalsFetch).inSeconds < 10) {
    return _lastTotalsResult!;
  }

  final squidStatus = ref.watch(squidConnectionStatusProvider);
  if (squidStatus != d.ConnectionStatus.connected) {
    // Return cached result if available, otherwise empty
    return _lastTotalsResult ?? const NetworkTotals.empty();
  }

  const document = r'''
    query GetNetworkTotals {
      transfers(first: 1) {
        totalCount
      }
      memberIdentities: identities(first: 1, filter: {status: {equalTo: "Member"}}) {
        totalCount
      }
      unconfirmedIdentities: identities(first: 1, filter: {status: {equalTo: "Unconfirmed"}}) {
        totalCount
      }
      unvalidatedIdentities: identities(first: 1, filter: {status: {equalTo: "Unvalidated"}}) {
        totalCount
      }
      expiredIdentities: identities(first: 1, filter: {status: {equalTo: "NotMember"}}) {
        totalCount
      }
      certs(first: 1, filter: {isActive: {equalTo: true}}) {
        totalCount
      }
    }
  ''';

  final result = await d.SquidService.client.query(
    QueryOptions(document: gql(document), fetchPolicy: FetchPolicy.networkOnly),
  );

  if (result.hasException) {
    log.w('Squid query failed: ${result.exception}');
    return _lastTotalsResult ?? const NetworkTotals.empty();
  }

  final data = result.data;
  if (data == null) {
    return const NetworkTotals.empty();
  }

  int readTotal(String key) {
    final section = data[key] as Map<String, dynamic>?;
    return (section?['totalCount'] as int?) ?? 0;
  }

  final totals = NetworkTotals(
    transactions: readTotal('transfers'),
    certifications: readTotal('certs'),
    memberIdentities: readTotal('memberIdentities'),
    unconfirmedIdentities: readTotal('unconfirmedIdentities'),
    unvalidatedIdentities: readTotal('unvalidatedIdentities'),
    expiredIdentities: readTotal('expiredIdentities'),
  );

  _lastTotalsFetch = DateTime.now();
  _lastTotalsResult = totals;
  return totals;
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
class AppInitNotifier extends Notifier<AppInitState> {
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  AppInitState build() {
    ref.onDispose(() => _connectivitySubscription?.cancel());
    return const AppInitState(isStorageInitialized: false, isAppVersionLoaded: false, isConnected: false);
  }

  /// Initialize the application
  Future<void> initApp({required BuildContext context, required WidgetRef widgetRef}) async {
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
      // ignore: use_build_context_synchronously
      imageService.preloadCriticalImages(context).catchError((e) {
        log.w('Failed to preload images: $e');
      });

      // Handle data version compatibility and initialization
      if (!context.mounted) return;
      await _handleDataVersionCompatibility(context, widgetRef);

      // Setup connection handling
      if (!context.mounted) return;
      await _setupConnectionHandling(context, widgetRef);
    } catch (e) {
      log.e('Error during app initialization: $e');
      state = state.copyWith(error: e.toString());
    }
  }

  /// Handle data version compatibility
  Future<void> _handleDataVersionCompatibility(BuildContext context, WidgetRef widgetRef) async {
    final config = ref.read(configServiceProvider);
    // Check if versionData non compatible, drop everything
    if (config.dataVersion == null) {
      config.dataVersion = dataVersion;
    }

    if (config.dataVersion! < dataVersion) {
      await showConfirmationDialog(
        context: context,
        message: "safeNotCompatibleMustReinstallGecko".tr(),
        confirmText: "gotit".tr(),
        barrierDismissible: false,
        hideCancelButton: true,
      );

      await avatarsDirectory.create();
      await config.deleteDefaultWallet();
      await config.clearAll();
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await Hive.deleteBoxFromDisk('contactsBox');
      await Hive.deleteBoxFromDisk('wallet_header_cache');

      g1WalletsBox = await Hive.openBox('g1WalletsBox');
      contactsBox = await Hive.openBox('contactsBox');
      walletHeaderDataBox = await Hive.openBox('wallet_header_cache');

      await ref.read(walletServiceProvider).clearWallets();
      config.dataVersion = dataVersion;

      // Reload wallets using Riverpod provider
      ref.read(walletsListProvider.notifier).refresh();
    }

    walletHeaderDataBox = await Hive.openBox('wallet_header_cache');
  }

  /// Setup connection handling and network monitoring
  Future<void> _setupConnectionHandling(BuildContext context, WidgetRef widgetRef) async {
    final homeMessageNotifier = ref.read(homeMessageProvider.notifier);

    if (!ref.read(durtProvider).isConnected) {
      await Hive.deleteBoxFromDisk('g1WalletsBox');
      await avatarsCacheDirectory.create();
      g1WalletsBox = await Hive.openBox('g1WalletsBox');
      contactsBox = await Hive.openBox('contactsBox');

      // Reload wallets using Riverpod provider
      ref.read(walletsListProvider.notifier).refresh();

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

            // Load wallets list using Riverpod provider
            await ref.read(walletsListProvider.notifier).loadWallets();
          }
        }
      }

      try {
        _connectivitySubscription = Connectivity().onConnectivityChanged.listen(updateConnectionStatus);
      } on PlatformException catch (e) {
        log.w('Connectivity monitoring unavailable: $e');
      }
    } else {
      state = state.copyWith(isConnected: true);
    }
  }
}

/// Provider for app initialization state
final appInitProvider = NotifierProvider<AppInitNotifier, AppInitState>(AppInitNotifier.new);
