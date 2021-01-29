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

    var walletsFolder = new Directory("${appPath.path}/wallets/");

    bool isWalletFolderExist = walletsFolder.existsSync();

    if (!isWalletFolderExist) {
      Directory(walletsFolder.path).createSync();
    }

    List contents = walletsFolder.listSync();
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
    print(listWallets);
    if (listWallets.isNotEmpty) {
      listWallets.clear();
    }
    print(walletsDirectory.path);

    // int i = 0;
    walletsDirectory
        .listSync(recursive: false, followLinks: false)
        .forEach((wallet) {
      String _name = wallet.path.split('/').last;
      String _pubkey = File(wallet.path + '/pubkey').readAsLinesSync()[0];
      print("$_name: $_pubkey");
      listWallets[_name] = _pubkey;
      // i++;

      // for (var _wallets in listWallets) {
      //   _wallets.pubkey =
      // }
    });
    return listWallets;
  }

  Future<int> deleteAllWallet(context) async {
    try {
      print('DELETE THAT ?: $walletsDirectory');

      final bool _answer = await _confirmDeletingAllWallets(context);

      if (_answer) {
        walletsDirectory.deleteSync(recursive: true);
        walletsDirectory.createSync();
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
          title: Text(
              'Êtes-vous sûr de vouloir supprimer tous vos portefeuilles ?'),
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
