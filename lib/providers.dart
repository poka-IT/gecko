// ignore_for_file: avoid_print

import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart' show Box;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/home.dart';
import 'package:gecko/models/migration_data.dart';
import 'dart:async';
import 'package:provider/provider.dart' as old_provider;
import 'dart:typed_data';

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
            homeProvider.changeMessage("connected".tr(args: [durt.network.displayName]), true);
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
            // homeProvider.changeMessage("nodeAndIndexerSynced".tr(), true);
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

/// Provides the [d.DatapodService] for querying the Datapod GraphQL API.
final datapodServiceProvider = Provider<d.DatapodService>((ref) {
  return ref.watch(durtProvider).datapod;
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
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getGenesisBlockchainTime();
});

/// Provides the migration data for identity migration detection.
final migrationDataProvider = FutureProvider.family<d.OldOwnerKey?, String>((ref, address) async {
  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getOldOwnerKey(address);
});

/// Provides migration data for identities that migrated FROM this address using Squid
final migrationFromDataProvider = FutureProvider.family<MigrationData?, String>((ref, address) async {
  try {
    final squidService = d.SquidService.client;
    final migrations = await squidService.getIdentityMigrations(address);

    if (migrations?.migrationFrom == null) {
      return null;
    }

    final genesisTime = await ref.watch(genesisTimeProvider.future);
    return await MigrationData.fromSquidMigrationFromNode(migrations!.migrationFrom!, genesisTime);
  } catch (e) {
    return null;
  }
});

/// Provides migration data for identities that migrated TO this address using Squid
final migrationToDataProvider = FutureProvider.family<MigrationData?, String>((ref, address) async {
  try {
    final squidService = d.SquidService.client;
    final migrations = await squidService.getIdentityMigrations(address);

    if (migrations?.migrationTo == null) {
      return null;
    }

    final genesisTime = await ref.watch(genesisTimeProvider.future);
    return await MigrationData.fromSquidMigrationToNode(migrations!.migrationTo!, genesisTime);
  } catch (e) {
    return null;
  }
});

