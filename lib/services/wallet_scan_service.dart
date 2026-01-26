import 'dart:async';
import 'package:durt2/durt2.dart' show WalletBalance, WalletEntity, Durt;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/services/mnemonic_service.dart';

/// Service for scanning wallet derivations and importing wallets.
///
/// This service provides pure functions for wallet derivation scanning operations.
/// It does not manage UI state directly but provides the core logic.
class WalletScanService {
  final Ref _ref;

  WalletScanService(this._ref);

  /// Scan wallet derivations for existing balances and import them.
  ///
  /// Returns a [WalletScanResult] with the scan results and any detected wallets.
  Future<WalletScanResult> scanDerivations({
    required MnemonicResult mnemonicResult,
    required Function(WalletScanStatus) onStatusChanged,
    required Function(int) onWalletCountChanged,
    int maxDerivations = 30,
    Duration timeout = const Duration(seconds: 120),
  }) async {
    try {
      return await _performScan(
        mnemonicResult: mnemonicResult,
        onStatusChanged: onStatusChanged,
        onWalletCountChanged: onWalletCountChanged,
        maxDerivations: maxDerivations,
      ).timeout(timeout, onTimeout: () => _handleScanTimeout());
    } catch (e) {
      log.e('Error scanning derivations: $e');
      await _cleanupFailedScan();
      return WalletScanResult.error('Error scanning derivations: $e');
    }
  }

  Future<WalletScanResult> _performScan({
    required MnemonicResult mnemonicResult,
    required Function(WalletScanStatus) onStatusChanged,
    required Function(int) onWalletCountChanged,
    required int maxDerivations,
  }) async {
    if (!_ref.read(durtProvider).isConnected) {
      return WalletScanResult.error('Not connected to network');
    }

    int scannedWalletCount = 0;
    final Map<String, int> addressToDerivation = {};
    bool hasWallets = false;

    // 1. SCAN ROOT WALLET
    onStatusChanged(WalletScanStatus.scanningRoot);
    final rootScanResult = await _scanRootWallet(mnemonicResult.englishMnemonic);
    if (rootScanResult.hasBalance) {
      hasWallets = true;
      scannedWalletCount++;
      onWalletCountChanged(scannedWalletCount);
    }

    // 2. GENERATE DERIVATION KEYPAIRS
    onStatusChanged(WalletScanStatus.generatingKeypairs);
    final derivationNumbers = [for (var i = 0; i < maxDerivations; i += 1) i];
    final keypairFutures = derivationNumbers
        .map((derivationNbr) => _generateKeypair(mnemonicResult.englishMnemonic, derivationNbr))
        .toList();

    final keypairResults = await Future.wait(keypairFutures);
    for (final entry in keypairResults) {
      addressToDerivation.putIfAbsent(entry.address, () => entry.derivation);
    }

    // 3. CHECK FOR DUPLICATE ADDRESSES
    final duplicateCheckResult = await _checkForDuplicateAddresses(
      rootAddress: rootScanResult.address,
      derivedAddresses: addressToDerivation.keys.toList(),
      includeRoot: rootScanResult.hasBalance,
    );

    if (duplicateCheckResult.hasDuplicates) {
      await _cleanupFailedScan();
      return WalletScanResult.error('Safe already exists');
    }

    // 4. SCAN BALANCES
    onStatusChanged(WalletScanStatus.scanningBalances);
    final balanceMap = await _scanBalances(addressToDerivation.keys.toList());
    final validWallets = balanceMap.entries.where((entry) => entry.value.free > BigInt.zero).toList();

    if (validWallets.isNotEmpty) {
      hasWallets = true;
    }

    // 5. IMPORT WALLETS
    onStatusChanged(WalletScanStatus.importingWallets);
    final importedWallets = await _importWallets(
      validWallets: validWallets,
      addressToDerivation: addressToDerivation,
      currentWalletCount: scannedWalletCount,
      onWalletCountChanged: onWalletCountChanged,
    );

    onStatusChanged(WalletScanStatus.completed);
    return WalletScanResult.success(
      hasWallets: hasWallets,
      totalWallets: scannedWalletCount + importedWallets.length,
      importedWallets: importedWallets,
    );
  }

