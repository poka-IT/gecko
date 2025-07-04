import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart' show Box;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/home.dart';
import 'dart:async';
import 'package:provider/provider.dart' as old_provider;

/// Connection status notifier that listens to both Duniter and Squid streams
class ConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  final homeProvider = old_provider.Provider.of<HomeProvider>(homeContext, listen: false);
  StreamSubscription<d.ConnectionStatus>? _duniterSubscription;
  StreamSubscription<d.ConnectionStatus>? _squidSubscription;

  d.ConnectionStatus _duniterStatus = d.ConnectionStatus.disconnected;
  d.ConnectionStatus _squidStatus = d.ConnectionStatus.disconnected;

  ConnectionStatusNotifier() : super(d.ConnectionStatus.disconnected) {
    _initializeStreams();
  }

  void _initializeStreams() {
    try {
      final durt = d.Durt.i;

      // Listen to Duniter connection status
      _duniterSubscription = durt.duniterConnectionStatusStream.listen((status) {
        _duniterStatus = status;
        _updateCombinedStatus();
      });

      // Listen to Squid connection status
      _squidSubscription = durt.squidConnectionStatusStream.listen((status) {
        _squidStatus = status;

        switch (status) {
          case d.ConnectionStatus.connected:
            homeProvider.changeMessage("nodeAndIndexerSynced".tr(), true);
            break;
          case d.ConnectionStatus.disconnected || d.ConnectionStatus.error:
            homeProvider.changeMessage("noValidIndexerFound".tr());
            break;
          case d.ConnectionStatus.connecting:
            break;
        }

        _updateCombinedStatus();
      });

      // Set initial states
      _duniterStatus = durt.duniterConnectionStatus;
      _squidStatus = durt.squidConnectionStatus;
      _updateCombinedStatus();
    } catch (e) {
      state = d.ConnectionStatus.disconnected;
    }
  }

  void _updateCombinedStatus() {
    // For now, we consider the app connected if either Duniter OR Squid is connected
    // This can be adjusted based on your requirements
    final newStatus = (_duniterStatus == d.ConnectionStatus.connected || _squidStatus == d.ConnectionStatus.connected)
        ? d.ConnectionStatus.connected
        : d.ConnectionStatus.disconnected;

    if (newStatus != state) {
      state = newStatus;
    }
  }

  @override
  void dispose() {
    _duniterSubscription?.cancel();
    _squidSubscription?.cancel();
    super.dispose();
  }
}

