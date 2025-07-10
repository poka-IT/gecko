// ignore_for_file: avoid_print

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

        // Update home message based on Duniter status
        switch (status) {
          case d.ConnectionStatus.connecting:
            homeProvider.changeMessage("connecting".tr());
            break;
          case d.ConnectionStatus.connected:
            homeProvider.changeMessage("connected".tr(), true);
            break;
          case d.ConnectionStatus.error:
            homeProvider.changeMessage("networkGenesisError".tr());
            break;
          case d.ConnectionStatus.disconnected:
            homeProvider.changeMessage("networkConnectionError".tr());
            break;
        }

        _updateCombinedStatus();
      });

      // Listen to Squid connection status
      _squidSubscription = durt.squidConnectionStatusStream.listen((status) {
        _squidStatus = status;

        switch (status) {
          case d.ConnectionStatus.connected:
            homeProvider.changeMessage("nodeAndIndexerSynced".tr(), true);
            break;
          case d.ConnectionStatus.disconnected:
            homeProvider.changeMessage("noValidIndexerFound".tr());
            break;
          case d.ConnectionStatus.error:
            homeProvider.changeMessage("indexerError".tr());
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
      state = d.ConnectionStatus.error;
      homeProvider.changeMessage("networkConnectionError".tr());
    }
  }

  void _updateCombinedStatus() {
    // Priority order: connected > connecting > error > disconnected
    // We consider the app connected if either Duniter OR Squid is connected
    // We consider the app in error state if either has an error (genesis validation, etc.)

    d.ConnectionStatus newStatus;

    if (_duniterStatus == d.ConnectionStatus.connected || _squidStatus == d.ConnectionStatus.connected) {
      newStatus = d.ConnectionStatus.connected;
    } else if (_duniterStatus == d.ConnectionStatus.error || _squidStatus == d.ConnectionStatus.error) {
      newStatus = d.ConnectionStatus.error;
    } else if (_duniterStatus == d.ConnectionStatus.connecting || _squidStatus == d.ConnectionStatus.connecting) {
      newStatus = d.ConnectionStatus.connecting;
    } else {
      newStatus = d.ConnectionStatus.disconnected;
    }

    if (newStatus != state) {
      state = newStatus;
    }
  }

  /// Note: Stream reinitialization is no longer needed due to proxy streams

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

/// Global container for accessing providers from anywhere
final globalProviderContainer = ProviderContainer();

/// Note: Stream reinitialization is no longer needed since durt2 uses proxy streams
/// that remain stable across network switches

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
final blockchainProvider = Provider<d.Duniter>((ref) {
  return ref.watch(durtProvider).blockchain;
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

/// Provides the [d.DurtKeyring] for managing key pairs from mnemonics.
final keyringProvider = Provider<d.DurtKeyring>((ref) {
  return ref.watch(durtProvider).keyring;
});

/// Provides the current [d.Networks] enum value the app is connected to (e.g., gdev, gtest, g1).
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
      // Ensure the endpoint has the correct format with path
      String testEndpoint = endpoint;

      // If the endpoint doesn't have a path, add the default v1beta1/relay path
      if (!testEndpoint.contains('/v1beta1/relay') && !testEndpoint.contains('/v1/graphql')) {
        if (testEndpoint.startsWith('wss://') || testEndpoint.startsWith('ws://')) {
          testEndpoint = '$testEndpoint/v1beta1/relay';
        } else if (testEndpoint.startsWith('https://') || testEndpoint.startsWith('http://')) {
          testEndpoint = '$testEndpoint/v1beta1/relay';
        } else {
          // Add protocol and path
          testEndpoint = 'wss://$testEndpoint/v1beta1/relay';
        }
      }

      // Test the endpoint
      final result = await d.SquidService.testEndpoint(testEndpoint);
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

/// Provides real-time wallet balance stream for a given address.
/// This uses Durt2's subscribeBalance to get live updates when balance changes.
/// The stream automatically starts when the first listener is added and stops when the last one is removed.
final balanceStreamProvider = StreamProvider.family.autoDispose<d.WalletBalance, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the balance stream
  late StreamController<d.WalletBalance> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.WalletBalance>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial balance first
        final initialBalance = await storageService.getBalance(address);

        if (!controller.isClosed) {
          controller.add(initialBalance);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeBalance(address, (newBalance) {
          if (!controller.isClosed) {
            controller.add(newBalance);
          }
        });
      } catch (e) {
        log.e('Error creating balance subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Balance stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed
  ref.onDispose(() async {
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Provides persistent real-time wallet balance stream for owned wallets.
/// This provider does NOT auto-dispose, keeping owned wallet balances always up-to-date.
/// Use this for: wallet home, wallet options, main wallet screens.
final persistentBalanceStreamProvider = StreamProvider.family<d.WalletBalance, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the balance stream
  late StreamController<d.WalletBalance> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.WalletBalance>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial balance first
        final initialBalance = await storageService.getBalance(address);

        if (!controller.isClosed) {
          controller.add(initialBalance);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeBalance(address, (newBalance) {
          if (!controller.isClosed) {
            controller.add(newBalance);
          }
        });
      } catch (e) {
        log.e('Error creating persistent balance subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Persistent balance stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed (only when app closes)
  ref.onDispose(() async {
    print('🗑️ Persistent balance stream disposed for $address');
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Provides real-time certification data stream for a given address.
/// This uses Durt2's subscribeToCertsCounter to get live updates when certification data changes.
/// The stream automatically starts when the first listener is added and stops when the last one is removed.
final certificationStreamProvider = StreamProvider.family.autoDispose<d.CertificationData, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the certification stream
  late StreamController<d.CertificationData> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.CertificationData>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial certification data first
        final initialCertData = await storageService.getCertsCounter(address);

        if (!controller.isClosed) {
          controller.add(initialCertData);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeToCertsCounter(address, (newCertData) {
          if (!controller.isClosed) {
            controller.add(newCertData);
          }
        });
      } catch (e) {
        log.e('Error creating certification subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Certification stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed
  ref.onDispose(() async {
    print('🗑️ Certification stream disposed for $address');
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Provides persistent real-time certification data stream for owned wallets.
/// This provider does NOT auto-dispose, keeping owned wallet certifications always up-to-date.
/// Use this for: owned wallet screens where certifications should stay subscribed.
final persistentCertificationStreamProvider = StreamProvider.family<d.CertificationData, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the certification stream
  late StreamController<d.CertificationData> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.CertificationData>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial certification data first
        final initialCertData = await storageService.getCertsCounter(address);

        if (!controller.isClosed) {
          controller.add(initialCertData);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeToCertsCounter(address, (newCertData) {
          if (!controller.isClosed) {
            controller.add(newCertData);
          }
        });
      } catch (e) {
        log.e('Error creating persistent certification subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Persistent certification stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed (only when app closes)
  ref.onDispose(() async {
    print('🗑️ Persistent certification stream disposed for $address');
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Smart certification provider that automatically chooses between persistent and auto-dispose
/// based on whether the address belongs to the user (found in wallet box).
/// For owned wallets: uses persistent subscription (stays active)
/// For other wallets: uses auto-dispose subscription (cleans up when widget disappears)
final smartCertificationStreamProvider = Provider.family.autoDispose<AsyncValue<d.CertificationData>, String>((
  ref,
  address,
) {
  final walletService = ref.watch(walletServiceProvider);

  // Check if this address belongs to the user using the new utility method
  final isOwnedWallet = walletService.isOwnedWallet(address);

  // Use appropriate provider based on ownership
  if (isOwnedWallet) {
    return ref.watch(persistentCertificationStreamProvider(address));
  } else {
    return ref.watch(certificationStreamProvider(address));
  }
});

/// Provides real-time identity status stream for a given address.
/// This uses Durt2's subscribeToIdtyStatus to get live updates when identity status changes.
/// The stream automatically starts when the first listener is added and stops when the last one is removed.
final idtyStatusStreamProvider = StreamProvider.family.autoDispose<d.IdtyStatus, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the identity status stream
  late StreamController<d.IdtyStatus> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.IdtyStatus>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial identity status first
        final initialStatus = await storageService.getIdtyStatus(address);

        if (!controller.isClosed) {
          controller.add(initialStatus);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeToIdtyStatus(address, (newStatus) {
          if (!controller.isClosed) {
            controller.add(newStatus);
          }
        });
      } catch (e) {
        log.e('Error creating identity status subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Identity status stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed
  ref.onDispose(() async {
    print('🗑️ Identity status stream disposed for $address');
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Provides persistent real-time identity status stream for owned wallets.
/// This provider does NOT auto-dispose, keeping owned wallet identity status always up-to-date.
/// Use this for: owned wallet screens where identity status should stay subscribed.
final persistentIdtyStatusStreamProvider = StreamProvider.family<d.IdtyStatus, String>((ref, address) {
  final storageService = ref.watch(storageServiceProvider);

  // Create a StreamController to manage the identity status stream
  late StreamController<d.IdtyStatus> controller;
  StreamSubscription<d.StorageChangeSet>? subscription;

  controller = StreamController<d.IdtyStatus>(
    onListen: () async {
      // When someone starts listening, create the subscription
      try {
        // Get initial identity status first
        final initialStatus = await storageService.getIdtyStatus(address);

        if (!controller.isClosed) {
          controller.add(initialStatus);
        }

        // Then subscribe to real-time updates
        subscription = await storageService.subscribeToIdtyStatus(address, (newStatus) {
          if (!controller.isClosed) {
            controller.add(newStatus);
          }
        });
      } catch (e) {
        log.e('Error creating persistent identity status subscription for $address: $e');
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    },
    onCancel: () async {
      // When no one is listening anymore, clean up the subscription
      print('🗑️ Persistent identity status stream cancelled for $address');
      await subscription?.cancel();
      subscription = null;
    },
  );

  // Clean up when the provider is disposed (only when app closes)
  ref.onDispose(() async {
    print('🗑️ Persistent identity status stream disposed for $address');
    await subscription?.cancel();
    await controller.close();
  });

  return controller.stream;
});

/// Smart identity status provider that automatically chooses between persistent and auto-dispose
/// based on whether the address belongs to the user (found in wallet box).
/// For owned wallets: uses persistent subscription (stays active)
/// For other wallets: uses auto-dispose subscription (cleans up when widget disappears)
final smartIdtyStatusStreamProvider = Provider.family.autoDispose<AsyncValue<d.IdtyStatus>, String>((ref, address) {
  final walletService = ref.watch(walletServiceProvider);

  // Check if this address belongs to the user using the new utility method
  final isOwnedWallet = walletService.isOwnedWallet(address);

  // Use appropriate provider based on ownership
  if (isOwnedWallet) {
    return ref.watch(persistentIdtyStatusStreamProvider(address));
  } else {
    return ref.watch(idtyStatusStreamProvider(address));
  }
});

/// Smart balance provider that automatically chooses between persistent and auto-dispose
/// based on whether the address belongs to the user (found in wallet box).
/// For owned wallets: uses persistent subscription (stays active)
/// For other wallets: uses auto-dispose subscription (cleans up when widget disappears)
final smartBalanceStreamProvider = Provider.family.autoDispose<AsyncValue<d.WalletBalance>, String>((ref, address) {
  final walletService = ref.watch(walletServiceProvider);

  // Check if this address belongs to the user using the new utility method
  final isOwnedWallet = walletService.isOwnedWallet(address);

  // Use appropriate provider based on ownership
  if (isOwnedWallet) {
    return ref.watch(persistentBalanceStreamProvider(address));
  } else {
    return ref.watch(balanceStreamProvider(address));
  }
});
