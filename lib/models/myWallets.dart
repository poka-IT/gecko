import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';

class MyWalletsProvider with ChangeNotifier {
  // Directory appPath;
  List listWallets = [];

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
      notifyListeners();
      return false;
    } else {
      print('Some wallets have been detected:');
      for (var _wallets in contents) {
        print(_wallets);
      }
      notifyListeners();
      return true;
    }

    // final bool isExist =
    //     File('${walletsFolder.path}/$name/wallet.dewif').existsSync();
    // print(this.appPath.path);
    // print('Wallet existe ? : ' + isExist.toString());
    // print('Is wallet generated ? : ' + walletIsGenerated.toString());
    // if (isExist) {
    //   print('Un wallet existe !');
    //   return true;
    // } else {
    //   return false;
    // }
  }

  Future importWallet() async {}

  List getAllWalletsNames() {
    listWallets.clear();
    print('1');
    print(walletsDirectory.path);
    print('2');

    walletsDirectory
        .listSync(recursive: false, followLinks: false)
        .forEach((wallet) {
      String _name = wallet.path.split('/').last;
      print(_name);
      listWallets.add(_name);
    });
    notifyListeners();

    return listWallets;
  }
}
