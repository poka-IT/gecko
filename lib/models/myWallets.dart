import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/walletData.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  String pinCode;
  int pinLenght;

  int getCurrentChest() {
    if (configBox.get('currentChest') == null) {
      configBox.put('currentChest', 0);
    }

    return configBox.get('currentChest');
  }

  bool checkIfWalletExist() {
    if (appPath == null) {
      return false;
    }

    final List _walletList = readAllWallets(0);

    if (_walletList.isEmpty) {
      log.i('No wallets detected');
      return false;
    } else {
      return true;
    }
  }

  List<WalletData> readAllWallets(int _chest) {
    listWallets.clear();
    walletBox.toMap().forEach((key, value) {
      if (value.chest == _chest) {
        listWallets.add(value);
      }
    });

    return listWallets;
  }

  WalletData getWalletData(List<int> _id) {
    if (_id.isEmpty) return WalletData();
    int _chest = _id[0];
    int _nbr = _id[1];
    var _targetedWallet;

    walletBox.toMap().forEach((key, value) {
      if (value.chest == _chest && value.number == _nbr) {
        _targetedWallet = value;
        return false;
      }
    });

    return _targetedWallet;
  }

  void getDefaultWallet() {
    MyWalletsProvider myWalletsProvider = MyWalletsProvider();

    if (configBox.get('defaultWallet') == null) {
      configBox.put('defaultWallet', [0, 0]);
    }

    defaultWallet = myWalletsProvider
        .getWalletData(configBox.get('defaultWallet').cast<int>());
  }

  Future<int> deleteAllWallet(context) async {
    try {
      log.w('DELETE ALL WALLETS ?');

      final bool _answer = await _confirmDeletingAllWallets(context);
      if (_answer) {
        await walletBox.clear();
        await chestBox.clear();
        await configBox.delete('defaultWallet');
        checkIfWalletExist();
        notifyListeners();
        rebuildWidget();

        Navigator.pop(context);
      }
      return 0;
    } catch (e) {
      return 1;
    }
  }

  Future<bool> _confirmDeletingAllWallets(context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('Êtes-vous sûr de vouloir supprimer tous vos trousseaux ?'),
          content: SingleChildScrollView(child: Text('')),
          actions: <Widget>[
            TextButton(
              child: Text("Non"),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              key: Key('confirmDeletingAllWallets'),
              child: Text("Oui"),
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
    int _chest = 0;
    List<WalletData> _walletConfig = readAllWallets(_chest);

    if (_walletConfig.isEmpty) {
      _newDerivationNbr = 3;
      _newWalletNbr = 0;
    } else {
      _newDerivationNbr = _walletConfig.last.derivation + 3;
      _newWalletNbr = _walletConfig.last.number + 1;
    }

    WalletData newWallet = WalletData(
        chest: _chest,
        number: _newWalletNbr,
        name: _name,
        derivation: _newDerivationNbr);

    await walletBox.add(newWallet);

    notifyListeners();
    Navigator.pop(context);
  }

  void rebuildWidget() {
    notifyListeners();
  }
}
