import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  late String pinCode;
  late String mnemonic;
  late Uint8List cesiumSeed;
  int? pinLenght;

  int? getCurrentChest() {
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

  List<WalletData> readAllWallets(int? _chest) {
    listWallets.clear();
    walletBox.toMap().forEach((key, value) {
      if (value.chest == _chest) {
        listWallets.add(value);
      }
    });

    return listWallets;
  }

  WalletData? getWalletData(List<int?> _id) {
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

  WalletData? getDefaultWallet(int? chest) {
    if (chestBox.isEmpty) {
      return WalletData(chest: 0, number: 0);
    } else {
      int? defaultWalletNumber = chestBox.get(chest)!.defaultWallet;
      return getWalletData([chest, defaultWalletNumber]);
    }
  }

  Future<int> deleteAllWallet(context) async {
    try {
      log.w('DELETE ALL WALLETS ?');

      final bool? _answer = await (_confirmDeletingAllWallets(context));
      if (_answer!) {
        await walletBox.clear();
        await chestBox.clear();
        await configBox.delete('defaultWallet');
        // await Future.delayed(const Duration(milliseconds: 50));
        // notifyListeners();

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

  Future<bool?> _confirmDeletingAllWallets(context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
              'Êtes-vous sûr de vouloir supprimer tous vos trousseaux ?'),
          content: const SingleChildScrollView(child: Text('')),
          actions: <Widget>[
            TextButton(
              child: const Text("Non"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              key: const Key('confirmDeletingAllWallets'),
              child: const Text("Oui"),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> generateNewDerivation(context, String _name) async {
    int _newDerivationNbr;
    int _newWalletNbr;
    int? _chest = getCurrentChest();
    List<WalletData> _walletConfig = readAllWallets(_chest);

    if (_walletConfig.isEmpty) {
      _newDerivationNbr = 2;
      _newWalletNbr = 0;
    } else {
      _newDerivationNbr = _walletConfig.last.derivation! + 2;
      _newWalletNbr = _walletConfig.last.number! + 1;
    }

    MyWalletsProvider myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);

    SubstrateSdk _sdk = Provider.of<SubstrateSdk>(context, listen: false);

    final int? _currentChestNumber = myWalletProvider.getCurrentChest();
    final ChestData _currentChest = chestBox.get(_currentChestNumber)!;

    final address = await _sdk.derive(
        context, _currentChest.address!, _newDerivationNbr, pinCode);

    WalletData newWallet = WalletData(
        chest: _chest,
        address: address,
        number: _newWalletNbr,
        name: _name,
        derivation: _newDerivationNbr,
        imageName: '${_newWalletNbr % 4}.png');

    await walletBox.add(newWallet);

    notifyListeners();
  }

  void rebuildWidget() {
    notifyListeners();
  }
}
