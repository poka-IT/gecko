import 'dart:io';

import 'package:durt2/durt2.dart' show WalletEntity, SafeEntity, SafeEntityExt, Durt;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/identity_providers.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/providers/stream_providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:path_provider/path_provider.dart';

class MyWalletsProvider with ChangeNotifier {
  late ProviderContainer _container;

  MyWalletsProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  List<WalletEntity> listWallets = [];
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;
  WalletEntity? _lastFlyBy;
  WalletEntity? dragAddress;

  WalletEntity? get lastFlyBy => _lastFlyBy;
  set lastFlyBy(WalletEntity? value) {
    if (_lastFlyBy != value) {
      _lastFlyBy = value;
      notifyListeners();
    }
  }

  bool isPinValid = false;
  bool isPinLoading = true;

  bool isOwner(String address) => listWallets.any((wallet) => wallet.address == address);

  int get getCurrentSafe => _container.read(walletServiceProvider).defaultSafeBoxNumber;

  bool get isWalletsExists => !_container.read(walletServiceProvider).safeBox.isEmpty();

  Future<List<WalletEntity>> readAllWallets({WidgetRef? ref, int? safeBoxNumber}) async {
    final sbn = safeBoxNumber ?? _container.read(walletServiceProvider).defaultSafeBoxNumber;

    final walletsExist = _container.read(walletServiceProvider).isWalletExist;
    if (!walletsExist) {
      listWallets = [];
      return [];
    }

    // Check if the requested safe actually exists before trying to get it
    SafeEntity? safe;
    try {
      safe = _container.read(walletServiceProvider).getSafeBox(sbn);
    } catch (e) {
      // Safe doesn't exist yet, this can happen during onboarding
      log.w('Safe $sbn not found, take the first safe: $e');
      // Get the first safe, not the number 0, the first of ObjectBox
      final firstSafe = _container.read(walletServiceProvider).safeBox.query().build().findFirst();
      if (firstSafe == null) {
        log.w('Safe $sbn not found, returning empty wallet list');
        return [];
      }
      safe = firstSafe;
      _container.read(walletServiceProvider).setDefaultSafeBoxNumber(safe.number);
    }

    if (ref != null) {
      // Need to invalidate the idtyWalletAsyncProvider before call to be sure idty wallet is well loaded
      ref.invalidate(idtyWalletAsyncProvider);
      // Wait for the identity wallet provider to complete before continuing
      await ref.read(idtyWalletAsyncProvider.future);
    }

    final wallets = safe.wallets.toList();
    wallets.sort((a, b) => a.number.compareTo(b.number));

    listWallets = wallets;

    return wallets;
  }

  WalletEntity? getWalletDataByAddress(String address) =>
      _container.read(walletServiceProvider).walletBox.query(WalletEntity_.address.equals(address)).build().findFirst();

  WalletEntity getDefaultWallet([int? safe]) {
    if (_container.read(walletServiceProvider).safeBox.isEmpty()) {
      return WalletEntity.create(address: '', number: 0, keyPairType: Durt.defaultKeyPairType);
    } else {
      safe ??= getCurrentSafe;

      // Check if the safe still exists before trying to access it
      try {
        final defaultWallet = _container.read(walletServiceProvider).safeBox.getNumber(safe).defaultAddress;
        if (defaultWallet == null) {
          return WalletEntity.create(address: '', number: 0, keyPairType: Durt.defaultKeyPairType);
        }
        return getWalletDataByAddress(defaultWallet) ??
            WalletEntity.create(address: '', number: 0, keyPairType: Durt.defaultKeyPairType);
      } catch (e) {
        // Safe doesn't exist anymore (probably deleted), return a default wallet
        log.w('Safe $safe not found in getDefaultWallet: $e');
        return WalletEntity.create(address: '', number: 0, keyPairType: Durt.defaultKeyPairType);
      }
    }
  }

