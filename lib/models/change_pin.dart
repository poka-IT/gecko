import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';

class ChangePinProvider with ChangeNotifier {
  bool ischangedPin = false;
  TextEditingController newPin = TextEditingController();

  Future<NewWallet> get badWallet => null;

  Future<NewWallet> changePin(_name, _oldPin) async {
    try {
      final _dewif = chestBox.get(configBox.get('currentChest')).dewif;

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

  Future storeNewPinChest(context, NewWallet _newWalletFile) async {
    ChestData currentChest = chestBox.getAt(configBox.get('currentChest'));
    currentChest.dewif = _newWalletFile.dewif;
    // currentChest.name = _name;
    chestBox.add(currentChest);

    Navigator.pop(context);
  }
}
