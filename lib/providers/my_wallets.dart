import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  String pinCode = '';
  late String mnemonic;
  int? pinLenght;
  bool isNewDerivationLoading = false;

  int getCurrentChest() {
    if (configBox.get('currentChest') == null) {
      configBox.put('currentChest', 0);
    }

    return configBox.get('currentChest');
  }

  bool checkIfWalletExist() {
    if (chestBox.isEmpty) {
      log.i('No wallets detected');
      return false;
    } else {
      return true;
    }
  }

  List<WalletData> readAllWallets([int? _chest]) {
    _chest = _chest ?? configBox.get('currentChest') ?? 0;
    listWallets.clear();
    walletBox.toMap().forEach((key, value) {
      if (value.chest == _chest) {
        listWallets.add(value);
      }
    });

    return listWallets;
  }

  WalletData? getWalletDataById(List<int?> _id) {
    if (_id.isEmpty) return WalletData();
    int? _chest = _id[0];
    int? _nbr = _id[1];
    WalletData? _targetedWallet;

    walletBox.toMap().forEach((key, value) {
      if (value.chest == _chest && value.number == _nbr) {
        _targetedWallet = value;
        return;
      }
    });

    return _targetedWallet;
  }

  WalletData? getWalletDataByAddress(String address) {
    WalletData? _targetedWallet;

    walletBox.toMap().forEach((key, value) {
      if (value.address == address) {
        _targetedWallet = value;
        return;
      }
    });

    return _targetedWallet;
  }

  WalletData getDefaultWallet([int? chest]) {
    if (chestBox.isEmpty) {
      return WalletData(chest: 0, number: 0);
    } else {
      chest ??= getCurrentChest();
      int? defaultWalletNumber = chestBox.get(chest)!.defaultWallet;
      return getWalletDataById([chest, defaultWalletNumber])!;
    }
  }

  Future<int> deleteAllWallet(context) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE ALL WALLETS ?');

      final bool? _answer = await (confirmPopup(
          context, 'Êtes-vous sûr de vouloir oublier tous vos coffres ?'));
      if (_answer!) {
        await walletBox.clear();
        await chestBox.clear();
        await configBox.delete('defaultWallet');
        await _sub.deleteAllAccounts();

        _myWalletProvider.pinCode = '';

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

  Future<void> generateNewDerivation(context, String _name,
      [int? number]) async {
    isNewDerivationLoading = true;
    notifyListeners();

    final List idList = getNextWalletNumberAndDerivation();
    int _newWalletNbr = idList[0];
    int _newDerivationNbr = number ?? idList[1];

    int? _chest = getCurrentChest();

    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = getDefaultWallet();

    final address = await _sub.derive(
        context, defaultWallet.address!, _newDerivationNbr, pinCode);

    WalletData newWallet = WalletData(
        version: dataVersion,
        chest: _chest,
        address: address,
        number: _newWalletNbr,
        name: _name,
        derivation: _newDerivationNbr,
        imageDefaultPath: '${_newWalletNbr % 4}.png');

    await walletBox.add(newWallet);

    isNewDerivationLoading = false;
    notifyListeners();
  }

  Future<void> generateRootWallet(context, String _name) async {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    isNewDerivationLoading = true;
    notifyListeners();
    int _newWalletNbr;
    int? _chest = getCurrentChest();

    List<WalletData> _walletConfig = readAllWallets(_chest);

    if (_walletConfig.isEmpty) {
      _newWalletNbr = 0;
    } else {
      _newWalletNbr = _walletConfig.last.number! + 1;
    }
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    WalletData defaultWallet = _myWalletProvider.getDefaultWallet();

    final address =
        await _sub.generateRootKeypair(defaultWallet.address!, pinCode);

    WalletData newWallet = WalletData(
        version: dataVersion,
        chest: _chest,
        address: address,
        number: _newWalletNbr,
        name: _name,
        derivation: -1,
        imageDefaultPath: '${_newWalletNbr % 4}.png');

    await walletBox.add(newWallet);

    isNewDerivationLoading = false;
    notifyListeners();
  }

  List<int> getNextWalletNumberAndDerivation(
      {int? chestNumber, bool isOneshoot = false}) {
    int _newDerivationNbr = 0;
    int _newWalletNbr = 0;

    chestNumber ??= getCurrentChest();

    List<WalletData> _walletConfig = readAllWallets(chestNumber);

    if (_walletConfig.isEmpty) {
      _newDerivationNbr = 2;
    } else {
      WalletData _lastWallet = _walletConfig.reduce(
          (curr, next) => curr.derivation! > next.derivation! ? curr : next);

      if (_lastWallet.derivation == -1) {
        _newDerivationNbr = 2;
      } else {
        _newDerivationNbr = _lastWallet.derivation! + (isOneshoot ? 1 : 2);
      }

      _newWalletNbr = _walletConfig.last.number! + 1;
    }

    return [_newWalletNbr, _newDerivationNbr];
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

  void rebuildWidget() {
    notifyListeners();
  }
}
