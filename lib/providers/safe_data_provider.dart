// ignore_for_file: avoid_print

import 'dart:async';
import 'package:durt2/durt2.dart' as d;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/wallets_provider.dart';
import 'package:gecko/providers/connection_providers.dart';

// ============================================================================
// STATE CLASS
// ============================================================================

/// Centralized state for all on-chain data of a safe's wallets.
/// This enables batch loading and synchronized display of wallet data.
class SafeOnChainData {
  final Map<String, d.WalletBalance> balances;
  final Map<String, d.CertificationData> certifications;
  final Map<String, d.IdtyStatus> identityStatuses;
  final bool isFullyLoaded;

  const SafeOnChainData({
    required this.balances,
    required this.certifications,
    required this.identityStatuses,
    this.isFullyLoaded = false,
  });

  factory SafeOnChainData.empty() =>
      const SafeOnChainData(balances: {}, certifications: {}, identityStatuses: {}, isFullyLoaded: false);

  SafeOnChainData copyWith({
    Map<String, d.WalletBalance>? balances,
    Map<String, d.CertificationData>? certifications,
    Map<String, d.IdtyStatus>? identityStatuses,
    bool? isFullyLoaded,
  }) => SafeOnChainData(
    balances: balances ?? this.balances,
    certifications: certifications ?? this.certifications,
    identityStatuses: identityStatuses ?? this.identityStatuses,
    isFullyLoaded: isFullyLoaded ?? this.isFullyLoaded,
  );

  /// Update a single wallet's balance
  SafeOnChainData updateBalance(String address, d.WalletBalance balance) {
    return copyWith(balances: {...balances, address: balance});
  }

  /// Update a single wallet's certification data
  SafeOnChainData updateCertification(String address, d.CertificationData cert) {
    return copyWith(certifications: {...certifications, address: cert});
  }

  /// Update a single wallet's identity status
  SafeOnChainData updateIdtyStatus(String address, d.IdtyStatus status) {
    return copyWith(identityStatuses: {...identityStatuses, address: status});
  }
}

// ============================================================================
// NOTIFIER CLASS
// ============================================================================

/// Notifier that manages all on-chain data for a safe's wallets.
/// Uses batch RPC calls and batch subscriptions for optimal performance.
class SafeOnChainDataNotifier extends AsyncNotifier<SafeOnChainData> {
  SafeOnChainDataNotifier(this.safeNumber);
  final int safeNumber;

  StreamSubscription? _balanceSubscription;
  StreamSubscription? _certSubscription;
  StreamSubscription? _idtySubscription;
  List<String> _currentAddresses = [];

  @override
  Future<SafeOnChainData> build() async {
    // Cleanup on dispose
    ref.onDispose(() {
      _cancelSubscriptions();
    });

    // Watch connection status to reload on reconnection
    final connectionStatus = ref.watch(connectionStatusProvider);
    if (connectionStatus != d.ConnectionStatus.connected) {
      // Return empty data in offline mode
      return SafeOnChainData.empty();
    }

    // Get wallets for this safe
    final walletService = ref.watch(walletServiceProvider);
    final safe = walletService.getSafeBox(safeNumber);
    final addresses = safe.wallets.map((w) => w.address).toList();

    if (addresses.isEmpty) {
      return SafeOnChainData.empty();
    }

    _currentAddresses = addresses;

    // Load all data in parallel using batch RPC calls (3 calls total)
    final storageService = ref.watch(storageServiceProvider);

    try {
      final results = await Future.wait([
        storageService.getBalances(addresses),
        storageService.getCertsCountersBatch(addresses),
        storageService.getIdtyStatusMulti(addresses),
      ]);

      final balances = results[0] as Map<String, d.WalletBalance>;
      final certs = results[1] as Map<String, d.CertificationData>;
      final statusList = results[2] as List<d.IdtyStatus>;

      // Map statuses to addresses (with safety check)
      final statuses = <String, d.IdtyStatus>{};
      if (statusList.length != addresses.length) {
        log.w('⚠️ getIdtyStatusMulti returned ${statusList.length} results for ${addresses.length} addresses');
      }
      final minLen = statusList.length < addresses.length ? statusList.length : addresses.length;
      for (var i = 0; i < minLen; i++) {
        statuses[addresses[i]] = statusList[i];
      }
      // Fill remaining addresses with IdtyStatus.none
      for (var i = minLen; i < addresses.length; i++) {
        statuses[addresses[i]] = d.IdtyStatus.none;
      }

      // Start batch subscriptions for real-time updates
      _startBatchSubscriptions(addresses, storageService);

      log.d('📦 SafeOnChainData loaded for safe #$safeNumber: ${addresses.length} wallets');

      return SafeOnChainData(
        balances: balances,
        certifications: certs,
        identityStatuses: statuses,
        isFullyLoaded: true,
      );
    } catch (e) {
      log.e('❌ Error loading SafeOnChainData for safe #$safeNumber: $e');
      rethrow;
    }
  }

