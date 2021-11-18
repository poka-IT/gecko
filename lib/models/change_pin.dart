import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:gecko/globals.dart';

class ChangePinProvider with ChangeNotifier {
  bool ischangedPin = false;
  TextEditingController newPin = TextEditingController();
  String pinToGive;

  Future<NewWallet> get badWallet => null;

  Future<NewWallet> changePin(String _oldPin) async {
    try {
      final _dewif = chestBox.get(configBox.get('currentChest')).dewif;

      NewWallet newWalletFile = await DubpRust.changeDewifPin(
        dewif: _dewif,
        oldPin: _oldPin.toUpperCase(),
      );

      newPin.text = pinToGive = newWalletFile.pin;
      ischangedPin = true;
      notifyListeners();
      return newWalletFile;
    } catch (e) {
      log.e('Impossible de changer le code PIN.');
      return badWallet;
    }
  }

  void storeNewPinChest(context, NewWallet _newWalletFile) {
    // ChestData currentChest = chestBox.getAt(configBox.get('currentChest'));
    // currentChest.dewif = _newWalletFile.dewif;
    // await chestBox.add(currentChest);

    chestBox.get(configBox.get('currentChest')).dewif = _newWalletFile.dewif;

    Navigator.pop(context, pinToGive);
    pinToGive = '';
  }
}
