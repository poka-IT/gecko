import 'dart:io';

import 'package:durt2/durt2.dart' show Durt, IdtyStatus, WalletData;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  String pinCode = '';
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;
  WalletData? lastFlyBy;
  WalletData? dragAddress;
  bool isPinValid = false;
  bool isPinLoading = true;

  bool isOwner(String address) => listWallets.any((wallet) => wallet.address == address);

  int get getCurrentSafe => Durt.i.wallets.defaultSafeBoxNumber;

  bool get isWalletsExists => Durt.i.wallets.safeBox.isNotEmpty;

  WalletData? get idtyWallet => listWallets.firstWhereOrNull((w) => w.isMembre) ?? listWallets.firstWhereOrNull((w) => w.hasIdentity);

  List<WalletData> get listWalletsWithoutIdty => listWallets.where((w) => w.address != idtyWallet?.address).toList();

  Future<List<WalletData>> readAllWallets([int? safe]) async {
    // final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    safe = safe ?? getCurrentSafe;
    listWallets.clear();
    final wallets = Durt.i.wallets.walletDataBox.toMap().values.toList();
    Map<String, WalletData> walletsToScan = {};
    for (var walletFromBox in wallets) {
      if (walletFromBox.safeBoxNumber != safe) {
        continue;
      }
      if (walletFromBox.identityStatus == IdtyStatus.unknown) {
        walletsToScan.putIfAbsent(walletFromBox.address, (() => walletFromBox));
      } else {
        listWallets.add(walletFromBox);
      }
    }

    // final idtyStatusList =
    //     await sub.idtyStatusMulti(walletsToScan.keys.toList());
    for (final wallet in walletsToScan.values) {
      // wallet.identityStatus = idtyStatusList[n];
      // if (Durt.i.wallets.walletDataBox.containsKey(wallet.address)) continue;
      // Durt.i.wallets.walletDataBox.put(wallet.address, wallet);

      listWallets.add(wallet);
    }

    listWallets.sort((p1, p2) => Comparable.compare(p1.number, p2.number));

    return listWallets;
  }

  WalletData? getWalletDataById(List<int?> id) {
    if (id.isEmpty) return WalletData(address: '', isOwned: true);
    int? safe = id[0];
    int? nbr = id[1];
    WalletData? targetedWallet;

    Durt.i.wallets.walletDataBox.toMap().forEach((key, value) {
      if (value.safeBoxNumber == safe && value.number == nbr) {
        targetedWallet = value;
        return;
      }
    });

    return targetedWallet;
  }

  Future<bool> askPinCode({bool force = false}) async {
    final defaultWallet = getDefaultWallet();

    if (pinCode.isEmpty || force) {
      pinCode = '';
      await Navigator.push(
        homeContext,
        MaterialPageRoute(
          builder: (homeContext) => UnlockingWallet(wallet: defaultWallet),
        ),
      );
    }
    return pinCode.isNotEmpty;
  }

  WalletData? getWalletDataByAddress(String address) => Durt.i.wallets.walletDataBox.toMap().values.firstWhereOrNull((wallet) => wallet.address == address);

  WalletData getDefaultWallet([int? safe]) {
    if (Durt.i.wallets.safeBox.isEmpty) {
      return WalletData(address: '', safeBoxNumber: 0, number: 0, isOwned: true);
    } else {
      safe ??= getCurrentSafe;
      final defaultWallet = Durt.i.wallets.safeBox.get(safe)!.defaultAddress;
      if (defaultWallet == null) {
        return WalletData(address: '', safeBoxNumber: safe, number: 0, isOwned: true);
      }
      return getWalletDataByAddress(defaultWallet) ?? WalletData(address: '', safeBoxNumber: safe, number: 0, isOwned: true);
    }
  }

  Future<int> deleteAllWallet(BuildContext context) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE ALL WALLETS ?');

      final answer = await showConfirmationDialog(
        context: context,
        message: 'areYouSureForgetAllSafes'.tr(),
        type: ConfirmationDialogType.warning,
      );
      if (answer) {
        await Durt.i.wallets.walletDataBox.clear();
        await Durt.i.wallets.safeBox.clear();
        await configBox.delete('defaultWallet');
        // await sub.deleteAllAccounts();

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

    WalletData defaultWallet = getDefaultWallet();

    // ignore: use_build_context_synchronously
    final walletData = await Durt.i.wallets.derive(fromAddress: defaultWallet.address, derivation: newDerivationNbr, pinCode: pinCode);

    WalletData newWallet = WalletData(
        safeBoxNumber: safeNumber,
        address: walletData.address,
        number: newWalletNbr,
        name: name,
        derivation: newDerivationNbr,
        imagePath: '${newWalletNbr % 4}.png',
        isOwned: true);

    await Durt.i.wallets.walletDataBox.put(newWallet.address, newWallet);
    await readAllWallets();

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<void> generateRootWallet(BuildContext context, String name) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? safeNumber = getCurrentSafe;

    List<WalletData> walletConfig = await readAllWallets(safeNumber);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number, p2.number);
    });

    if (walletConfig.isEmpty) {
      newWalletNbr = 0;
    } else {
      newWalletNbr = walletConfig.last.number + 1;
    }

    WalletData defaultWallet = myWalletProvider.getDefaultWallet();

    final walletData = await Durt.i.wallets.generateRootKeypair(fromAddress: defaultWallet.address, pinCode: pinCode);

    WalletData newWallet = WalletData(
        safeBoxNumber: safeNumber,
        address: walletData.address,
        number: newWalletNbr,
        name: name,
        derivation: -1,
        imagePath: '${newWalletNbr % 4}.png',
        isOwned: true);

    await Durt.i.wallets.walletDataBox.put(newWallet.address, newWallet);
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
