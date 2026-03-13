import 'dart:io';

import 'package:durt2/durt2.dart' as d;
import 'package:durt2/objectbox.g.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/providers/safe_data_provider.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:path_provider/path_provider.dart';

// ============================================================================
// STATE CLASSES
// ============================================================================

/// Immutable state for the wallets list
class WalletsListState {
  final List<d.WalletEntity> wallets;
  final bool isLoading;
  final int currentSafeNumber;
  final String? error;

  const WalletsListState({this.wallets = const [], this.isLoading = false, this.currentSafeNumber = 0, this.error});

  WalletsListState copyWith({List<d.WalletEntity>? wallets, bool? isLoading, int? currentSafeNumber, String? error}) {
    return WalletsListState(
      wallets: wallets ?? this.wallets,
      isLoading: isLoading ?? this.isLoading,
      currentSafeNumber: currentSafeNumber ?? this.currentSafeNumber,
      error: error,
    );
  }

  /// Computed property: check if wallet list is empty
  bool get isEmpty => wallets.isEmpty;

  /// Computed property: check if wallet list is not empty
  bool get isNotEmpty => wallets.isNotEmpty;
}

/// Immutable state for PIN management
class PinState {
  final bool isValid;
  final bool isLoading;
  final int? pinLength;

  const PinState({this.isValid = false, this.isLoading = true, this.pinLength});

  PinState copyWith({bool? isValid, bool? isLoading, int? pinLength}) {
    return PinState(
      isValid: isValid ?? this.isValid,
      isLoading: isLoading ?? this.isLoading,
      pinLength: pinLength ?? this.pinLength,
    );
  }
}

/// Immutable state for drag & drop operations
class DragDropState {
  final d.WalletEntity? lastFlyBy;
  final d.WalletEntity? dragAddress;

  const DragDropState({this.lastFlyBy, this.dragAddress});

  DragDropState copyWith({
    d.WalletEntity? lastFlyBy,
    d.WalletEntity? dragAddress,
    bool clearLastFlyBy = false,
    bool clearDragAddress = false,
  }) {
    return DragDropState(
      lastFlyBy: clearLastFlyBy ? null : (lastFlyBy ?? this.lastFlyBy),
      dragAddress: clearDragAddress ? null : (dragAddress ?? this.dragAddress),
    );
  }

  /// Computed property: check if a drag operation is in progress
  bool get isDragging => dragAddress != null;
}

/// Immutable state for derivation operations
class DerivationState {
  final bool isLoading;
  final String? mnemonic;
  final String? error;

  const DerivationState({this.isLoading = false, this.mnemonic, this.error});

  DerivationState copyWith({bool? isLoading, String? mnemonic, String? error, bool clearMnemonic = false}) {
    return DerivationState(
      isLoading: isLoading ?? this.isLoading,
      mnemonic: clearMnemonic ? null : (mnemonic ?? this.mnemonic),
      error: error,
    );
  }
}

// ============================================================================
// NOTIFIERS
// ============================================================================

/// Notifier for managing the wallets list
class WalletsListNotifier extends Notifier<WalletsListState> {
  @override
  WalletsListState build() {
    // Listen to safe number changes to auto-reload
    ref.listen(defaultSafeBoxNumberProvider, (previous, next) {
      if (previous != next) {
        // Si pas de safe (-1), vider la liste au lieu de charger
        if (next < 0) {
          state = state.copyWith(wallets: [], isLoading: false, currentSafeNumber: next);
        } else {
          loadWallets(safeBoxNumber: next);
        }
      }
    });

    // Initial load
    Future.microtask(() => loadWallets());

    return const WalletsListState(isLoading: true);
  }

  d.WalletService get _walletService => ref.read(walletServiceProvider);

