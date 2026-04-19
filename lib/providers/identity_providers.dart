import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/migration_data.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/block_height_provider.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/services/config_service.dart';

/// Notifier to track whether the user has dismissed the migration warning for a given address.
/// Resets on app restart, so the warning will reappear next session.
class IgnoreMigrationWarningNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void ignore() => state = true;
}

/// Provider to track migration warning dismissal per address
final ignoreMigrationWarningProvider = NotifierProvider.family<IgnoreMigrationWarningNotifier, bool, String>(
  (_) => IgnoreMigrationWarningNotifier(),
);

enum MigrationDirection { from, to }

/// Provides migration data for a given direction (from/to) and address.
final migrationDataProvider = FutureProvider.family<MigrationData?, ({MigrationDirection direction, String address})>((
  ref,
  params,
) async {
  try {
    final squidService = d.SquidService.client;
    final migrations = await squidService.getIdentityMigrations(params.address);

    final node = params.direction == MigrationDirection.from ? migrations?.migrationFrom : migrations?.migrationTo;
    if (node == null) return null;

    final genesisTime = await ref.watch(genesisTimeProvider.future);
    if (genesisTime == null) return null;

    return params.direction == MigrationDirection.from
        ? await MigrationData.fromSquidMigrationFromNode(node, genesisTime)
        : await MigrationData.fromSquidMigrationToNode(node, genesisTime);
  } catch (e) {
    return null;
  }
});

/// Shorthand for migration FROM data.
final migrationFromDataProvider = FutureProvider.family<MigrationData?, String>(
  (ref, address) => ref.watch(migrationDataProvider((direction: MigrationDirection.from, address: address)).future),
);

/// Shorthand for migration TO data.
final migrationToDataProvider = FutureProvider.family<MigrationData?, String>(
  (ref, address) => ref.watch(migrationDataProvider((direction: MigrationDirection.to, address: address)).future),
);

/// Hybrid identity name provider that combines initial fetch with periodic polling
/// This ensures identity names are always up-to-date after migrations or identity creations
class HybridIdentityNameNotifier extends AsyncNotifier<String?> {
  HybridIdentityNameNotifier(this.arg);
  final String arg;

  StreamSubscription<String?>? _nameSubscription;

  @override
  Future<String?> build() async {
    final address = arg;
    // Cleanup when provider is disposed
    ref.onDispose(() {
      _nameSubscription?.cancel();
    });

    // Check Squid connection
    final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
    if (squidConnectionStatus != d.ConnectionStatus.connected) {
      return null;
    }

    // Initial fetch
    final identityName = await _fetchIdentityName(address);

    // Subscribe to identity name changes (replaces Timer.periodic(10s))
    _startNameSubscription(address);

    return identityName;
  }

  Future<String?> _fetchIdentityName(String address) async {
    try {
      final identityName = await d.SquidService.client.getIdentityName(address);

      // Cache the result
      final squidService = ref.read(squidServiceProvider);
      squidService.walletNameIndexer[address] = identityName;

      return identityName;
    } catch (e) {
      return null;
    }
  }

  /// Subscribe to identity name changes via Squid (replaces Timer.periodic(10s))
  void _startNameSubscription(String address) {
    _nameSubscription?.cancel();
    try {
      _nameSubscription = d.SquidService.client
          .subscribeIdentityName(address)
          .listen(
            (newName) {
              // Only update if name actually changed
              if (newName != state.value) {
                // Cache the result
                final squidService = ref.read(squidServiceProvider);
                squidService.walletNameIndexer[address] = newName;

                state = AsyncValue.data(newName);
              }
            },
            onError: (error) {
              log.e('Identity name subscription error for $address: $error');
            },
          );
    } catch (e) {
      log.e('Failed to setup identity name subscription for $address: $e');
    }
  }

