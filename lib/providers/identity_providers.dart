import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:gecko/models/migration_data.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/stream_providers.dart';

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

/// Provider to check if a certification already exists between effective wallet and target address
/// Returns true if a certification exists (renewal case), false if not (new certification case)
final certificationExistsProvider = FutureProvider.family<bool, String>((ref, targetAddress) async {
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

  @override
  Future<d.WalletEntity?> build() async {
    // Watch wallet service but don't rebuild on connection changes
    final walletService = ref.watch(walletServiceProvider);
    final storageService = ref.watch(storageServiceProvider);
    // Watch the default safe number provider to react to safe changes
    final defaultSafeNumber = ref.watch(defaultSafeBoxNumberProvider);

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

/// State provider for selected certification wallet (development mode only)
/// This allows developers to choose which identity wallet to use for certifications
/// when using the test mnemonic with multiple identity wallets
final selectedCertificationWalletProvider = StateProvider<String?>((ref) => null);

/// Provider for certification state between effective wallet and target address
/// Automatically updates when balance or certifications change, with caching to avoid UI jumps
final certStateProvider = AsyncNotifierProvider.family<CertStateNotifier, d.CertState?, String>(CertStateNotifier.new);

/// Notifier that caches cert state and updates smoothly without UI jumps
class CertStateNotifier extends AsyncNotifier<d.CertState?> {
  CertStateNotifier(this.arg);
  final String arg;

  @override
  Future<d.CertState?> build() async {
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
  // Watch the default safe number provider to react to safe changes
  final defaultSafeNumber = ref.watch(defaultSafeBoxNumberProvider);

  final allSafes = walletService.safeBox.getAll();
  if (allSafes.isEmpty) return [];

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
