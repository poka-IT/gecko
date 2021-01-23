import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';

class MyWalletsProvider with ChangeNotifier {
  Directory appPath;

  bool checkIfWalletExist() {
    if (this.appPath == null) {
      return false;
    }

    var walletsFolder = new Directory("${this.appPath.path}/wallets/");

    bool isWalletFolderExist = walletsFolder.existsSync();

    if (!isWalletFolderExist) {
      Directory(walletsFolder.path).createSync();
    }

    List contents = walletsFolder.listSync();
    if (contents.length == 0) {
      print('No wallets detected');
      return false;
    } else {
      print('Some wallets have been detected:');
      for (var _wallets in contents) {
        print(_wallets);
      }
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

  Future getAppDirectory() async {
    this.appPath = await getApplicationDocumentsDirectory();
    notifyListeners();
  }

  Future importWallet() async {}
}