  /// Load wallets from the specified safe box
  Future<void> loadWallets({int? safeBoxNumber, WidgetRef? widgetRef}) async {
    final sbn = safeBoxNumber ?? _walletService.defaultSafeBoxNumber;

    // Pas de safe valide (-1), retourner une liste vide
    if (sbn < 0 || !_walletService.isWalletExist) {
      state = state.copyWith(wallets: [], isLoading: false, currentSafeNumber: sbn);
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      d.SafeEntity? safe;
      try {
        safe = _walletService.getSafeBox(sbn);
      } catch (e) {
        // Safe doesn't exist yet, get the first safe
        log.w('Safe $sbn not found, take the first safe: $e');
        final firstSafe = _walletService.safeBox.query().build().findFirst();
        if (firstSafe == null) {
          log.w('Safe $sbn not found, returning empty wallet list');
          state = state.copyWith(wallets: [], isLoading: false);
          return;
        }
        safe = firstSafe;
        _walletService.setDefaultSafeBoxNumber(safe.number);
      }

      if (widgetRef != null) {
        // Invalidate and wait for identity wallet provider
        widgetRef.invalidate(idtyWalletAsyncProvider);
        await widgetRef.read(idtyWalletAsyncProvider.future);
      }

      // Use a direct query instead of safe.wallets.toList() to avoid ObjectBox
      // ToMany backlink cache returning stale data after wallet creation/deletion.
      final query = _walletService.walletBox.query()..link(WalletEntity_.safe, SafeEntity_.number.equals(safe.number));
      final wallets = query.build().find()..sort((a, b) => a.number.compareTo(b.number));

      state = state.copyWith(wallets: wallets, isLoading: false, currentSafeNumber: safe.number);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Force refresh - reloads the list from the source
  void refresh() {
    loadWallets();
  }

  /// Update the wallets list locally without reloading
  void updateWallets(List<d.WalletEntity> wallets) {
    state = state.copyWith(wallets: wallets);
  }

  /// Clear wallets (used after safe deletion)
  void clear() {
    state = state.copyWith(wallets: []);
  }
}

/// Notifier for PIN state management
class PinStateNotifier extends Notifier<PinState> {
  @override
  PinState build() {
    return const PinState();
  }

  /// Set the PIN valid state
  void setValid(bool isValid) {
    state = state.copyWith(isValid: isValid);
  }

  /// Set the loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// Set the PIN length
  void setPinLength(int? length) {
    state = state.copyWith(pinLength: length);
  }

  /// Reset to initial state
  void reset() {
    state = const PinState();
  }

  /// Set PIN as validated with the given length
  void setValidated({required int pinLength}) {
    state = PinState(isValid: true, isLoading: false, pinLength: pinLength);
  }

  /// Set PIN as invalid
  void setInvalid() {
    state = state.copyWith(isValid: false, isLoading: false);
  }
}

/// Notifier for drag & drop state management
class DragDropNotifier extends Notifier<DragDropState> {
  @override
  DragDropState build() {
    return const DragDropState();
  }

  /// Set the wallet being dragged
  void setDragAddress(d.WalletEntity? wallet) {
    state = state.copyWith(dragAddress: wallet, clearDragAddress: wallet == null);
  }

  /// Set the wallet currently being hovered over
  void setLastFlyBy(d.WalletEntity? wallet) {
    if (state.lastFlyBy != wallet) {
      state = state.copyWith(lastFlyBy: wallet, clearLastFlyBy: wallet == null);
    }
  }

  /// Clear all drag state
  void clearDrag() {
    state = const DragDropState();
  }
}

/// Notifier for derivation state management
class DerivationStateNotifier extends Notifier<DerivationState> {
  @override
  DerivationState build() {
    return const DerivationState();
  }

  /// Set the mnemonic
  void setMnemonic(String mnemonic) {
    state = state.copyWith(mnemonic: mnemonic);
  }

  /// Clear the mnemonic
  void clearMnemonic() {
    state = state.copyWith(clearMnemonic: true);
  }

  /// Set the loading state
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }
}

/// Notifier for wallet actions (stateless operations)
class WalletActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  d.WalletService get _walletService => ref.read(walletServiceProvider);

