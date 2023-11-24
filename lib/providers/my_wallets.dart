import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
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

  Future<List<WalletData>> readAllWallets([int? chest]) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    chest = chest ?? configBox.get('currentChest') ?? 0;
    listWallets.clear();
    final wallets = walletBox.toMap().values.toList();
    for (var walletFromBox in wallets) {
      if (walletFromBox.chest == chest) {
        if (walletFromBox.identityStatus == IdtyStatus.unknown) {
          walletFromBox.identityStatus =
              await sub.idtyStatus(walletFromBox.address);
          walletBox.put(walletFromBox.address, walletFromBox);
        }
        listWallets.add(walletFromBox);
      }
    }

    return listWallets;
  }

  // List<WalletData> readAllWallets([int? chest]) {
  //   final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
  //   bool hasFetchStatus = false;
  //   List<Future> futures = [];
  //   chest = chest ?? configBox.get('currentChest') ?? 0;
  //   listWallets.clear();
  //   walletBox.toMap().forEach((key, walletFromBox) {
  //     if (walletFromBox.chest == chest) {
  //       if (walletFromBox.identityStatus == IdtyStatus.unknown) {
  //         hasFetchStatus = true;
  //         futures.add(sub.idtyStatus(walletFromBox.address).then((valueStatus) {
  //           walletFromBox.identityStatus = valueStatus;
  //           listWallets.add(walletFromBox);
  //           // walletBox.put(key, walletFromBox);
  //         }));
  //       } else {
  //         listWallets.add(walletFromBox);
  //       }
  //     }
  //   });
  //   // if (hasFetchStatus) {
  //   //   sleep(const Duration(milliseconds: 300));
  //   //   log.d('yoooooooooo');
  //   //   readAllWallets(chest);
  //   // }

  //   if (hasFetchStatus) {
  //     Future.wait(futures).then((_) {
  //       return listWallets;
  //       // while (listWallets.any((element) =>
  //       //     element.chest == chest &&
  //       //     element.identityStatus == IdtyStatus.unknown)) {

  //       // List tata = listWallets.toList();
  //       // log.d(listWallets);
  //       // while (tata.length < walletBox.length) {
  //       //   tata = listWallets.toList();
  //       //   sleep(const Duration(milliseconds: 500));
  //       //   Map status = {};
  //       //   for (var walletInList in tata) {
  //       //     status.putIfAbsent(
  //       //         walletInList.name, () => walletInList.identityStatus);
  //       //   }
  //       //   log.d(status);
  //       //   log.d('yoooooo');

  //       //   status.clear();
  //       // }
  //     });
  //   }

  //   // if (hasFetchStatus) {
  //   //   walletBox.putAll(
  //   //       Map.fromEntries(listWallets.map((e) => MapEntry(e.address, e))));
  //   // }

  //   return listWallets;
  // }

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

        await Navigator.of(context)
            .pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);
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

    final List idList = await getNextWalletNumberAndDerivation();
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
    await readAllWallets();

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

  Future<List<int>> getNextWalletNumberAndDerivation(
      {int? chestNumber, bool isOneshoot = false}) async {
    int newDerivationNbr = 0;
    int newWalletNbr = 0;

    chestNumber ??= getCurrentChest();

    // List<WalletData> walletConfig = await readAllWallets(chestNumber);
    listWallets.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    if (listWallets.isEmpty) {
      newDerivationNbr = 2;
    } else {
      WalletData lastWallet = listWallets.reduce(
          (curr, next) => curr.derivation! > next.derivation! ? curr : next);

      if (lastWallet.derivation == -1) {
        newDerivationNbr = 2;
      } else {
        newDerivationNbr = lastWallet.derivation! + (isOneshoot ? 1 : 2);
      }

      newWalletNbr = listWallets.last.number! + 1;
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
