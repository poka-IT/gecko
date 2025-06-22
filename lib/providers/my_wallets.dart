import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/chest_provider.dart';
import 'package:gecko/providers/substrate_sdk.dart';
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
  final chestProvider = Provider.of<ChestProvider>(homeContext, listen: false);

  bool isOwner(String address) => listWallets.any((wallet) => wallet.address == address);

  bool get isWalletsExists => chestBox.isNotEmpty;

  WalletData? get idtyWallet => listWallets.firstWhereOrNull((w) => w.isMembre) ?? listWallets.firstWhereOrNull((w) => w.hasIdentity);

  List<WalletData> get listWalletsWithoutIdty => listWallets.where((w) => w.address != idtyWallet?.address).toList();

  Future<void> clearWallets(ChestData chest) async {
    // ignore: use_build_context_synchronously
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    final chestProvider = Provider.of<ChestProvider>(homeContext, listen: false);
    final wallets = chestProvider.getChestWallets(chest);
    await sub.deleteAccounts(wallets);
    await chestBox.delete(chest.key);
    await walletBox.clear();
    await configBox.put('currentChest', 0);

    pinCode = '';
  }

  Future<List<WalletData>> readAllWallets([int? chest]) async {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
    chest = chest ?? chestProvider.getCurrentChestNumber();
    listWallets.clear();

    final walletsInChest = walletBox.values.where((w) => w.chest == chest);

    final Map<String, WalletData> walletsToScan = {};

    for (final wallet in walletsInChest) {
      if (wallet.identityStatus == IdtyStatus.unknown) {
        walletsToScan[wallet.address] = wallet;
      } else {
        listWallets.add(wallet);
      }
    }

    if (walletsToScan.isNotEmpty) {
      final addresses = walletsToScan.keys.toList();
      try {
        final idtyStatusList = await sub.idtyStatusMulti(addresses);

        if (idtyStatusList.length == addresses.length) {
          for (var i = 0; i < addresses.length; i++) {
            final wallet = walletsToScan[addresses[i]]!;
            wallet.identityStatus = idtyStatusList[i];
            await walletBox.put(wallet.address, wallet);
          }
        } else {
          log.w('Idty status check returned a list of different size than wallets to scan. Wallets will be displayed with unknown status.');
        }
      } catch (e, s) {
        log.e('Failed to fetch identity statuses', error: e, stackTrace: s);
      }

      listWallets.addAll(walletsToScan.values);
    }

    listWallets.sort((p1, p2) => Comparable.compare(p1.number!, p2.number!));

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

  WalletData? getWalletDataByAddress(String address) => walletBox.toMap().values.firstWhereOrNull((wallet) => wallet.address == address);

  WalletData getDefaultWallet([int? chest]) {
    if (chestBox.isEmpty) {
      return WalletData(address: '', chest: 0, number: 0, isOwned: true);
    } else {
      chest ??= chestProvider.getCurrentChestNumber();
      int? defaultWalletNumber = chestBox.get(chest)!.defaultWallet;
      return getWalletDataById([chest, defaultWalletNumber]) ?? WalletData(address: '', chest: chest, number: 0, isOwned: true);
    }
  }

  Future<int> deleteAllWallet(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE ALL WALLETS ?');

      final answer = await showConfirmationDialog(
        context: context,
        message: 'areYouSureForgetAllChests'.tr(),
        type: ConfirmationDialogType.warning,
      );
      if (answer) {
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

    int? chest = chestProvider.getCurrentChestNumber();

    // ignore: use_build_context_synchronously
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = getDefaultWallet();

    // ignore: use_build_context_synchronously
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

  Future<void> generateRootWallet(BuildContext context, String name) async {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int newWalletNbr;
    int? chest = chestProvider.getCurrentChestNumber();

    List<WalletData> walletConfig = await readAllWallets(chest);
    walletConfig.sort((p1, p2) {
      return Comparable.compare(p1.number!, p2.number!);
    });

    if (walletConfig.isEmpty) {
      newWalletNbr = 0;
    } else {
      newWalletNbr = walletConfig.last.number! + 1;
    }
    // ignore: use_build_context_synchronously
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
    chestNumber ??= chestProvider.getCurrentChestNumber();

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