  /// Generate a new derivation wallet
  ///
  /// If [customDerivation] is provided, creates a wallet with that specific derivation number.
  /// Otherwise, generates the next available derivation automatically.
  Future<void> generateNewDerivation(String name, {int? customDerivation}) async {
    ref.read(derivationStateProvider.notifier).setLoading(true);

    try {
      final safeNumber = _walletService.defaultSafeBoxNumber;

      if (customDerivation != null) {
        // Generate wallet with specific derivation number
        final wallets = ref.read(walletsListProvider).wallets;
        final newWalletNbr = wallets.isEmpty ? 0 : wallets.last.number + 1;

        // Get the mnemonic from the safe
        final firstWallet = ref.read(firstWalletProvider);
        if (firstWallet == null) throw Exception('No wallet available');
        final mnemonic = await _walletService.getSeed(address: firstWallet.address, pin: PinCodeService.pinCode);

        // Generate keypair with the custom derivation
        final keypair = await _walletService.getKeyPairFromMnemonic(
          mnemonic,
          derivation: customDerivation,
          keyPairType: d.Durt.defaultKeyPairType,
        );

        final newWallet = d.WalletEntity.create(
          address: keypair.address,
          number: newWalletNbr,
          derivation: customDerivation,
          name: name,
          imagePath: 'assets/avatars/${newWalletNbr % 4}.png',
          keyPairType: d.Durt.defaultKeyPairType,
        );

        final safe = _walletService.getSafeBox(safeNumber);
        newWallet.safe.target = safe;
        await _walletService.walletBox.putAsync(newWallet);
      } else {
        // Generate next available derivation
        final newWallet = await _walletService.generateNextDerivation(
          pinCode: PinCodeService.pinCode,
          safeBoxNumber: safeNumber,
          walletName: name,
        );

        newWallet.imagePath = 'assets/avatars/${newWallet.number % 4}.png';
        await _walletService.walletBox.putAsync(newWallet);
      }

      // Reload wallets list
      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: safeNumber);

      // Invalidate related providers
      invalidateProviders();
    } finally {
      ref.read(derivationStateProvider.notifier).setLoading(false);
    }
  }

  /// Generate a root wallet
  Future<void> generateRootWallet(String name) async {
    ref.read(derivationStateProvider.notifier).setLoading(true);

    try {
      final safeNumber = _walletService.defaultSafeBoxNumber;
      final wallets = ref.read(walletsListProvider).wallets;
      final newWalletNbr = wallets.isEmpty ? 0 : wallets.last.number + 1;

      final firstWallet = ref.read(firstWalletProvider);
      if (firstWallet == null) throw Exception('No wallet available');
      final walletData = await _walletService.generateRootKeypair(
        fromAddress: firstWallet.address,
        pinCode: PinCodeService.pinCode,
      );

      final newWallet = d.WalletEntity.create(
        address: walletData.address,
        number: newWalletNbr,
        name: name,
        imagePath: 'assets/avatars/${newWalletNbr % 4}.png',
        keyPairType: d.Durt.defaultKeyPairType,
      );

      final safe = _walletService.getSafeBox(safeNumber);
      newWallet.safe.target = safe;
      await _walletService.walletBox.putAsync(newWallet);

      await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: safeNumber);
      invalidateProviders();
    } finally {
      ref.read(derivationStateProvider.notifier).setLoading(false);
    }
  }

  /// Delete all wallets - returns true on success
  /// Navigation should be handled by the caller
  Future<bool> deleteAllWallets() async {
    try {
      await _walletService.clearWallets();
      await ref.read(configBoxProvider).removeAllAsync();

      final directory = await getApplicationDocumentsDirectory();
      final avatarFolder = Directory('${directory.path}/avatars/');
      if (await avatarFolder.exists()) {
        await avatarFolder.delete(recursive: true);
        await avatarFolder.create();
      }

      PinCodeService.pinCode = '';
      ref.read(walletsListProvider.notifier).clear();

      return true;
    } catch (e) {
      log.e('Failed to delete all wallets: $e');
      return false;
    }
  }

  /// Invalidate all safe-dependent providers after wallet/safe changes
  void invalidateProviders() {
    try {
      // Stream providers
      ref.invalidate(smartBalanceStreamProvider);
      ref.invalidate(balanceStreamProvider);
      ref.invalidate(persistentBalanceStreamProvider);
      ref.invalidate(idtyStatusStreamProvider);
      ref.invalidate(persistentIdtyStatusStreamProvider);
      ref.invalidate(smartCertificationStreamProvider);
      ref.invalidate(certificationStreamProvider);
      ref.invalidate(persistentCertificationStreamProvider);
      // Hybrid providers
      ref.invalidate(hybridIdentityNameProvider);
      ref.invalidate(hybridIdtyStatusProvider);
      ref.invalidate(hybridCertificationProvider);
      ref.invalidate(smartAccountConsumersProvider);
      // Identity & certification providers
      ref.invalidate(idtyWalletAsyncProvider);
      ref.invalidate(effectiveCertificationWalletProvider);
      ref.invalidate(selectedCertificationWalletProvider);
      ref.invalidate(certStateProvider);
      ref.invalidate(certificationExistsProvider);
      // History & data providers
      ref.invalidate(transfersOnlyHistoryProvider);
      ref.invalidate(combinedHistoryProvider);
      ref.invalidate(transactionHistoryProvider);
      ref.invalidate(certificationListProvider);
      ref.invalidate(safeOnChainDataProvider);

      log.i('Invalidated all safe-dependent providers after safe operation');
    } catch (e) {
      log.e('Error invalidating providers: $e');
    }
  }

  /// Centralized safe switch: updates safe number, clears caches, invalidates all providers, reloads wallets.
  /// This is the single entry point for changing the active safe.
  Future<void> switchSafe(int newSafeNumber) async {
    // 1. Update safe number
    ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(newSafeNumber);
    // 2. Force-refresh notifiers with instance caches
    try {
      ref.read(idtyWalletAsyncProvider.notifier).forceRefresh();
    } catch (_) {}
    // 3. Invalidate ALL safe-dependent providers
    invalidateProviders();
    // 4. Reload wallets for the new safe
    await ref.read(walletsListProvider.notifier).loadWallets(safeBoxNumber: newSafeNumber);
  }
}

