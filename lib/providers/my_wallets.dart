import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/myWallets/unlocking_wallet.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  WalletData? idtyWallet;
  List<WalletData> listWalletsWithoutIdty = [];
  String pinCode = '';
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;
  WalletData? lastFlyBy;
  WalletData? dragAddress;
  bool isPinValid = false;
  bool isPinLoading = true;

  int getCurrentChest() {
    if (configBox.get('currentChest') == null) {
      configBox.put('currentChest', 0);
    }

    return configBox.get('currentChest');
  }

  bool isWalletsExists() => chestBox.isNotEmpty;

  Future<List<WalletData>> readAllWallets([int? chest]) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    chest = chest ?? getCurrentChest();
    listWallets.clear();
    final wallets = walletBox.toMap().values.toList();
    Map<String, WalletData> walletsToScan = {};
    for (var walletFromBox in wallets) {
      if (walletFromBox.chest != chest) {
        continue;
      }
      if (walletFromBox.identityStatus == IdtyStatus.unknown) {
        walletsToScan.putIfAbsent(walletFromBox.address, (() => walletFromBox));
      } else {
        listWallets.add(walletFromBox);
      }
    }

    // update all idty status in lists
    int n = 0;
    final idtyStatusList = await sub.idtyStatusMulti(walletsToScan.keys.toList());
    for (final wallet in walletsToScan.values) {
      wallet.identityStatus = idtyStatusList[n];
      walletBox.put(wallet.address, wallet);
      listWallets.add(wallet);
      n++;
    }

    listWallets.sort((p1, p2) => Comparable.compare(p1.number!, p2.number!));

    idtyWallet = listWallets.firstWhereOrNull((w) => w.hasIdentity);

    listWalletsWithoutIdty = listWallets.toList();
    listWalletsWithoutIdty.removeWhere((w) => w.address == idtyWallet?.address);

    return listWallets;
  }

  WalletData? getWalletDataById(List<int?> id) {
    if (id.isEmpty) return WalletData(address: '', isOwned: true);
    int? chest = id[0];
    int? nbr = id[1];
    WalletData? targetedWallet;

    walletBox.toMap().forEach((key, value) {
      if (value.chest == chest && value.number == nbr) {
        targetedWallet = value;
        return;
      }
    });

    return targetedWallet;
  }

  Future<bool> askPinCode() async {
    final defaultWallet = getDefaultWallet();

    if (pinCode.isEmpty) {
      await Navigator.push(
        homeContext,
        MaterialPageRoute(
          builder: (homeContext) => UnlockingWallet(wallet: defaultWallet),
        ),
      );
    }
    return pinCode.isNotEmpty;
  }

  WalletData? getWalletDataByAddress(String address) {
    WalletData? targetedWallet;

    walletBox.toMap().forEach((key, value) {
      if (value.address == address) {
        targetedWallet = value;
        return;
      }
    });

    return targetedWallet;
  }

  WalletData getDefaultWallet([int? chest]) {
    if (chestBox.isEmpty) {
      return WalletData(address: '', chest: 0, number: 0, isOwned: true);
    } else {
      chest ??= getCurrentChest();
      int? defaultWalletNumber = chestBox.get(chest)!.defaultWallet;
      return getWalletDataById([chest, defaultWalletNumber]) ?? WalletData(address: '', chest: chest, number: 0, isOwned: true);
    }
  }

  Future<int> deleteAllWallet(context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE ALL WALLETS ?');

      final bool? answer = await (confirmPopup(context, 'areYouSureForgetAllChests'.tr()));
      if (answer!) {
        await walletBox.clear();
        await chestBox.clear();
        await configBox.delete('defaultWallet');
        await sub.deleteAllAccounts();

        final directory = await getApplicationDocumentsDirectory();
        final avatarFolder = Directory('${directory.path}/avatars/');
        if (await avatarFolder.exists()) {
          await avatarFolder.delete(recursive: true);
          await avatarFolder.create();
        }

        myWalletProvider.pinCode = '';

        await Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<void> generateNewDerivation(context, String name, [int? number]) async {
    isNewDerivationLoading = true;
    notifyListeners();

    final List idList = await getNextWalletNumberAndDerivation();
    int newWalletNbr = idList[0];
    int newDerivationNbr = number ?? idList[1];

    int? chest = getCurrentChest();

    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = getDefaultWallet();

    final address = await sub.derive(context, defaultWallet.address, newDerivationNbr, pinCode);

    WalletData newWallet = WalletData(
        chest: chest,
        address: address,
        number: newWalletNbr,
        name: name,
        derivation: newDerivationNbr,
        imageDefaultPath: '${newWalletNbr % 4}.png',
        isOwned: true);

    await walletBox.put(newWallet.address, newWallet);
    await readAllWallets();

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<void> generateRootWallet(context, String name) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? chest = getCurrentChest();

    List<WalletData> walletConfig = await readAllWallets(chest);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    if (walletConfig.isEmpty) {
      newWalletNbr = 0;
    } else {
      newWalletNbr = walletConfig.last.number! + 1;
    }
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = myWalletProvider.getDefaultWallet();

    final address = await sub.generateRootKeypair(defaultWallet.address, pinCode);

    WalletData newWallet = WalletData(
        chest: chest, address: address, number: newWalletNbr, name: name, derivation: -1, imageDefaultPath: '${newWalletNbr % 4}.png', isOwned: true);

    await walletBox.put(newWallet.address, newWallet);
    await readAllWallets();

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<List<int>> getNextWalletNumberAndDerivation({int? chestNumber}) async {
    chestNumber ??= getCurrentChest();

    listWallets.sort((p1, p2) => p1.number!.compareTo(p2.number!));

    if (listWallets.isEmpty) {
      return [0, 0];
    }

    final maxDerivation = listWallets.map((w) => w.derivation ?? -1).reduce((max, value) => value > max ? value : max);

    final newDerivationNbr = maxDerivation == -1 ? 0 : maxDerivation + 1;

    final newWalletNbr = listWallets.last.number! + 1;

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