  void forceRefresh() async {
    final address = arg;
    try {
      final newName = await _fetchIdentityName(address);
      state = AsyncValue.data(newName);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

final hybridIdentityNameProvider = AsyncNotifierProvider.family<HybridIdentityNameNotifier, String?, String>(
  HybridIdentityNameNotifier.new,
);

/// Provides identity search results for a given search term.
/// Searches both by identity name and by address fragment in parallel,
/// then merges and deduplicates results (name matches first, then address matches).
final searchIdentityProvider = FutureProvider.family<List<d.IdentitySuggestion>, String>((ref, searchTerm) async {
  final squidConnectionStatus = ref.watch(squidConnectionStatusProvider);
  if (squidConnectionStatus != d.ConnectionStatus.connected) {
    return [];
  }

  try {
    final client = d.SquidService.client;

    // Always search by name; also search by address fragment if >= 6 chars and no spaces
    final nameSearch = client.searchAddressByName(searchTerm);
    final doAddressSearch = searchTerm.length >= 6 && !searchTerm.contains(' ');
    final addressSearch = doAddressSearch ? client.searchByAddress(searchTerm) : Future.value(<d.IdentitySuggestion>[]);

    final bothResults = await Future.wait([
      nameSearch.catchError((_) => <d.IdentitySuggestion>[]),
      addressSearch.catchError((_) => <d.IdentitySuggestion>[]),
    ]);
    final nameResults = bothResults[0];
    final addressResults = bothResults[1];

    // Merge: name results first, then address results not already present
    final seenAddresses = <String>{};
    final merged = <d.IdentitySuggestion>[];
    for (final r in nameResults) {
      if (seenAddresses.add(r.address)) merged.add(r);
    }
    for (final r in addressResults) {
      if (seenAddresses.add(r.address)) merged.add(r);
    }
    return merged;
  } catch (e) {
    return [];
  }
});

/// Provider to check if a certification already exists between effective wallet and target address
/// Returns true if a certification exists (renewal case), false if not (new certification case)
final certificationExistsProvider = FutureProvider.family<bool, String>((ref, targetAddress) async {
  // Check if storage is initialized FIRST
  final storageState = ref.watch(storageStateProvider);
  if (storageState == StorageState.notInitialized) {
    return false;
  }

  final effectiveWallet = await ref.watch(effectiveCertificationWalletProvider.future);
  if (effectiveWallet == null) return false;

  final storageService = ref.watch(storageServiceProvider);
  final validityPeriod = await storageService.getCertValidityPeriod(effectiveWallet.address, targetAddress);

  // If validity period > 0, certification exists
  return validityPeriod > 0;
});

/// Stable identity wallet notifier that caches results and only rebuilds when necessary
/// This prevents the UI reload spam during connection changes
class IdtyWalletNotifier extends AsyncNotifier<d.WalletEntity?> {
  d.WalletEntity? _cachedResult;
  List<String> _cachedWalletAddresses = [];
  int? _lastSafeNumber;

  @override
  Future<d.WalletEntity?> build() async {
    // Watch the default safe number BEFORE storage state check
    // to clear cache on safe change even during brief notInitialized states
    final defaultSafeNumber = ref.watch(defaultSafeBoxNumberProvider);

    // Clear cache on safe change
    if (_lastSafeNumber != null && _lastSafeNumber != defaultSafeNumber) {
      _cachedResult = null;
      _cachedWalletAddresses = [];
    }
    _lastSafeNumber = defaultSafeNumber;

    // Check if storage is initialized FIRST before accessing any providers
    final storageState = ref.watch(storageStateProvider);
    if (storageState == StorageState.notInitialized) {
      return _cachedResult;
    }

    // Now safe to watch other providers
    final walletService = ref.watch(walletServiceProvider);
    final storageService = ref.watch(storageServiceProvider);

    final allSafes = walletService.safeBox.getAll();
    if (allSafes.isEmpty) {
      _cachedResult = null;
      _cachedWalletAddresses = [];
      return null;
    }

    final defaultSafe = allSafes.firstWhere(
      (safe) => safe.number == defaultSafeNumber,
      orElse: () => allSafes.first, // Fallback to first safe if default not found
    );

    // Use direct query instead of defaultSafe.wallets.toList() to avoid
    // ObjectBox ToMany backlink cache returning stale data.
    final query = walletService.walletBox.query()
      ..link(WalletEntity_.safe, SafeEntity_.number.equals(defaultSafe.number));
    final wallets = query.build().find();
    if (wallets.isEmpty) {
      _cachedResult = null;
      _cachedWalletAddresses = [];
      _persistCache(defaultSafeNumber, null);
      return null;
    }

    // Seed the in-memory cache from the persistent cache on cold builds.
    // This eliminates the WalletsHome layout flash (grid-only → hero+grid)
    // that otherwise occurs on every PIN unlock when the provider is
    // invalidated and rebuilds from scratch. The on-chain resolution below
    // still runs to validate and refresh the cached value.
    if (_cachedResult == null) {
      final cachedAddress = ConfigService(configBox).getIdentityWalletAddress(defaultSafeNumber);
      if (cachedAddress != null) {
        final candidate = wallets.where((w) => w.address == cachedAddress).firstOrNull;
        if (candidate != null) {
          _cachedResult = candidate;
          _cachedWalletAddresses = wallets.map((w) => w.address).toList()..sort();
        }
      }
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
    _persistCache(defaultSafeNumber, bestWallet?.address);

    // Preload streams for the selected wallet
    if (bestWallet != null) {
      _preloadStreamsQuietly(wallets);
    }

    return bestWallet;
  }

  /// Persist the resolved identity wallet address to Hive so the next cold
  /// build can seed [_cachedResult] synchronously and avoid the layout flash.
  void _persistCache(int safeNumber, String? address) {
    // Fire-and-forget: do not await, Hive writes are fast and a failure here
    // is non-critical (next resolution will just re-populate the cache).
    ConfigService(configBox).setIdentityWalletAddress(safeNumber, address);
  }

  /// Preload streams without triggering UI rebuilds
  void _preloadStreamsQuietly(List<d.WalletEntity> wallets) {
    // Use a timer to avoid immediate rebuilds
    Timer.run(() {
      for (final wallet in wallets) {
        try {
          // These calls preload the providers without causing immediate rebuilds
          ref.read(smartBalanceStreamProvider(wallet.address));
          ref.read(hybridIdentityNameProvider(wallet.address));
          ref.read(hybridIdtyStatusProvider(wallet.address));
          ref.read(hybridCertificationProvider(wallet.address));
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
    _lastSafeNumber = null;
    ref.invalidateSelf();
  }
}

/// Stable async provider to get the identity wallet (member or identity holder)
/// Uses caching to prevent UI reload spam during connection changes
final idtyWalletAsyncProvider = AsyncNotifierProvider<IdtyWalletNotifier, d.WalletEntity?>(() => IdtyWalletNotifier());

/// Notifier for selected certification wallet (development mode only)
/// This allows developers to choose which identity wallet to use for certifications
/// when using the test mnemonic with multiple identity wallets
class SelectedCertificationWalletNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? value) => state = value;
  void clear() => state = null;
}

/// Provider for selected certification wallet (development mode only)
final selectedCertificationWalletProvider = NotifierProvider<SelectedCertificationWalletNotifier, String?>(
  SelectedCertificationWalletNotifier.new,
);

/// Provider for certification state between effective wallet and target address
/// Automatically updates when balance or certifications change, with caching to avoid UI jumps
final certStateProvider = AsyncNotifierProvider.family<CertStateNotifier, d.CertState?, String>(CertStateNotifier.new);

/// Notifier that caches cert state and updates smoothly without UI jumps
class CertStateNotifier extends AsyncNotifier<d.CertState?> {
  CertStateNotifier(this.arg);
  final String arg;

  @override
  Future<d.CertState?> build() async {
    // Check storage state FIRST
    final storageState = ref.watch(storageStateProvider);
    if (storageState == StorageState.notInitialized) {
      return null;
    }

    final toAddress = arg;
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

    final certState = await _getCertState(effectiveWallet.address, toAddress);

    // Listen to block height to refresh cert state periodically while in a waiting state.
    // Throttled to every 10 blocks (~60s) to avoid excessive RPC calls (getCertState
    // makes 5 parallel queries). Exact timing is not critical for countdown display.
    ref.listen(blockHeightProvider, (previous, next) {
      if (next == 0 || next == previous) return;
      final currentState = state.value;
      if (currentState == null) return;
      final hasWaitingDuration = currentState.duration != null && currentState.duration! > Duration.zero;
      if (!hasWaitingDuration) return;
      // Only refresh every 10 blocks to limit RPC load
      if (previous != null && (next ~/ 10) == (previous ~/ 10)) return;
      _refreshCertState();
    });

    return certState;
  }

  /// Refresh cert state without clearing the previous value
  void _refreshCertState() async {
    // Check storage state first
    final storageState = ref.read(storageStateProvider);
    if (storageState == StorageState.notInitialized) return;

    final effectiveWallet = await ref.read(effectiveCertificationWalletProvider.future);
    if (effectiveWallet == null) return;

    // Update state smoothly - keep previous value visible during loading
    final newCertState = await _getCertState(effectiveWallet.address, arg);
    state = AsyncValue.data(newCertState);
  }

  /// Get cert state from storage
  Future<d.CertState?> _getCertState(String fromAddress, String toAddress) async {
    // Check if storage is initialized
    final storageState = ref.read(storageStateProvider);
    if (storageState == StorageState.notInitialized) {
      return null;
    }

    return await ref.read(storageServiceProvider).getCertState(fromAddress: fromAddress, toAddress: toAddress);
  }
}

/// Provider to get member wallets from the CURRENT safe only.
/// Used on mobile where certification is scoped to the active safe.
final identityWalletsAsyncProvider = FutureProvider<List<d.WalletEntity>>((ref) async {
  // Check if storage is initialized FIRST
  final storageState = ref.watch(storageStateProvider);
  if (storageState == StorageState.notInitialized) {
    return [];
  }

  final walletService = ref.watch(walletServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  // Watch the default safe number provider to react to safe changes
  final defaultSafeNumber = ref.watch(defaultSafeBoxNumberProvider);

  final allSafes = walletService.safeBox.getAll();
  if (allSafes.isEmpty) return [];

  final defaultSafe = allSafes.firstWhere((safe) => safe.number == defaultSafeNumber, orElse: () => allSafes.first);

  // Use direct query to avoid ObjectBox ToMany backlink cache
  final query = walletService.walletBox.query()
    ..link(WalletEntity_.safe, SafeEntity_.number.equals(defaultSafe.number));
  final wallets = query.build().find();
  if (wallets.isEmpty) return [];

  final memberWallets = <d.WalletEntity>[];

  // Only keep wallets with member (validated) identity status
  for (final wallet in wallets) {
    try {
      final status = await storageService.getIdtyStatus(wallet.address);
      if (status == d.IdtyStatus.validated) {
        memberWallets.add(wallet);
      }
    } catch (_) {
      // Skip wallets that can't be checked (e.g., offline mode)
    }
  }

  return memberWallets;
});

/// Provider to get member wallets across ALL safes.
/// Used on desktop where all safes are visible and certification
/// should work regardless of which safe is currently active.
final allSafesIdentityWalletsProvider = FutureProvider<List<d.WalletEntity>>((ref) async {
  final storageState = ref.watch(storageStateProvider);
  if (storageState == StorageState.notInitialized) {
    return [];
  }

  final walletService = ref.watch(walletServiceProvider);
  final storageService = ref.watch(storageServiceProvider);

  // Watch safe changes to rebuild when safes are added/removed
  ref.watch(defaultSafeBoxNumberProvider);

  final allWallets = walletService.walletBox.getAll();
  if (allWallets.isEmpty) return [];

  final memberWallets = <d.WalletEntity>[];

  for (final wallet in allWallets) {
    try {
      final status = await storageService.getIdtyStatus(wallet.address);
      if (status == d.IdtyStatus.validated) {
        memberWallets.add(wallet);
      }
    } catch (_) {
      // Skip wallets that can't be checked (e.g., offline mode)
    }
  }

  return memberWallets;
});

/// Provider that returns the effective certification wallet:
/// - If a specific wallet is selected via dropdown, use that
/// - Otherwise, use the automatic identity wallet selection from current safe
final effectiveCertificationWalletProvider = FutureProvider<d.WalletEntity?>((ref) async {
  final selectedAddress = ref.watch(selectedCertificationWalletProvider);

  // If a specific wallet is selected via dropdown, use that
  if (selectedAddress != null) {
    final walletService = ref.watch(walletServiceProvider);
    final selectedWallet = walletService.walletBox.getAll().where((w) => w.address == selectedAddress).firstOrNull;
    if (selectedWallet != null) {
      return selectedWallet;
    }
  }

  // Otherwise, use the automatic selection from current safe
  return ref.watch(idtyWalletAsyncProvider.future);
});
