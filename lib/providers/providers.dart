// ignore_for_file: avoid_print

import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart' show Box;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provides the [d.DatapodService] for querying the Datapod GraphQL API.
final datapodServiceProvider = Provider<d.DatapodService>((ref) {
  return ref.watch(durtProvider).datapod;
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

/// Provides the current default wallet for reactive UI updates.
/// This provider watches for changes to the default wallet and rebuilds dependents automatically.
final defaultWalletProvider = Provider<d.WalletEntity>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  // defaultWallet now always returns a valid wallet or throws a meaningful exception
  return walletService.defaultWallet;
});
