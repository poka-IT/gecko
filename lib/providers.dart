import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart' show Box;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

/// Provides a stream of the current [d.ConnectionStatus].
///
/// This is the most efficient way to listen for connection changes. Widgets that
/// watch this provider will only rebuild when the connection status actually changes
/// (e.g., from 'connecting' to 'connected').
final connectionStatusProvider = StreamProvider<d.ConnectionStatus>((ref) {
  return ref.watch(durtProvider).connectionStatusStream;
});