  Future<RootScanResult> _scanRootWallet(String englishMnemonic) async {
    try {
      final keypair = await _ref.read(walletServiceProvider).getKeyPairFromMnemonic(englishMnemonic);
      final address = keypair.address;

      final balance = await _ref
          .read(storageServiceProvider)
          .getBalance(address)
          .timeout(const Duration(seconds: 1), onTimeout: () => WalletBalance.empty());

      if (balance.free > BigInt.zero) {
        // Import root wallet
        final walletName = 'myRootWallet'.tr();
        final actualSafeNumber = _ref.read(walletServiceProvider).defaultSafeBoxNumber;
        final safe = _ref.read(walletServiceProvider).getSafeBox(actualSafeNumber);

        final rootWallet = WalletEntity.create(
          address: address,
          name: walletName,
          imagePath: 'assets/avatars/0.png',
          keyPairType: Durt.defaultKeyPairType,
        );

        rootWallet.safe.target = safe;
        await _ref.read(walletServiceProvider).walletBox.putAsync(rootWallet);

        return RootScanResult(address: address, hasBalance: true);
      }

      return RootScanResult(address: address, hasBalance: false);
    } catch (e) {
      log.e('Error scanning root wallet: $e');
      return RootScanResult(address: '', hasBalance: false);
    }
  }

  Future<KeypairResult> _generateKeypair(String englishMnemonic, int derivation) async {
    final keypair = await _ref
        .read(walletServiceProvider)
        .getKeyPairFromMnemonic(englishMnemonic, derivation: derivation, keyPairType: Durt.defaultKeyPairType);
    return KeypairResult(address: keypair.address, derivation: derivation);
  }

  Future<DuplicateCheckResult> _checkForDuplicateAddresses({
    required String? rootAddress,
    required List<String> derivedAddresses,
    required bool includeRoot,
  }) async {
    final allAddresses = <String>[];

    if (includeRoot && rootAddress != null) {
      allAddresses.add(rootAddress);
    }
    allAddresses.addAll(derivedAddresses);

    final duplicateAddresses = <String>[];
    final currentSafeNumber = _ref.read(walletServiceProvider).defaultSafeBoxNumber;

    for (final address in allAddresses) {
      final existingWallet = _ref
          .read(walletServiceProvider)
          .walletBox
          .query(WalletEntity_.address.equals(address))
          .build()
          .findFirst();

      if (existingWallet != null) {
        final walletSafeNumber = existingWallet.safe.target?.number;
        if (walletSafeNumber != null && walletSafeNumber != currentSafeNumber) {
          duplicateAddresses.add(address);
        }
      }
    }

    return DuplicateCheckResult(hasDuplicates: duplicateAddresses.isNotEmpty, duplicateAddresses: duplicateAddresses);
  }

  Future<Map<String, WalletBalance>> _scanBalances(List<String> addresses) async {
    try {
      final balanceList = await _ref
          .read(storageServiceProvider)
          .getBalances(addresses)
          .timeout(const Duration(seconds: 20));

      // Remove addresses with zero balance
      balanceList.removeWhere((key, value) => value.free == BigInt.zero);
      return balanceList;
    } catch (e) {
      log.e('Error scanning balances: $e');
      throw TimeoutException('Timeout scanning derivations');
    }
  }

