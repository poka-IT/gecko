import 'dart:io';
import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';

class ChangePinProvider with ChangeNotifier {
  bool ischangedPin = false;
  TextEditingController newPin = new TextEditingController();

  Future<NewWallet> get badWallet => null;

  Future<NewWallet> changePin(_name, _oldPin) async {
    try {
      final _walletFile = Directory('${walletsDirectory.path}/$_name');
      final _dewif =
          File(_walletFile.path + '/wallet.dewif').readAsLinesSync()[0];

      NewWallet newWalletFile = await DubpRust.changeDewifPin(
        dewif: _dewif,
        oldPin: _oldPin,
      );

      newPin.text = newWalletFile.pin;
      ischangedPin = true;
      notifyListeners();
      return newWalletFile;
    } catch (e) {
      log.e('Impossible de changer le code PIN.');
      return badWallet;
    }
  }

  Future storeWallet(context, _name, _newWalletFile) async {
    final Directory walletNameDirectory =
        Directory('${walletsDirectory.path}/$_name');
    final walletFile = File('${walletNameDirectory.path}/wallet.dewif');

    walletFile.writeAsString('${_newWalletFile.dewif}');
    Navigator.pop(context);
    return _name;
  }
}