// ============================================================================
// PROVIDERS
// ============================================================================

/// Provider for the wallets list state
final walletsListProvider = NotifierProvider<WalletsListNotifier, WalletsListState>(WalletsListNotifier.new);

/// Provider for PIN state
final pinStateProvider = NotifierProvider<PinStateNotifier, PinState>(PinStateNotifier.new);

/// Provider for drag & drop state
final dragDropProvider = NotifierProvider<DragDropNotifier, DragDropState>(DragDropNotifier.new);

/// Provider for derivation state
final derivationStateProvider = NotifierProvider<DerivationStateNotifier, DerivationState>(DerivationStateNotifier.new);

/// Provider for wallet actions (stateless)
final walletActionsProvider = NotifierProvider<WalletActionsNotifier, void>(WalletActionsNotifier.new);

// ============================================================================
// DERIVED PROVIDERS (COMPUTED)
// ============================================================================

/// Check if an address belongs to the user's wallets
final isOwnerProvider = Provider.family<bool, String>((ref, address) {
  final wallets = ref.watch(walletsListProvider).wallets;
  return wallets.any((wallet) => wallet.address == address);
});

/// Get wallet by address - searches current safe first, then falls back to global lookup
final walletByAddressProvider = Provider.family<d.WalletEntity?, String>((ref, address) {
  final walletsState = ref.watch(walletsListProvider);
  // Current safe first
  final currentSafeWallet = walletsState.wallets.where((w) => w.address == address).firstOrNull;
  if (currentSafeWallet != null) return currentSafeWallet;
  // Fallback: global lookup for external views
  final walletService = ref.read(walletServiceProvider);
  return walletService.walletBox.query(WalletEntity_.address.equals(address)).build().findFirst();
});

/// Check if wallets exist
final isWalletsExistsProvider = Provider<bool>((ref) {
  return ref.watch(walletsListProvider).wallets.isNotEmpty;
});

/// Get current safe number
final currentSafeNumberProvider = Provider<int>((ref) {
  return ref.watch(walletsListProvider).currentSafeNumber;
});

/// Groups of safes with their wallets, computed from ObjectBox.
/// Only rebuilds when walletsListProvider changes (wallet structure change),
/// NOT on every balance/block height update.
final safeWalletGroupsProvider = Provider<List<SafeWalletGroup>>((ref) {
  // Watch walletsListProvider to rebuild when wallets change
  ref.watch(walletsListProvider);
  final walletService = ref.read(walletServiceProvider);
  final currentSafe = ref.read(currentSafeNumberProvider);

  final allSafes = walletService.safeBox.getAll()..sort((a, b) => a.number.compareTo(b.number));
  return allSafes
      .map((safe) {
        final query = walletService.walletBox.query()..link(WalletEntity_.safe, SafeEntity_.number.equals(safe.number));
        final wallets = query.build().find()..sort((a, b) => a.number.compareTo(b.number));
        return SafeWalletGroup(safe: safe, wallets: wallets, isCurrent: safe.number == currentSafe);
      })
      .where((group) => group.wallets.isNotEmpty)
      .toList(growable: false);
});

/// Data class for safe + wallets grouping
class SafeWalletGroup {
  final d.SafeEntity safe;
  final List<d.WalletEntity> wallets;
  final bool isCurrent;

  const SafeWalletGroup({required this.safe, required this.wallets, required this.isCurrent});
}
