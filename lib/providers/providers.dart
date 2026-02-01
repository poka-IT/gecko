// ignore_for_file: avoid_print

import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart' show Box;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/connection_providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/routes.dart';

/// Provides the global, initialized instance of [d.Durt].
///
/// DuniterStorageService is now always available, even without network connection.
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

/// Provides the current [d.Networks] enum value the app is connected to (e.g., gdev, gtest, g1).
final networkProvider = Provider<d.Networks>((ref) {
  return ref.watch(durtProvider).network;
});

/// Provides the [d.SquidService] for querying the GraphQL indexer.
final squidServiceProvider = Provider<d.SquidService>((ref) {
  return ref.watch(durtProvider).squid;
});

/// Provides the [d.CesiumPlusService] for querying the Cesium+ pod REST API.
final cesiumPlusServiceProvider = Provider<d.CesiumPlusService>((ref) {
  return ref.watch(durtProvider).cesiumPlus;
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
/// Returns null if storage is not initialized or in offline mode.
final genesisTimeProvider = FutureProvider<DateTime?>((ref) async {
  final storageState = ref.watch(storageStateProvider);

  if (storageState == StorageState.notInitialized) {
    return null; // Loading state
  }

  if (storageState == StorageState.offlineMode) {
    return null; // Pas de genesis time en offline
  }

  final storageService = ref.watch(storageServiceProvider);
  return await storageService.getGenesisBlockchainTime();
});

/// Provides the first wallet of the active safe for reactive UI updates.
/// This provider watches the wallets list and returns the first wallet (sorted by number).
final firstWalletProvider = Provider<d.WalletEntity>((ref) {
  final walletsList = ref.watch(walletsListProvider).wallets;
  return walletsList.first;
});

/// Notifier for pending legacy migration data
class PendingLegacyMigrationNotifier extends Notifier<LegacyMigrationData?> {
  @override
  LegacyMigrationData? build() => null;

  void set(LegacyMigrationData? value) => state = value;
  void clear() => state = null;
}

/// Provider for pending legacy migration data
/// This is used to store migration data between wallet options screen and onboarding completion
final pendingLegacyMigrationProvider = NotifierProvider<PendingLegacyMigrationNotifier, LegacyMigrationData?>(
  PendingLegacyMigrationNotifier.new,
);

/// Notifier for the default safe box number.
/// This ensures that identity providers react to safe changes.
class DefaultSafeBoxNumberNotifier extends Notifier<int> {
  @override
  int build() {
    return ref.read(walletServiceProvider).defaultSafeBoxNumber;
  }

  d.WalletService get _walletService => ref.read(walletServiceProvider);

  /// Update the default safe box number and sync with wallet service
  void setDefaultSafeBoxNumber(int safeBoxNumber) {
    _walletService.setDefaultSafeBoxNumber(safeBoxNumber);
    state = safeBoxNumber;
  }

  /// Refresh the state from wallet service (useful after external changes)
  void refresh() {
    state = _walletService.defaultSafeBoxNumber;
  }
}

/// Reactive provider for the default safe box number.
/// This provider watches the wallet service and automatically updates when the default safe changes.
/// Other providers (like identity providers) should watch this to react to safe changes.
final defaultSafeBoxNumberProvider = NotifierProvider<DefaultSafeBoxNumberNotifier, int>(
  DefaultSafeBoxNumberNotifier.new,
);
