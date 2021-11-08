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
      final _dewif = chestBox.get(0);

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

  Future storeWallet(context, _name, NewWallet _newWalletFile) async {
    chestBox.put(0, _newWalletFile.dewif);

    Navigator.pop(context);
    return _name;
  }
}