/// Provides the previous address for identity migration detection.
/// This is kept for backward compatibility but migrationFromDataProvider should be preferred.
final previousAddressProvider = FutureProvider.family<String?, String>((ref, address) async {
  final migrationData = await ref.watch(migrationDataProvider(address).future);
  return migrationData?.oldAddress;
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

/// Provides real-time identity name stream for a given address.
/// This uses a real GraphQL subscription to detect identity name changes in real-time.
/// The stream automatically starts when the first listener is added and stops when the last one is removed.
final identityNameStreamProvider = StreamProvider.family.autoDispose<String?, String>((ref, address) {
  // Check if Squid is connected
  final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
  if (squidConnectionStatus != d.ConnectionStatus.connected) {
    // Return a stream that emits null if not connected
    return Stream.value(null);
  }

  // Use the GraphQL subscription from SquidService
  return d.SquidService.client.subscribeIdentityName(address).handleError((error) {
    log.e('Identity name subscription error for $address: $error');
    // Return null on error instead of breaking the stream
  });
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
    // For owned wallets: use persistent stream to keep status up-to-date
    return ref.watch(persistentIdtyStatusStreamProvider(address));
  } else {
    // For other wallets: use auto-dispose stream
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

/// Cached provider for checking if an account has consumers
/// Uses smart caching to avoid repeated expensive storage calls
final hasAccountConsumersProvider = FutureProvider.family<bool, String>((ref, address) async {
  final storageService = ref.watch(storageServiceProvider);

  // Check connection status first - if not connected, return false (safe default)
  final connectionStatus = ref.watch(connectionStatusProvider);
  if (connectionStatus != d.ConnectionStatus.connected) {
    return false;
  }

  try {
    final hasConsumers = await storageService.hasAccountConsumers(address);
    return hasConsumers;
  } catch (e) {
    log.e('Error checking account consumers for $address: $e');
    // Return false on error (safe default for deletion checks)
    return false;
  }
});

/// Smart cached provider for account consumers that handles connection changes
/// This provider caches results and invalidates appropriately
class AccountConsumersNotifier extends FamilyAsyncNotifier<bool, String> {
  bool? _cachedResult;
  Timer? _cacheTimer;

  @override
  Future<bool> build(String address) async {
    // Clear cache timer when rebuilding
    _cacheTimer?.cancel();
    _cacheTimer = null;

    // Clean up timer when provider is disposed
    ref.onDispose(() {
      _cacheTimer?.cancel();
    });

    final storageService = ref.watch(storageServiceProvider);

    // Check connection status first
    final connectionStatus = ref.watch(connectionStatusProvider);
    if (connectionStatus != d.ConnectionStatus.connected) {
      _cachedResult = false;
      return false;
    }

    // If we have a recent cached result, use it
    if (_cachedResult != null) {
      // Set timer to invalidate cache after 30 seconds
      _cacheTimer = Timer(const Duration(seconds: 30), () {
        _cachedResult = null;
        ref.invalidateSelf();
      });
      return _cachedResult!;
    }

    try {
      final hasConsumers = await storageService.hasAccountConsumers(address);
      _cachedResult = hasConsumers;

      // Cache result for 30 seconds
      _cacheTimer = Timer(const Duration(seconds: 30), () {
        _cachedResult = null;
      });

      return hasConsumers;
    } catch (e) {
      log.e('Error checking account consumers for $address: $e');
      _cachedResult = false;
      return false;
    }
  }
}

/// Smart account consumers provider with intelligent caching
final smartAccountConsumersProvider = AsyncNotifierProvider.family<AccountConsumersNotifier, bool, String>(
  () => AccountConsumersNotifier(),
);

/// Hybrid identity status provider using StateNotifier approach
/// This bypasses the closed stream issue by using direct storage calls and forced refreshes
/// For existing identities: uses normal streams, for non-existing: uses polling
class HybridIdtyStatusNotifier extends FamilyAsyncNotifier<d.IdtyStatus, String> {
  Timer? _refreshTimer;
  StreamSubscription<d.StorageChangeSet>? _idtySubscription;

  @override
  Future<d.IdtyStatus> build(String address) async {
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _refreshTimer?.cancel();
      _idtySubscription?.cancel();
    });

    // Initial status fetch
    final storageService = ref.watch(storageServiceProvider);
    final status = await storageService.getIdtyStatus(address);

    // Setup appropriate listening mechanism based on current status
    if (status == d.IdtyStatus.none) {
      // If no identity, set up polling to detect identity creation
      _startPeriodicRefresh(address);
    } else {
      // If identity exists, use normal stream subscription for real-time updates
      _startIdentitySubscription(address);
    }

    return status;
  }

  void _startPeriodicRefresh(String address) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        final storageService = ref.read(storageServiceProvider);
        final newStatus = await storageService.getIdtyStatus(address);

        if (newStatus != state.value) {
          state = AsyncValue.data(newStatus);

          // If identity was created, stop polling and start stream subscription
          if (newStatus != d.IdtyStatus.none) {
            timer.cancel();
            _refreshTimer = null;
            _startIdentitySubscription(address);
          }
        }
      } catch (e) {
        // Continue trying on error
      }
    });
  }

  void _startIdentitySubscription(String address) async {
    _idtySubscription?.cancel();
    try {
      final storageService = ref.read(storageServiceProvider);
      _idtySubscription = await storageService.subscribeToIdtyStatus(address, (newStatus) {
        if (newStatus != state.value) {
          state = AsyncValue.data(newStatus);

          // If identity disappears, switch back to polling
          if (newStatus == d.IdtyStatus.none) {
            _idtySubscription?.cancel();
            _idtySubscription = null;
            _startPeriodicRefresh(address);
          }
        }
      });
    } catch (e) {
      log.e('Error starting identity subscription for $address: $e');
      // Fallback to manual refresh only
    }
  }

  void forceRefresh() async {
    final address = arg;
    try {
      final storageService = ref.read(storageServiceProvider);
      final newStatus = await storageService.getIdtyStatus(address);
      final previousStatus = state.value;

      state = AsyncValue.data(newStatus);

      // Handle transition between different listening modes
      if (previousStatus == d.IdtyStatus.none && newStatus != d.IdtyStatus.none) {
        // Transition from no identity to having identity: switch to stream
        _refreshTimer?.cancel();
        _refreshTimer = null;
        _startIdentitySubscription(address);
      } else if (previousStatus != d.IdtyStatus.none && newStatus == d.IdtyStatus.none) {
        // Transition from having identity to no identity: switch to polling
        _idtySubscription?.cancel();
        _idtySubscription = null;
        _startPeriodicRefresh(address);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Cleanup is handled in build() with ref.onDispose()
}

final hybridIdtyStatusProvider = AsyncNotifierProvider.family<HybridIdtyStatusNotifier, d.IdtyStatus, String>(
  () => HybridIdtyStatusNotifier(),
);

/// Stable identity wallet notifier that caches results and only rebuilds when necessary
/// This prevents the UI reload spam during connection changes
class IdtyWalletNotifier extends AsyncNotifier<d.WalletEntity?> {
  d.WalletEntity? _cachedResult;
  List<String> _cachedWalletAddresses = [];

  @override
  Future<d.WalletEntity?> build() async {
    // Watch wallet service but don't rebuild on connection changes
    final walletService = ref.watch(walletServiceProvider);
    final storageService = ref.watch(storageServiceProvider);

    final allSafes = walletService.safeBox.getAll();
    if (allSafes.isEmpty) {
      _cachedResult = null;
      _cachedWalletAddresses = [];
      return null;
    }

    final defaultSafeNumber = walletService.defaultSafeBoxNumber;
    final defaultSafe = allSafes.firstWhere(
      (safe) => safe.number == defaultSafeNumber,
      orElse: () => allSafes.first, // Fallback to first safe if default not found
    );

    final wallets = defaultSafe.wallets.toList();
    if (wallets.isEmpty) {
      _cachedResult = null;
      _cachedWalletAddresses = [];
      return null;
    }

    // Check if wallet list changed - only rebuild if wallets were added/removed
    final currentAddresses = wallets.map((w) => w.address).toList()..sort();
    if (_cachedResult != null &&
        _cachedWalletAddresses.length == currentAddresses.length &&
        _cachedWalletAddresses.every((addr) => currentAddresses.contains(addr))) {
      // Wallet list unchanged, preload streams without rebuilding UI
      _preloadStreamsQuietly(wallets);
      return _cachedResult;
    }

    _cachedWalletAddresses = currentAddresses;

    // Get identity status for all wallets in parallel
    final statusFutures = wallets.map((wallet) async {
      try {
        final status = await storageService.getIdtyStatus(wallet.address);
        return MapEntry(wallet, status);
      } catch (e) {
        return MapEntry(wallet, d.IdtyStatus.unknown);
      }
    });

    final walletStatusList = await Future.wait(statusFutures);

    // Find wallet with highest priority identity
    d.WalletEntity? bestWallet;
    int bestPriority = 0; // 0 = no identity, 1 = any identity, 2 = confirmed, 3 = validated

    for (final entry in walletStatusList) {
      final wallet = entry.key;
      final status = entry.value;

      int priority = switch (status) {
        d.IdtyStatus.validated => 3, // Member - highest priority
        d.IdtyStatus.confirmed => 2, // Confirmed identity
        d.IdtyStatus.none || d.IdtyStatus.unknown => 0, // No identity
        _ => 1, // Any other identity status
      };

      if (priority > bestPriority) {
        bestWallet = wallet;
        bestPriority = priority;

        // Early exit if we found a member (highest priority)
        if (priority == 3) break;
      }
    }

    _cachedResult = bestWallet;

    // Preload streams for the selected wallet
    if (bestWallet != null) {
      _preloadStreamsQuietly(wallets);
    }

    return bestWallet;
  }

  /// Preload streams without triggering UI rebuilds
  void _preloadStreamsQuietly(List<d.WalletEntity> wallets) {
    // Use a timer to avoid immediate rebuilds
    Timer.run(() {
      for (final wallet in wallets) {
        try {
          // These calls preload the providers without causing immediate rebuilds
          ref.read(smartBalanceStreamProvider(wallet.address));
          ref.read(identityNameProvider(wallet.address));
          ref.read(hybridIdtyStatusProvider(wallet.address));
          ref.read(smartCertificationStreamProvider(wallet.address));
          ref.read(smartAccountConsumersProvider(wallet.address));
        } catch (e) {
          // Ignore preload errors
        }
      }
    });
  }

  /// Force refresh when needed (called externally when wallet status changes)
  void forceRefresh() {
    _cachedResult = null;
    _cachedWalletAddresses = [];
    ref.invalidateSelf();
  }
}

/// Stable async provider to get the identity wallet (member or identity holder)
/// Uses caching to prevent UI reload spam during connection changes
final idtyWalletAsyncProvider = AsyncNotifierProvider<IdtyWalletNotifier, d.WalletEntity?>(() => IdtyWalletNotifier());

/// Async provider to get wallets without identity
final walletsWithoutIdtyAsyncProvider = FutureProvider<List<d.WalletEntity>>((ref) async {
  final idtyWallet = await ref.watch(idtyWalletAsyncProvider.future);
  final walletService = ref.watch(walletServiceProvider);

  final allSafes = walletService.safeBox.getAll();
  if (allSafes.isEmpty) return [];

  final defaultSafeNumber = walletService.defaultSafeBoxNumber;
  final defaultSafe = allSafes.firstWhere(
    (safe) => safe.number == defaultSafeNumber,
    orElse: () => allSafes.first, // Fallback to first safe if default not found
  );

  final allWallets = defaultSafe.wallets.toList();

  return allWallets.where((w) => w.address != idtyWallet?.address).toList();
});

/// State provider for selected certification wallet (development mode only)
/// This allows developers to choose which identity wallet to use for certifications
/// when using the test mnemonic with multiple identity wallets
final selectedCertificationWalletProvider = StateProvider<String?>((ref) => null);

/// Provider for certification state between effective wallet and target address
/// Automatically updates when balance or certifications change, with caching to avoid UI jumps
final certStateProvider = AsyncNotifierProvider.family<CertStateNotifier, d.CertState?, String>(
  () => CertStateNotifier(),
);

/// Notifier that caches cert state and updates smoothly without UI jumps
class CertStateNotifier extends FamilyAsyncNotifier<d.CertState?, String> {
  @override
  Future<d.CertState?> build(String toAddress) async {
    // Watch streams for auto-updates but keep previous state during loading
    ref.listen(smartBalanceStreamProvider(toAddress), (previous, next) {
      if (!next.isLoading && next.hasValue) {
        _refreshCertState();
      }
    });

    final effectiveWallet = await ref.watch(effectiveCertificationWalletProvider.future);
    if (effectiveWallet == null) return null;

    ref.listen(smartCertificationStreamProvider(effectiveWallet.address), (previous, next) {
      if (!next.isLoading && next.hasValue) {
        _refreshCertState();
      }
    });

    return await _getCertState(effectiveWallet.address, toAddress);
  }

  /// Refresh cert state without clearing the previous value
  void _refreshCertState() async {
    final effectiveWallet = await ref.read(effectiveCertificationWalletProvider.future);
    if (effectiveWallet == null) return;

    // Update state smoothly - keep previous value visible during loading
    final newCertState = await _getCertState(effectiveWallet.address, arg);
    state = AsyncValue.data(newCertState);
  }

  /// Get cert state from storage
  Future<d.CertState?> _getCertState(String fromAddress, String toAddress) async {
    return await ref.read(storageServiceProvider).getCertState(fromAddress: fromAddress, toAddress: toAddress);
  }
}

/// Provider to get all wallets with identity status for certification dropdown
final identityWalletsAsyncProvider = FutureProvider<List<d.WalletEntity>>((ref) async {
  final walletService = ref.watch(walletServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  final allSafes = walletService.safeBox.getAll();
  if (allSafes.isEmpty) return [];

  final defaultSafeNumber = walletService.defaultSafeBoxNumber;
  final defaultSafe = allSafes.firstWhere(
    (safe) => safe.number == defaultSafeNumber,
    orElse: () => allSafes.first, // Fallback to first safe if default not found
  );

  final wallets = defaultSafe.wallets.toList();
  if (wallets.isEmpty) return [];

  final identityWalletsWithStatus = <({d.WalletEntity wallet, d.IdtyStatus status})>[];

  // Check each wallet for identity status and collect those with identities
  for (final wallet in wallets) {
    final status = await storageService.getIdtyStatus(wallet.address);
    if (status != d.IdtyStatus.none && status != d.IdtyStatus.unknown) {
      identityWalletsWithStatus.add((wallet: wallet, status: status));
    }
  }

  // Sort by priority: validated > confirmed > others
  identityWalletsWithStatus.sort((a, b) {
    // Priority order: validated (3) > confirmed (2) > others (1)
    final priorityA = a.status == d.IdtyStatus.validated
        ? 3
        : a.status == d.IdtyStatus.confirmed
        ? 2
        : 1;
    final priorityB = b.status == d.IdtyStatus.validated
        ? 3
        : b.status == d.IdtyStatus.confirmed
        ? 2
        : 1;

    return priorityB.compareTo(priorityA); // Highest priority first
  });

  return identityWalletsWithStatus.map((e) => e.wallet).toList();
});

/// Provider that returns the effective certification wallet:
/// - If a specific wallet is selected in dev mode, use that
/// - Otherwise, use the automatic identity wallet selection
final effectiveCertificationWalletProvider = FutureProvider<d.WalletEntity?>((ref) async {
  final selectedAddress = ref.watch(selectedCertificationWalletProvider);

  // If a specific wallet is selected (dev mode), use that
  if (selectedAddress != null) {
    final walletService = ref.watch(walletServiceProvider);
    final selectedWallet = walletService.walletBox.getAll().where((w) => w.address == selectedAddress).firstOrNull;
    if (selectedWallet != null) {
      return selectedWallet;
    }
  }

  // Otherwise, use the automatic selection
  return ref.watch(idtyWalletAsyncProvider.future);
});

/// Avatar cache provider using Riverpod
final avatarCacheProvider = StateNotifierProvider<AvatarCacheNotifier, Map<String, Uint8List?>>((ref) {
  return AvatarCacheNotifier(ref);
});

/// Provider to get avatar for a specific address
final avatarProvider = FutureProvider.family<Uint8List?, String>((ref, address) async {
  final avatarCache = ref.read(avatarCacheProvider.notifier);
  return await avatarCache.getAvatar(address);
});

/// Avatar cache notifier that manages avatar downloading and caching
class AvatarCacheNotifier extends StateNotifier<Map<String, Uint8List?>> {
  final Ref ref;

  AvatarCacheNotifier(this.ref) : super({});

  /// Get avatar for an address, with caching
  Future<Uint8List?> getAvatar(String address) async {
    try {
      // Check if already cached
      if (state.containsKey(address)) {
        return state[address];
      }

      // Convert address to SS58 prefix 42 for Datapod
      final ss5842Address = d.Address.decode(address).encode(prefix: 42);

      // Get avatar from Datapod service
      final datapodService = ref.read(datapodServiceProvider);
      final avatarBytes = await datapodService.getAvatar(ss5842Address);

      // Cache the result (even if null)
      state = {...state, address: avatarBytes};

      return avatarBytes;
    } catch (e) {
      log.e('Error getting avatar for $address: $e');
      // Cache null result to avoid retrying immediately
      state = {...state, address: null};
      return null;
    }
  }

  /// Clear cache for a specific address
  void clearAvatar(String address) {
    state = Map.from(state)..remove(address);
  }

  /// Clear all cached avatars
  void clearAll() {
    state = {};
  }
}
