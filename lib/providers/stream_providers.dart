// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/connection_providers.dart';

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