  Future<int> deleteAllWallet(BuildContext context) async {
    try {
      log.w('DELETE ALL WALLETS ?');

      final answer = await showConfirmationDialog(
        context: context,
        message: 'areYouSureForgetAllSafes'.tr(),
        type: ConfirmationDialogType.warning,
      );
      if (answer) {
        // Use Durt2's clearWallets method which includes biometric cleanup
        await _container.read(walletServiceProvider).clearWallets();
        await _container.read(configBoxProvider).removeAllAsync();

        final directory = await getApplicationDocumentsDirectory();
        final avatarFolder = Directory('${directory.path}/avatars/');
        if (await avatarFolder.exists()) {
          await avatarFolder.delete(recursive: true);
          await avatarFolder.create();
        }

        PinCodeService.pinCode = '';

        // Clear the in-memory wallet list and notify listeners
        listWallets = [];
        notifyListeners();

        // ignore: use_build_context_synchronously
        await Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (Route<dynamic> route) => false);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<void> generateNewDerivation(BuildContext context, String name, [int? number]) async {
    isNewDerivationLoading = true;
    notifyListeners();

    // Give the UI a moment to rebuild and show the loading indicator.
    await Future.delayed(const Duration(milliseconds: 50));

    int? safeNumber = getCurrentSafe;

    // Let Durt2 handle wallet number generation and derivation creation
    final newWallet = await _container
        .read(walletServiceProvider)
        .generateNextDerivation(pinCode: PinCodeService.pinCode, safeBoxNumber: safeNumber, walletName: name);

    // Update avatar path based on the wallet number assigned by Durt2
    newWallet.imagePath = 'assets/avatars/${newWallet.number % 4}.png';
    // Save the updated wallet with avatar path
    await _container.read(walletServiceProvider).walletBox.putAsync(newWallet);

    await readAllWallets(safeBoxNumber: safeNumber);

    isNewDerivationLoading = false;

    // Defer the final notifyListeners to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      // Invalidate providers after wallet creation to fix state synchronization
      invalidateProviders();
    });
  }

  Future<void> generateRootWallet(BuildContext context, String name) async {
    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? safeNumber = getCurrentSafe;

    List<WalletEntity> walletConfig = await readAllWallets(safeBoxNumber: safeNumber);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number, p2.number);
    });

    if (walletConfig.isEmpty) {
      newWalletNbr = 0;
    } else {
      newWalletNbr = walletConfig.last.number + 1;
    }

    WalletEntity defaultWallet = getDefaultWallet(safeNumber);

    final walletData = await _container
        .read(walletServiceProvider)
        .generateRootKeypair(fromAddress: defaultWallet.address, pinCode: PinCodeService.pinCode);

    WalletEntity newWallet = WalletEntity.create(
      address: walletData.address,
      number: newWalletNbr,
      name: name,
      imagePath: 'assets/avatars/${newWalletNbr % 4}.png',
      keyPairType: Durt.defaultKeyPairType,
    );

    final safe = _container.read(walletServiceProvider).getSafeBox(safeNumber);
    newWallet.safe.target = safe;

    await _container.read(walletServiceProvider).walletBox.putAsync(newWallet);
    await readAllWallets(safeBoxNumber: safeNumber);

    isNewDerivationLoading = false;

    // Defer the final notifyListeners to avoid setState during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
      // Invalidate providers after wallet creation to fix state synchronization
      invalidateProviders();
    });
  }

  void reload() {
    notifyListeners();
  }

  /// Invalidate all Riverpod family providers to fix state synchronization issues
  /// This should be called after safe operations (create, switch, etc.)
  void invalidateProviders() {
    try {
      // Use the existing container from MyWalletsProvider to invalidate providers
      _container.invalidate(smartBalanceStreamProvider);
      _container.invalidate(balanceStreamProvider);
      _container.invalidate(persistentBalanceStreamProvider);
      _container.invalidate(idtyStatusStreamProvider);
      _container.invalidate(smartCertificationStreamProvider);
      _container.invalidate(certificationStreamProvider);
      _container.invalidate(persistentCertificationStreamProvider);
      _container.invalidate(transfersOnlyHistoryProvider);
      _container.invalidate(combinedHistoryProvider);
      _container.invalidate(transactionHistoryProvider);
      _container.invalidate(certificationListProvider);

      log.i('🔄 Invalidated all family providers after safe operation');
    } catch (e) {
      log.e('❌ Error invalidating providers: $e');
    }
  }
}
