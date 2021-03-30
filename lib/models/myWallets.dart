import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  String listWallets;

  Future initWalletFolder() async {
    getDefaultWallet();

    final bool isWalletFolderExist = await walletsDirectory.exists();
    if (!isWalletFolderExist) {
      await Directory(walletsDirectory.path).create();
    }

    File _currentChestFile = File('${walletsDirectory.path}/currentChest.conf');

    await _currentChestFile.create();
    await _currentChestFile.writeAsString('0');

    final bool isChestsExist =
        await Directory('${walletsDirectory.path}/0').exists();
    if (!isChestsExist) {
      await Directory('${walletsDirectory.path}/0').create();
      await Directory('${walletsDirectory.path}/1').create();
      await File('${walletsDirectory.path}/0/list.conf').create();
      await File('${walletsDirectory.path}/0/order.conf').create();
      await File('${walletsDirectory.path}/1/list.conf').create();
      await File('${walletsDirectory.path}/1/order.conf').create();
    }
  }

  int getCurrentChest() {
    File _currentChestFile = File('${walletsDirectory.path}/currentChest.conf');

    bool isCurrentChestExist = _currentChestFile.existsSync();
    if (!isCurrentChestExist) {
      _currentChestFile.createSync();
      _currentChestFile.writeAsString('0');
    }
    return int.parse(_currentChestFile.readAsStringSync());
  }

  bool checkIfWalletExist() {
    if (appPath == null) {
      return false;
    }

    final String _walletList = getAllWalletsNames(0);

    if (_walletList == '') {
      print('No wallets detected');
      return false;
    } else {
      print('Some wallets have been detected.');
      return true;
    }
  }

  String getAllWalletsNames(int _chest) {
    if (listWallets != null && listWallets.isNotEmpty) {
      listWallets = '';
    }
    if (listWallets == null) {
      listWallets = '';
    }

    print(walletsDirectory.path);

    // int i = 0;
    File _walletConfig = File('${walletsDirectory.path}/$_chest/list.conf');
    _walletConfig.readAsLinesSync().forEach((element) {
      if (listWallets != '') {
        listWallets += '\n';
      }
      listWallets += element;
      // listWallets += "${element.split(':')[0]}:${element.split(':')[1]}:${element.split(':')[2]}"
    });
    print(listWallets);

    return listWallets;
  }

  int getDerivationNbr(String _id) {
    int chest = int.parse(_id.split(':')[0]);
    // int nbr = int.parse(_id.split(':')[1]);
    final _walletConfig = File('${walletsDirectory.path}/$chest/list.conf');

    int derivation;

    _walletConfig.readAsLinesSync().forEach((element) {
      if ("${element.split(':')[0]}:${element.split(':')[1]}" == _id) {
        derivation = int.parse(element.split(':')[3]);
      }
    });

    return derivation;
  }

  void getDefaultWallet() {
    defaultWalletFile = File('${appPath.path}/defaultWallet');

    bool isdefaultWalletFile = defaultWalletFile.existsSync();

    if (!isdefaultWalletFile) {
      File(defaultWalletFile.path).createSync();
    }

    try {
      defaultWallet = defaultWalletFile.readAsStringSync();
    } catch (e) {
      defaultWallet = '0:0';
    }
    if (defaultWallet == '') defaultWallet = '0:0';
  }

  Future<int> deleteAllWallet(context) async {
    try {
      print('DELETE THAT ?: $walletsDirectory');

      final bool _answer = await _confirmDeletingAllWallets(context);

      if (_answer) {
        await walletsDirectory.delete(recursive: true);
        await walletsDirectory.create();
        await initWalletFolder();
        notifyListeners();
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
        MyWalletsProvider _myWalletProvider =
            Provider.of<MyWalletsProvider>(context);
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
              child: Text("Oui"),
              onPressed: () {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _myWalletProvider.listWallets =
                      _myWalletProvider.getAllWalletsNames(getCurrentChest());
                  _myWalletProvider.rebuildWidget();
                });
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
    final _walletConfig = File('${walletsDirectory.path}/0/list.conf');

    if (await _walletConfig.readAsString() == '') {
      _newDerivationNbr = 3;
      _newWalletNbr = 0;
    } else {
      String _lastWallet =
          await _walletConfig.readAsLines().then((value) => value.last);
      int _lastDerivation = int.parse(_lastWallet.split(':')[3]);
      _newDerivationNbr = _lastDerivation + 3;

      int _lastWalletNbr = int.parse(_lastWallet.split(':')[1]);
      _newWalletNbr = _lastWalletNbr + 1;
    }

    await _walletConfig.writeAsString(
        '\n0:$_newWalletNbr:$_name:$_newDerivationNbr',
        mode: FileMode.append);

    print(await _walletConfig.readAsString());
    notifyListeners();

    Navigator.pop(context);
  }

  void rebuildWidget() {
    notifyListeners();
  }
}