/// Connection status notifier for Duniter only
class DuniterConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  DuniterConnectionStatusNotifier() : super(d.ConnectionStatus.disconnected) {
    _initializeStream();
  }

  void _initializeStream() {
    try {
      final durt = d.Durt.i;

      // Set initial state
      state = durt.duniterConnectionStatus;

      // Listen to stream
      _subscription = durt.duniterConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      state = d.ConnectionStatus.disconnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Connection status notifier for Squid only
class SquidConnectionStatusNotifier extends StateNotifier<d.ConnectionStatus> {
  StreamSubscription<d.ConnectionStatus>? _subscription;

  SquidConnectionStatusNotifier() : super(d.ConnectionStatus.disconnected) {
    _initializeStream();
  }

  void _initializeStream() {
    try {
      final durt = d.Durt.i;

      // Set initial state
      state = durt.squidConnectionStatus;

      // Listen to stream
      _subscription = durt.squidConnectionStatusStream.listen((status) {
        state = status;
      });
    } catch (e) {
      state = d.ConnectionStatus.disconnected;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Combined connection status provider (default)
final connectionStatusProvider = StateNotifierProvider<ConnectionStatusNotifier, d.ConnectionStatus>((ref) {
  return ConnectionStatusNotifier();
});

/// Duniter-only connection status provider
final duniterConnectionStatusProvider = StateNotifierProvider<DuniterConnectionStatusNotifier, d.ConnectionStatus>((
  ref,
) {
  return DuniterConnectionStatusNotifier();
});

/// Squid-only connection status provider
final squidConnectionStatusProvider = StateNotifierProvider<SquidConnectionStatusNotifier, d.ConnectionStatus>((ref) {
  return SquidConnectionStatusNotifier();
});

/// Provides the global, initialized instance of [d.Durt].
///
/// Throws an exception if [d.Durt.i] is accessed before initialization.
/// This is the root provider from which all other Durt service providers are derived.
final durtProvider = Provider<d.Durt>((ref) {
  return d.Durt.i;
});

/// Provides the [d.WalletService] for managing wallets, safes, and cryptographic keys.
final walletServiceProvider = Provider<d.WalletService>((ref) {
  return ref.watch(durtProvider).wallets;
});

/// Provides the [d.DuniterStorageService] for cached access to on-chain data like
/// balances, identity status, etc.
final storageServiceProvider = Provider<d.DuniterStorageService>((ref) {
  return ref.watch(durtProvider).storage;
});

/// Provides the [d.DuniterService] for interacting with Duniter-specific pallets
/// and crafting transactions like `pay`, `renewMembership`, etc.
final duniterServiceProvider = Provider<d.DuniterService>((ref) {
  return ref.watch(durtProvider).duniter;
});

/// Provides the [d.Gdev] client, the auto-generated interface for interacting
/// with the Duniter v2 Substrate runtime (querying storage, etc.).
final gdevProvider = Provider<d.Gdev>((ref) {
  return ref.watch(durtProvider).gdev;
});

/// Provides the low-level Polkadart [d.Provider] for sending raw JSON-RPC requests.
///
/// Note: This is aliased as `polkadart.Provider` to avoid conflicts with Riverpod's `Provider`.
final polkadartProvider = Provider<d.Provider>((ref) {
  return ref.watch(durtProvider).polkadart;
});

/// Provides the Substrate [d.AuthorApi] for submitting extrinsics.
final authorApiProvider = Provider<d.AuthorApi>((ref) {
  return ref.watch(durtProvider).authorApi;
});

/// Provides the Substrate [d.StateApi] for querying the node's state.
final stateApiProvider = Provider<d.StateApi>((ref) {
  return ref.watch(durtProvider).stateApi;
});

/// Provides the [d.Keyring] for managing key pairs from mnemonics.
final keyringProvider = Provider<d.Keyring>((ref) {
  return ref.watch(durtProvider).keyring;
});

/// Provides the current [d.Networks] enum value the app is connected to (e.g., gdev, gtest).
final networkProvider = Provider<d.Networks>((ref) {
  return ref.watch(durtProvider).network;
});

/// Provides the [d.SquidService] for querying the GraphQL indexer.
final squidServiceProvider = Provider<d.SquidService>((ref) {
  return ref.watch(durtProvider).squid;
});

/// Provides the current Squid endpoint as a string.
/// This can be used to rebuild widgets when the endpoint changes.
final squidEndpointProvider = Provider<String>((ref) {
  return d.Networks.squidEndpoint;
});

/// Provides loading state for Squid endpoint operations.
final squidLoadingProvider = StateProvider<bool>((ref) => false);

/// Provides a method to test a Squid endpoint and update loading state.
final squidEndpointTesterProvider = Provider<Future<bool> Function(String)>((ref) {
  return (String endpoint) async {
    // Set loading state
    ref.read(squidLoadingProvider.notifier).state = true;

    try {
      // Test the endpoint
      final result = await d.SquidService.testEndpoint(endpoint);
      return result;
    } finally {
      // Clear loading state
      ref.read(squidLoadingProvider.notifier).state = false;
    }
  };
});

/// Provides the [d.Utils] service for utility functions.
final utilsProvider = Provider<d.Utils>((ref) {
  return ref.watch(durtProvider).utils;
});

/// Provides the [d.DuniterConnectionService] to manage connection status and endpoints.
final duniterConnectionProvider = Provider<d.DuniterConnectionService>((ref) {
  return ref.watch(durtProvider).duniterConnection;
});

/// Provides the ObjectBox [Box] for the [d.Config] entity.
final configBoxProvider = Provider<Box<d.Config>>((ref) {
  return ref.watch(durtProvider).configBox;
});

/// Provides the genesis blockchain time for transaction date calculations.
final genesisTimeProvider = FutureProvider<DateTime>((ref) async {
  return await d.SquidService.client.getGenesisBlockchainTime();
});

/// Provides the previous address for identity migration detection.
final previousAddressProvider = FutureProvider.family<String?, String>((ref, address) async {
  final storageService = ref.watch(storageServiceProvider);
  final oldOwnerKey = await storageService.getOldOwnerKey(address);
  return oldOwnerKey?.oldAddress;
});

/// Provides the name of an identity by address.
/// Returns null if the address has no identity or if network is unavailable.
final identityNameProvider = FutureProvider.family<String?, String>((ref, address) async {
  // Check if we have Squid connection specifically (required for identity queries)
  final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
  if (squidConnectionStatus != d.ConnectionStatus.connected) {
    return null; // Return null if Squid is not connected
  }

  try {
    final identityName = await d.SquidService.client.getIdentityName(address);

    // Cache the result
    final squidService = ref.read(squidServiceProvider);
    squidService.walletNameIndexer[address] = identityName;

    return identityName;
  } catch (e) {
    // If there's an error, return null (address might not have an identity)
    return null;
  }
});

/// Provides a synchronous access to the cached identity name.
/// Returns null if not cached yet.
final cachedIdentityNameProvider = Provider.family<String?, String>((ref, address) {
  final squidService = ref.watch(squidServiceProvider);
  return squidService.walletNameIndexer[address];
});

/// Provides identity search results for a given search term.
/// Returns empty list if network is unavailable.
final searchIdentityProvider = FutureProvider.family<List<d.IdentitySuggestion>, String>((ref, searchTerm) async {
  // Check if we have Squid connection specifically (required for identity search)
  final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
  if (squidConnectionStatus != d.ConnectionStatus.connected) {
    return []; // Return empty list if Squid is not connected
  }

  try {
    final results = await d.SquidService.client.searchAddressByName(searchTerm);
    return results;
  } catch (e) {
    // If there's an error, return empty list
    return [];
  }
});
