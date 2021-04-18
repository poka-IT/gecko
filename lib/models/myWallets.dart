import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:provider/provider.dart';

class MyWalletsProvider with ChangeNotifier {
  List<WalletData> listWallets = [];
  String pinCode;
  int pinLenght;

  Future initWalletFolder() async {
    // getDefaultWallet();

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
      // getDefaultWallet();
    }
    await getDefaultWalletAsync();
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

    final List _walletList = readAllWallets(0);

    if (_walletList.isEmpty) {
      log.i('No wallets detected');
      return false;
    } else {
      return true;
    }
  }

  List readAllWallets(int _chest) {
    // log.d(walletsDirectory.path);

    listWallets = [];

    File _walletConfig = File('${walletsDirectory.path}/$_chest/list.conf');
    _walletConfig.readAsLinesSync().forEach((element) {
      listWallets.add(WalletData(element));
    });

    log.i(listWallets.toString());
    return listWallets;
  }

  WalletData getWalletData(String _id) {
    // log.d(_id);
    if (_id == '') return WalletData('');
    int chest = int.parse(_id.split(':')[0]);
    final _walletConfig = File('${walletsDirectory.path}/$chest/list.conf');

    return WalletData(_walletConfig
        .readAsLinesSync()
        .firstWhere((element) => element.startsWith(_id)));
  }

  Future<WalletData> getWalletDataAsync(String _id) async {
    // log.d(_id);
    if (_id == '') return WalletData('');
    int chest = int.parse(_id.split(':')[0]);
    final _walletConfig = File('${walletsDirectory.path}/$chest/list.conf');

    List configLines = await _walletConfig.readAsLines();
    log.d(configLines);

    if (configLines.isEmpty) {
      return WalletData('');
    }

    return WalletData(
        configLines.firstWhere((element) => element.startsWith(_id)));
  }

  void getDefaultWallet() {
    defaultWalletFile = File('${appPath.path}/defaultWallet');

    if (!defaultWalletFile.existsSync()) {
      File(defaultWalletFile.path).createSync();
      defaultWalletFile.writeAsStringSync("0:0");
    }

    defaultWallet = getWalletData(defaultWalletFile.readAsStringSync());
  }

  Future getDefaultWalletAsync() async {
    defaultWalletFile = File('${appPath.path}/defaultWallet');

    if (!await defaultWalletFile.exists()) {
      await File(defaultWalletFile.path).create();
      await defaultWalletFile.writeAsString("0:0");
    } else {
      defaultWallet =
          await getWalletDataAsync(await defaultWalletFile.readAsString());
    }
  }

  Future<int> deleteAllWallet(context) async {
    MyWalletsProvider _myWalletProvider =
        Provider.of<MyWalletsProvider>(context, listen: false);
    try {
      log.w('DELETE THAT ?: $walletsDirectory');

      final bool _answer = await _confirmDeletingAllWallets(context);
      if (_answer) {
        await walletsDirectory.delete(recursive: true);
        await defaultWalletFile.delete();
        await walletsDirectory.create();
        await initWalletFolder();
        // await Future.delayed(Duration(milliseconds: 500));
        // scheduleMicrotask(() {
        notifyListeners();
        rebuildWidget();
        _myWalletProvider.rebuildWidget();
        // });

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

    notifyListeners();

    Navigator.pop(context);
  }

  void rebuildWidget() {
    notifyListeners();
  }
}

// wallet data contains elements identifying wallet
class WalletData {
  int chest;
  int number;
  String name;
  int derivation;

  // constructor from ':'-separated string
  WalletData(String element) {
    if (element != '') {
      List parts = element.split(':');

      this.chest = int.parse(parts[0]);
      this.number = int.parse(parts[1]);
      this.name = parts[2];
      this.derivation = int.parse(parts[3]);
    }
  }

  // representation of WalletData when debugging
  @override
  String toString() {
    return this.name;
  }

  // creates the ':'-separated string from the WalletData
  String inLine() {
    return "${this.chest}:${this.number}:${this.name}:${this.derivation}";
  }

  // returns only the id part of the ':'-separated string
  String id() {
    return "${this.chest}:${this.number}";
  }
}
