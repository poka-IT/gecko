// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/block_height_provider.dart';

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

/// Smart balance provider that automatically chooses between persistent and auto-dispose
/// based on whether the address belongs to the user (found in wallet box).
/// For owned wallets: uses persistent subscription (stays active)
/// For other wallets: uses auto-dispose subscription (cleans up when widget disappears)
final smartBalanceStreamProvider = Provider.family.autoDispose<AsyncValue<d.WalletBalance>, String>((ref, address) {
  final walletsState = ref.watch(walletsListProvider);
  final isCurrentSafeWallet = walletsState.wallets.any((w) => w.address == address);

  // Use appropriate provider based on ownership in current safe
  if (isCurrentSafeWallet) {
    return ref.watch(persistentBalanceStreamProvider(address));
  } else {
    return ref.watch(balanceStreamProvider(address));
  }
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
  final walletsState = ref.watch(walletsListProvider);
  final isCurrentSafeWallet = walletsState.wallets.any((w) => w.address == address);

  // Use appropriate provider based on ownership in current safe
  if (isCurrentSafeWallet) {
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
  final walletsState = ref.watch(walletsListProvider);
  final isCurrentSafeWallet = walletsState.wallets.any((w) => w.address == address);

  // Use appropriate provider based on ownership in current safe
  if (isCurrentSafeWallet) {
    return ref.watch(persistentIdtyStatusStreamProvider(address));
  } else {
    return ref.watch(idtyStatusStreamProvider(address));
  }
});

/// Smart cached provider for account consumers that handles connection changes
/// This provider caches results and invalidates appropriately
class AccountConsumersNotifier extends AsyncNotifier<bool> {
  AccountConsumersNotifier(this.arg);
  final String arg;

  bool? _cachedResult;
  Timer? _cacheTimer;

  @override
  Future<bool> build() async {
    final address = arg;
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
  AccountConsumersNotifier.new,
);

/// Hybrid identity status provider using StateNotifier approach
/// This bypasses the closed stream issue by using direct storage calls and forced refreshes
/// For existing identities: uses normal streams, for non-existing: uses polling
class HybridIdtyStatusNotifier extends AsyncNotifier<d.IdtyStatus> {
  HybridIdtyStatusNotifier(this.arg);
  final String arg;

  StreamSubscription<d.StorageChangeSet>? _idtySubscription;
  bool _listeningToBlockHeight = false;

  @override
  Future<d.IdtyStatus> build() async {
    final address = arg;
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _idtySubscription?.cancel();
    });

    // Initial status fetch
    final storageService = ref.watch(storageServiceProvider);
    final status = await storageService.getIdtyStatus(address);

    // Setup appropriate listening mechanism based on current status
    if (status == d.IdtyStatus.none) {
      // If no identity, listen to block height to detect identity creation
      _startBlockHeightListener(address);
    } else {
      // If identity exists, use normal stream subscription for real-time updates
      _startIdentitySubscription(address);
    }

    return status;
  }

  /// Listen to new blocks to check for identity creation (replaces Timer.periodic(5s))
  void _startBlockHeightListener(String address) {
    if (_listeningToBlockHeight) return;
    _listeningToBlockHeight = true;
    ref.listen(blockHeightProvider, (previous, next) async {
      if (next == 0 || next == previous) return;
      try {
        final storageService = ref.read(storageServiceProvider);
        final newStatus = await storageService.getIdtyStatus(address);

        if (newStatus != state.value) {
          state = AsyncValue.data(newStatus);

          // If identity was created, switch to stream subscription
          if (newStatus != d.IdtyStatus.none) {
            _listeningToBlockHeight = false;
            _startIdentitySubscription(address);
          }
        }
      } catch (e) {
        // Continue trying on next block
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

          // If identity disappears, switch back to block height listener
          if (newStatus == d.IdtyStatus.none) {
            _idtySubscription?.cancel();
            _idtySubscription = null;
            _startBlockHeightListener(address);
          }
        }
      });
    } catch (e) {
      log.e('Error starting identity subscription for $address: $e');
      // Fallback to block height listener
      _startBlockHeightListener(address);
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
        _listeningToBlockHeight = false;
        _startIdentitySubscription(address);
      } else if (previousStatus != d.IdtyStatus.none && newStatus == d.IdtyStatus.none) {
        // Transition from having identity to no identity: switch to block height
        _idtySubscription?.cancel();
        _idtySubscription = null;
        _startBlockHeightListener(address);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final hybridIdtyStatusProvider = AsyncNotifierProvider.family<HybridIdtyStatusNotifier, d.IdtyStatus, String>(
  HybridIdtyStatusNotifier.new,
);

/// Hybrid certification provider using StateNotifier approach
/// This ensures certifications are always up-to-date by combining streams with periodic polling
/// Solves the issue where WebSocket notifications for IdtyCertMeta storage key are not triggered
class HybridCertificationNotifier extends AsyncNotifier<d.CertificationData> {
  HybridCertificationNotifier(this.arg);
  final String arg;

  StreamSubscription<d.StorageChangeSet>? _certSubscription;
  StreamSubscription<String?>? _certActivitySubscription;

  @override
  Future<d.CertificationData> build() async {
    final address = arg;
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _certSubscription?.cancel();
      _certActivitySubscription?.cancel();
    });

    // Initial data fetch
    final storageService = ref.watch(storageServiceProvider);
    final certData = await storageService.getCertsCounter(address);

    // Start Duniter stream subscription (primary source)
    _startCertSubscription(address);
    // Start Squid cert activity subscription (catches missed WebSocket updates)
    _startCertActivitySubscription(address);

    return certData;
  }

  /// Subscribe to Squid cert activity to detect changes (replaces Timer.periodic(10s))
  void _startCertActivitySubscription(String address) {
    _certActivitySubscription?.cancel();
    try {
      _certActivitySubscription = d.SquidService.client
          .subscribeCertActivity(address)
          .listen(
            (certId) {
              if (certId != null) {
                forceRefresh();
              }
            },
            onError: (error) {
              log.e('Cert activity subscription error for $address: $error');
            },
          );
    } catch (e) {
      log.e('Failed to setup cert activity subscription for $address: $e');
    }
  }

  void _startCertSubscription(String address) async {
    _certSubscription?.cancel();
    try {
      final storageService = ref.read(storageServiceProvider);
      _certSubscription = await storageService.subscribeToCertsCounter(address, (newCertData) {
        final currentData = state.value;
        if (currentData == null ||
            newCertData.receivedCount != currentData.receivedCount ||
            newCertData.sentCount != currentData.sentCount) {
          state = AsyncValue.data(newCertData);
        }
      });
    } catch (e) {
      log.e('Error starting certification subscription for $address: $e');
    }
  }

  void forceRefresh() async {
    final address = arg;
    try {
      final storageService = ref.read(storageServiceProvider);
      final newCertData = await storageService.getCertsCounter(address);
      state = AsyncValue.data(newCertData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final hybridCertificationProvider =
    AsyncNotifierProvider.family<HybridCertificationNotifier, d.CertificationData, String>(
      HybridCertificationNotifier.new,
    );
