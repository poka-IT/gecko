import 'dart:io';

import 'package:durt2/durt2.dart' show WalletEntity, SafeEntityExt, Durt, IdtyStatus;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
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

  WalletEntity? get idtyWallet =>
      listWallets.firstWhereOrNull((w) => w.isMember) ?? listWallets.firstWhereOrNull((w) => w.hasIdentity);

  List<WalletEntity> get listWalletsWithoutIdty => listWallets.where((w) => w.address != idtyWallet?.address).toList();

  Future<List<WalletEntity>> readAllWallets([int? safeBoxNumber]) async {
    final sbn = safeBoxNumber ?? _container.read(walletServiceProvider).defaultSafeBoxNumber;

    final walletsExist = _container.read(walletServiceProvider).isWalletExist;
    if (!walletsExist) {
      return [];
    }

    final safe = _container.read(walletServiceProvider).getSafeBox(sbn);

    final wallets = safe.wallets.toList();
    wallets.sort((a, b) => a.number.compareTo(b.number));

    // Check if Duniter is connected before trying to access storage service
    // If not connected (e.g., genesis hash validation failed), keep wallets with default status
    if (_container.read(durtProvider).isConnected) {
      try {
        final futures = wallets.map((wallet) => _container.read(storageServiceProvider).getIdtyStatus(wallet.address));
        final newStatuses = await Future.wait(futures);

        for (var i = 0; i < wallets.length; i++) {
          wallets[i].identityStatus = newStatuses[i];
        }
      } catch (e) {
        log.e('Error getting identity statuses: $e');
        // If there's an error getting identity statuses, keep wallets with their existing status
        // This prevents the app from crashing when storage service is not available
        for (var wallet in wallets) {
          wallet.identityStatus = IdtyStatus.unknown;
        }
      }
    } else {
      // If Duniter is not connected, set all wallets to unknown status
      log.w('Duniter not connected, setting all wallets to unknown identity status');
      for (var wallet in wallets) {
        wallet.identityStatus = IdtyStatus.unknown;
      }
    }

    await _container.read(walletServiceProvider).walletBox.putManyAsync(wallets);

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

  Future<bool> askPinCode({bool force = false}) async {
    final defaultWallet = getDefaultWallet();

    if (pinCode.isEmpty || force) {
      pinCode = '';
      await Navigator.push(
        homeContext,
        MaterialPageRoute(builder: (homeContext) => UnlockingWallet(wallet: defaultWallet)),
      );
    }
    return pinCode.isNotEmpty;
  }

  WalletEntity? getWalletDataByAddress(String address) =>
      _container.read(walletServiceProvider).walletBox.query(WalletEntity_.address.equals(address)).build().findFirst();

  WalletEntity getDefaultWallet([int? safe]) {
    if (_container.read(walletServiceProvider).safeBox.isEmpty()) {
      return WalletEntity.create(
        address: '',
        number: 0,
        keyPairType: Durt.defaultKeyPairType,
        identityStatus: IdtyStatus.unknown,
      );
    } else {
      safe ??= getCurrentSafe;

      final defaultWallet = _container.read(walletServiceProvider).safeBox.getNumber(safe).defaultAddress;
      if (defaultWallet == null) {
        return WalletEntity.create(
          address: '',
          number: 0,
          keyPairType: Durt.defaultKeyPairType,
          identityStatus: IdtyStatus.unknown,
        );
      }
      return getWalletDataByAddress(defaultWallet) ??
          WalletEntity.create(
            address: '',
            number: 0,
            keyPairType: Durt.defaultKeyPairType,
            identityStatus: IdtyStatus.unknown,
          );
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
        await _container.read(walletServiceProvider).walletBox.removeAllAsync();
        await _container.read(walletServiceProvider).safeBox.removeAllAsync();
        await _container.read(configBoxProvider).removeAllAsync();

        final directory = await getApplicationDocumentsDirectory();
        final avatarFolder = Directory('${directory.path}/avatars/');
        if (await avatarFolder.exists()) {
          await avatarFolder.delete(recursive: true);
          await avatarFolder.create();
        }

        myWalletProvider.pinCode = '';

        // ignore: use_build_context_synchronously
        await Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<void> generateNewDerivation(BuildContext context, String name, [int? number]) async {
    isNewDerivationLoading = true;
    notifyListeners();

    final List idList = await getNextWalletNumberAndDerivation();
    int newWalletNbr = idList[0];
    int newDerivationNbr = number ?? idList[1];

    int? safeNumber = getCurrentSafe;

    WalletEntity defaultWallet = getDefaultWallet();

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
      identityStatus: IdtyStatus.unknown,
    );

    final safe = _container.read(walletServiceProvider).getSafeBox(safeNumber);
    newWallet.safe.target = safe;

    await _container.read(walletServiceProvider).walletBox.putAsync(newWallet);

    await readAllWallets();

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<void> generateRootWallet(BuildContext context, String name) async {
    final myWalletProvider = old_provider.Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? safeNumber = getCurrentSafe;

    List<WalletEntity> walletConfig = await readAllWallets(safeNumber);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number, p2.number);
    });

    if (walletConfig.isEmpty) {
      newWalletNbr = 0;
    } else {
      newWalletNbr = walletConfig.last.number + 1;
    }

    WalletEntity defaultWallet = myWalletProvider.getDefaultWallet();

    final walletData = await _container
        .read(walletServiceProvider)
        .generateRootKeypair(fromAddress: defaultWallet.address, pinCode: pinCode);

    WalletEntity newWallet = WalletEntity.create(
      address: walletData.address,
      number: newWalletNbr,
      name: name,
      imagePath: 'assets/avatars/${newWalletNbr % 4}.png',
      keyPairType: Durt.defaultKeyPairType,
      identityStatus: IdtyStatus.unknown,
    );

    final safe = _container.read(walletServiceProvider).getSafeBox(safeNumber);
    newWallet.safe.target = safe;

    await _container.read(walletServiceProvider).walletBox.putAsync(newWallet);
    await readAllWallets();

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<List<int>> getNextWalletNumberAndDerivation({int? safeNumber}) async {
    safeNumber ??= getCurrentSafe;

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
}