  void _cancelSubscriptions() {
    _balanceSubscription?.cancel();
    _certSubscription?.cancel();
    _idtySubscription?.cancel();
    _balanceSubscription = null;
    _certSubscription = null;
    _idtySubscription = null;
  }

  void _startBatchSubscriptions(List<String> addresses, d.DuniterStorageService storageService) async {
    // Cancel existing subscriptions first
    _cancelSubscriptions();

    try {
      // Single subscription for all balance updates
      _balanceSubscription = await storageService.subscribeBalancesBatch(addresses, (address, balance) {
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncValue.data(currentState.updateBalance(address, balance));
        }
      });

      // Single subscription for all certification updates
      _certSubscription = await storageService.subscribeCertsBatch(addresses, (address, certData) {
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncValue.data(currentState.updateCertification(address, certData));
        }
      });

      // Single subscription for all identity status updates
      _idtySubscription = await storageService.subscribeIdtyStatusBatch(addresses, (address, status) {
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncValue.data(currentState.updateIdtyStatus(address, status));
        }
      });

      log.d('🔔 Batch subscriptions started for ${addresses.length} addresses');
    } catch (e) {
      log.e('❌ Error starting batch subscriptions: $e');
    }
  }

  /// Force refresh all data for the current safe
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    ref.invalidateSelf();
  }

  /// Add a new wallet address to the subscriptions
  void addWallet(String address) {
    if (!_currentAddresses.contains(address)) {
      _currentAddresses.add(address);
      // Trigger a full reload to include the new wallet
      ref.invalidateSelf();
    }
  }

  /// Remove a wallet address from the subscriptions
  void removeWallet(String address) {
    if (_currentAddresses.contains(address)) {
      _currentAddresses.remove(address);
      // Update state to remove the wallet's data
      final currentState = state.value;
      if (currentState != null) {
        final newBalances = Map<String, d.WalletBalance>.from(currentState.balances)..remove(address);
        final newCerts = Map<String, d.CertificationData>.from(currentState.certifications)..remove(address);
        final newStatuses = Map<String, d.IdtyStatus>.from(currentState.identityStatuses)..remove(address);
        state = AsyncValue.data(
          currentState.copyWith(balances: newBalances, certifications: newCerts, identityStatuses: newStatuses),
        );
      }
    }
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Main provider for on-chain data of a safe.
/// Loads all wallet data in batch and maintains real-time subscriptions.
final safeOnChainDataProvider = AsyncNotifierProvider.family<SafeOnChainDataNotifier, SafeOnChainData, int>(
  SafeOnChainDataNotifier.new,
);

// ============================================================================
// SELECTOR PROVIDERS (Granular access)
// ============================================================================

/// Balance for a specific wallet address from the current safe's batch-loaded data.
/// Returns null if the wallet is not in the current safe (use smartBalanceStreamProvider as fallback).
final safeWalletBalanceProvider = Provider.family<d.WalletBalance?, String>((ref, address) {
  final currentSafe = ref.watch(currentSafeNumberProvider);
  final safeData = ref.watch(safeOnChainDataProvider(currentSafe));

  return safeData.when(data: (data) => data.balances[address], loading: () => null, error: (e, st) => null);
});

/// Check if a wallet belongs to the current safe
final isWalletInCurrentSafeProvider = Provider.family<bool, String>((ref, address) {
  final walletService = ref.watch(walletServiceProvider);
  return walletService.isOwnedWallet(address);
});

/// Certification data for a specific wallet address from the current safe's batch-loaded data.
/// Returns null if the wallet is not in the current safe (use smartCertificationStreamProvider as fallback).
final safeWalletCertProvider = Provider.family<d.CertificationData?, String>((ref, address) {
  final currentSafe = ref.watch(currentSafeNumberProvider);
  final safeData = ref.watch(safeOnChainDataProvider(currentSafe));

  return safeData.when(data: (data) => data.certifications[address], loading: () => null, error: (e, st) => null);
});

/// Identity status for a specific wallet address from the current safe's batch-loaded data.
/// Returns null if the wallet is not in the current safe (use smartIdtyStatusStreamProvider as fallback).
final safeWalletIdtyStatusProvider = Provider.family<d.IdtyStatus?, String>((ref, address) {
  final currentSafe = ref.watch(currentSafeNumberProvider);
  final safeData = ref.watch(safeOnChainDataProvider(currentSafe));

  return safeData.when(data: (data) => data.identityStatuses[address], loading: () => null, error: (e, st) => null);
});

/// Check if safe data is fully loaded.
/// Useful for showing loading indicators.
final isSafeDataLoadedProvider = Provider.family<bool, int>((ref, safeNumber) {
  final safeData = ref.watch(safeOnChainDataProvider(safeNumber));
  return safeData.when(data: (data) => data.isFullyLoaded, loading: () => false, error: (e, st) => false);
});