  Future<List<WalletEntity>> _importWallets({
    required List<MapEntry<String, WalletBalance>> validWallets,
    required Map<String, int> addressToDerivation,
    required int currentWalletCount,
    required Function(int) onWalletCountChanged,
  }) async {
    if (validWallets.isEmpty) {
      return [];
    }

    // Sort wallets by derivation number to preserve order
    final sortedWallets = validWallets.toList()
      ..sort((a, b) => addressToDerivation[a.key]!.compareTo(addressToDerivation[b.key]!));

    final actualSafeNumber = _ref.read(walletServiceProvider).defaultSafeBoxNumber;
    final safe = _ref.read(walletServiceProvider).getSafeBox(actualSafeNumber);

    final importedWallets = <WalletEntity>[];

    // Create and save wallets one by one to ensure correct numbering
    for (int i = 0; i < sortedWallets.length; i++) {
      final walletAddress = sortedWallets[i].key;
      final walletIndex = currentWalletCount + i;
      final walletName = walletIndex == 0 ? 'currentWallet'.tr() : '${'wallet'.tr()} ${walletIndex + 1}';

      final wallet = WalletEntity.create(
        address: walletAddress,
        name: walletName,
        derivation: addressToDerivation[walletAddress],
        imagePath: 'assets/avatars/${walletIndex % 4}.png',
        keyPairType: Durt.defaultKeyPairType,
        number: _ref.read(walletServiceProvider).getNextWalletNumber,
      );

      wallet.safe.target = safe;

      // Save immediately to update the count for the next wallet
      await _ref.read(walletServiceProvider).walletBox.putAsync(wallet);
      importedWallets.add(wallet);
      onWalletCountChanged(currentWalletCount + i + 1);
    }

    return importedWallets;
  }

  Future<WalletScanResult> _handleScanTimeout() async {
    await _cleanupFailedScan();
    return WalletScanResult.timeout();
  }

  Future<void> _cleanupFailedScan() async {
    try {
      final actualSafeNumber = _ref.read(walletServiceProvider).defaultSafeBoxNumber;
      await _ref.read(walletServiceProvider).deleteSafe(actualSafeNumber);

      // Restore previous defaultSafeBoxNumber
      final safeBox = _ref.read(walletServiceProvider).safeBox;
      if (!safeBox.isEmpty()) {
        final allSafes = safeBox.getAll();
        if (allSafes.isNotEmpty) {
          final maxSafeNumber = allSafes.map((s) => s.number).reduce((a, b) => a > b ? a : b);
          _ref.read(defaultSafeBoxNumberProvider.notifier).setDefaultSafeBoxNumber(maxSafeNumber);
          // Invalidate identity providers to ensure they use the new safe
          _ref.invalidate(idtyWalletAsyncProvider);
          _ref.invalidate(identityWalletsAsyncProvider);
        }
      }
    } catch (e) {
      log.e('Error during cleanup: $e');
    }
  }
}

/// Status of wallet derivation scanning process.
enum WalletScanStatus { none, scanningRoot, generatingKeypairs, scanningBalances, importingWallets, completed }

/// Result of wallet derivation scanning.
class WalletScanResult {
  final bool isSuccess;
  final bool isTimeout;
  final bool hasWallets;
  final int totalWallets;
  final List<WalletEntity> importedWallets;
  final String? errorMessage;

  const WalletScanResult._({
    required this.isSuccess,
    required this.isTimeout,
    required this.hasWallets,
    required this.totalWallets,
    required this.importedWallets,
    this.errorMessage,
  });

  factory WalletScanResult.success({
    required bool hasWallets,
    required int totalWallets,
    required List<WalletEntity> importedWallets,
  }) {
    return WalletScanResult._(
      isSuccess: true,
      isTimeout: false,
      hasWallets: hasWallets,
      totalWallets: totalWallets,
      importedWallets: importedWallets,
    );
  }

  factory WalletScanResult.error(String message) {
    return WalletScanResult._(
      isSuccess: false,
      isTimeout: false,
      hasWallets: false,
      totalWallets: 0,
      importedWallets: [],
      errorMessage: message,
    );
  }

  factory WalletScanResult.timeout() {
    return const WalletScanResult._(
      isSuccess: false,
      isTimeout: true,
      hasWallets: false,
      totalWallets: 0,
      importedWallets: [],
      errorMessage: 'Scan timed out',
    );
  }

  bool get hasError => !isSuccess && !isTimeout;
}

/// Helper classes for internal results
class RootScanResult {
  final String address;
  final bool hasBalance;

  const RootScanResult({required this.address, required this.hasBalance});
}

class KeypairResult {
  final String address;
  final int derivation;

  const KeypairResult({required this.address, required this.derivation});
}

class DuplicateCheckResult {
  final bool hasDuplicates;
  final List<String> duplicateAddresses;

  const DuplicateCheckResult({required this.hasDuplicates, required this.duplicateAddresses});
}
