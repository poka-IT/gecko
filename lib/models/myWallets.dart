import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  String listWallets;

  bool checkIfWalletExist() {
    if (appPath == null) {
      return false;
    }

    print(walletsDirectory.listSync());

    List contents = walletsDirectory.listSync();
    if (contents.length == 0) {
      print('No wallets detected');
      return false;
    } else {
      print('Some wallets have been detected.');
      return true;
    }
  }

  String getAllWalletsNames() {
    final bool _isWalletsExists = checkIfWalletExist();
    if (!_isWalletsExists) {
      return '';
    }

    if (listWallets != null && listWallets.isNotEmpty) {
      listWallets = '';
    }
    if (listWallets == null) {
      listWallets = '';
    }

    // int i = 0;
    walletsDirectory
        .listSync(recursive: false, followLinks: false)
        .forEach((_wallet) {
      File _walletConfig = File('${_wallet.path}/config.txt');
      _walletConfig.readAsLinesSync().forEach((element) {
        if (listWallets != '') {
          listWallets += '\n';
        }
        listWallets += element;
        // listWallets += "${element.split(':')[0]}:${element.split(':')[1]}:${element.split(':')[2]}"
      });
    });
    print(listWallets);

    return listWallets;
  }

  Future getDefaultWallet() async {
    defaultWalletFile = File('${appPath.path}/defaultWallet');

    bool isdefaultWalletFile = await defaultWalletFile.exists();

    if (!isdefaultWalletFile) {
      await File(defaultWalletFile.path).create();
    }

    try {
      defaultWallet = await defaultWalletFile.readAsString();
    } catch (e) {
      defaultWallet = '0:3';
    }
    if (defaultWallet == '') defaultWallet = '0:3';
  }

  Future<int> deleteAllWallet(context) async {
    try {
      print('DELETE THAT ?: $walletsDirectory');

      final bool _answer = await _confirmDeletingAllWallets(context);

      if (_answer) {
        await walletsDirectory.delete(recursive: true);
        await walletsDirectory.create();
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
                      _myWalletProvider.getAllWalletsNames();
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
    final _walletConfig = File('${walletsDirectory.path}/0/config.txt');

    if (await _walletConfig.readAsString() == '') {
      _newDerivationNbr = 3;
    } else {
      String _lastWallet =
          await _walletConfig.readAsLines().then((value) => value.last);
      int _lastDerivation = int.parse(_lastWallet.split(':')[2]);
      _newDerivationNbr = _lastDerivation + 3;
    }

    await _walletConfig.writeAsString('\n0:$_name:$_newDerivationNbr',
        mode: FileMode.append);

    print(await _walletConfig.readAsString());
    notifyListeners();

    Navigator.pop(context);
  }

  void rebuildWidget() {
    notifyListeners();
  }
}
