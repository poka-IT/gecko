import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  Map listWallets = Map();

  bool checkIfWalletExist() {
    if (appPath == null) {
      return false;
    }

    List contents = walletsDirectory.listSync();
    if (contents.length == 0) {
      print('No wallets detected');
      return false;
    } else {
      print('Some wallets have been detected.');
      return true;
    }
  }

  Future importWallet() async {}

  Map getAllWalletsNames() {
    if (listWallets.isNotEmpty) {
      listWallets.clear();
    }

    // int i = 0;
    walletsDirectory
        .listSync(recursive: false, followLinks: false)
        .forEach((_wallet) {
      File('${_wallet.path}/config.txt').readAsLinesSync().forEach((element) {
        listWallets[int.parse(element.split(':')[0])] = element.split(':')[1];
      });
    });
    return listWallets;
  }

  Future<int> deleteAllWallet(context) async {
    try {
      print('DELETE THAT ?: $walletsDirectory');

      final bool _answer = await _confirmDeletingAllWallets(context);

      if (_answer) {
        await walletsDirectory.delete(recursive: true);
        await walletsDirectory.create();
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

  void rebuildWidget() {
    notifyListeners();
  }
}
