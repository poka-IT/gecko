import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyWalletsProvider extends ChangeNotifier {
  List<WalletData> listWallets = [];
  String pinCode = '';
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;
  String lastFlyBy = '';
  String dragAddress = '';
  bool isPinValid = false;
  bool isPinLoading = true;

  int getCurrentChest() {
    if (configBox.get('currentChest') == null) {
      configBox.put('currentChest', 0);
    }

    return configBox.get('currentChest');
  }

  bool checkIfWalletExist() {
    if (chestBox.isEmpty) {
      // log.i('No wallets detected');
      return false;
    } else {
      return true;
    }
  }

  List<WalletData> readAllWallets([int? chest]) {
    chest = chest ?? configBox.get('currentChest') ?? 0;
    listWallets.clear();
    walletBox.toMap().forEach((key, value) {
      if (value.chest == chest) {
        listWallets.add(value);
      }
    });

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
      return getWalletDataById([chest, defaultWalletNumber]) ??
          WalletData(address: '', chest: chest, number: 0, isOwned: true);
    }
  }

  Future<int> deleteAllWallet(context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE ALL WALLETS ?');

      final bool? answer =
          await (confirmPopup(context, 'areYouSureForgetAllChests'.tr()));
      if (answer!) {
        await walletBox.clear();
        await chestBox.clear();
        await configBox.delete('defaultWallet');
        await sub.deleteAllAccounts();

        myWalletProvider.pinCode = '';

        await Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          ModalRoute.withName('/'),
        );
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<void> generateNewDerivation(context, String name,
      [int? number]) async {
    isNewDerivationLoading = true;
    notifyListeners();

    final List idList = getNextWalletNumberAndDerivation();
    int newWalletNbr = idList[0];
    int newDerivationNbr = number ?? idList[1];

    int? chest = getCurrentChest();

    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = getDefaultWallet();

    final address = await sub.derive(
        context, defaultWallet.address, newDerivationNbr, pinCode);

    WalletData newWallet = WalletData(
        chest: chest,
        address: address,
        number: newWalletNbr,
        name: name,
        derivation: newDerivationNbr,
        imageDefaultPath: '${newWalletNbr % 4}.png',
        isOwned: true);

    await walletBox.put(newWallet.address, newWallet);

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<void> generateRootWallet(context, String name) async {
    final myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? chest = getCurrentChest();

    List<WalletData> walletConfig = readAllWallets(chest);
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

    final address =
        await sub.generateRootKeypair(defaultWallet.address, pinCode);

    WalletData newWallet = WalletData(
        chest: chest,
        address: address,
        number: newWalletNbr,
        name: name,
        derivation: -1,
        imageDefaultPath: '${newWalletNbr % 4}.png',
        isOwned: true);

    await walletBox.put(newWallet.address, newWallet);

    isNewDerivationLoading = false;
    notifyListeners();
  }

  List<int> getNextWalletNumberAndDerivation(
      {int? chestNumber, bool isOneshoot = false}) {
    int newDerivationNbr = 0;
    int newWalletNbr = 0;

    chestNumber ??= getCurrentChest();

    List<WalletData> walletConfig = readAllWallets(chestNumber);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    if (walletConfig.isEmpty) {
      newDerivationNbr = 2;
    } else {
      WalletData lastWallet = walletConfig.reduce(
          (curr, next) => curr.derivation! > next.derivation! ? curr : next);

      if (lastWallet.derivation == -1) {
        newDerivationNbr = 2;
      } else {
        newDerivationNbr = lastWallet.derivation! + (isOneshoot ? 1 : 2);
      }

      newWalletNbr = walletConfig.last.number! + 1;
    }

    return [newWalletNbr, newDerivationNbr];
  }

  int lockPin = 0;
  Future resetPinCode([int minutes = 15]) async {
    lockPin++;
    final actualLock = lockPin;
    await Future.delayed(
        Duration(seconds: configBox.get('isCacheChecked') ? minutes * 60 : 1));
    log.i('reset pin code, lock $actualLock ...');
    if (actualLock == lockPin) pinCode = '';
  }

  void reload() {
    notifyListeners();
  }
}

  // Finally, we are using StateNotifierProvider to allow the UI to interact with
// our TodosNotifier class.
final myWalletsProvider = ChangeNotifierProvider<MyWalletsProvider>((ref) {
  return MyWalletsProvider();
});