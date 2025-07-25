import 'dart:io';

import 'package:durt2/durt2.dart' show WalletEntity, SafeEntity, SafeEntityExt, Durt, IdtyStatus;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/providers/transaction_history_providers.dart';
import 'package:gecko/providers/certification_list_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart' as old_provider;

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
  String pinCode = '';
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;
  WalletEntity? lastFlyBy;
  WalletEntity? dragAddress;
  bool isPinValid = false;
  bool isPinLoading = true;

  bool isOwner(String address) => listWallets.any((wallet) => wallet.address == address);

  int get getCurrentSafe => _container.read(walletServiceProvider).defaultSafeBoxNumber;

  bool get isWalletsExists => !_container.read(walletServiceProvider).safeBox.isEmpty();

  // Removed sync version - use getIdtyWalletAsync() instead

  // New async method to get identity wallet based on real-time status
  Future<WalletEntity?> getIdtyWalletAsync() async {
    try {
      final storageService = _container.read(storageServiceProvider);

      // Check each wallet for member status first, then identity status
      for (final wallet in listWallets) {
        final status = await storageService.getIdtyStatus(wallet.address);
        if (status == IdtyStatus.validated) {
          return wallet; // Return first member wallet
        }
      }

      // If no member found, look for any identity
      for (final wallet in listWallets) {
        final status = await storageService.getIdtyStatus(wallet.address);
        if (status != IdtyStatus.none && status != IdtyStatus.unknown) {
          return wallet; // Return first wallet with identity
        }
      }

      return null; // No identity found
    } catch (e) {
      log.e('Error getting identity wallet: $e');
      return listWallets.isNotEmpty ? listWallets.first : null;
    }
  }

  // Removed sync version - use getWalletsWithoutIdtyAsync() instead

  // New async method to get wallets without identity
  Future<List<WalletEntity>> getWalletsWithoutIdtyAsync() async {
    final idtyWallet = await getIdtyWalletAsync();
    return listWallets.where((w) => w.address != idtyWallet?.address).toList();
  }

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

  WalletEntity? getWalletDataById(List<int?> id) {
    if (id.length < 2 || id[0] == null || id[1] == null) {
      return null;
    }

    final int safeNumber = id[0]!;
    final int walletNumber = id[1]!;

    final qBuilder = _container.read(walletServiceProvider).walletBox.query(WalletEntity_.number.equals(walletNumber));

    qBuilder.link(WalletEntity_.safe, SafeEntity_.number.equals(safeNumber));

    final wallet = qBuilder.build().findFirst();

    return wallet;
  }

  Future<bool> askPinCode({bool force = false, bool canSwitch = false}) async {
    final defaultWallet = getDefaultWallet();

    if (pinCode.isEmpty || force) {
      pinCode = '';
      final result = await Navigator.pushNamed(
        homeContext,
        RouteNames.unlockingWallet,
        arguments: UnlockingWalletArguments(wallet: defaultWallet, canSwitch: canSwitch),
      );
      // Only continue if we actually got a valid PIN back
      if (result == null) return false;
    }
    return pinCode.isNotEmpty;
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
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);
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

        myWalletProvider.pinCode = '';

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

    final List idList = await getNextWalletNumberAndDerivation(safeNumber: safeNumber);
    int newWalletNbr = idList[0];
    int newDerivationNbr = number ?? idList[1];

    WalletEntity defaultWallet = getDefaultWallet(safeNumber);

    // ignore: use_build_context_synchronously
    final walletData = await _container
        .read(walletServiceProvider)
        .derive(fromAddress: defaultWallet.address, derivation: newDerivationNbr, pinCode: pinCode);

    WalletEntity newWallet = WalletEntity.create(
      address: walletData.address,
      number: newWalletNbr,
      name: name,
      derivation: newDerivationNbr,
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
        .generateRootKeypair(fromAddress: defaultWallet.address, pinCode: pinCode);

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

  Future<List<int>> getNextWalletNumberAndDerivation({required int safeNumber}) async {
    await readAllWallets(safeBoxNumber: safeNumber);

    listWallets.sort((p1, p2) => p1.number.compareTo(p2.number));

    if (listWallets.isEmpty) {
      return [0, 0];
    }

    final maxDerivation = listWallets.map((w) => w.derivation ?? -1).reduce((max, value) => value > max ? value : max);

    final newDerivationNbr = maxDerivation == -1 ? 0 : maxDerivation + 1;

    final newWalletNbr = listWallets.last.number + 1;

    return [newWalletNbr, newDerivationNbr];
  }

  int lockPin = 0;
  Future debounceResetPinCode([int minutes = 15]) async {
    lockPin++;
    final actualLock = lockPin;
    await Future.delayed(Duration(seconds: configBox.get('isCacheChecked') ? minutes * 60 : 1));
    log.i('reset pin code, lock $actualLock ...');
    if (actualLock == lockPin) pinCode = '';
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
