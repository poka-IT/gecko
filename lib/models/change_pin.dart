import 'package:durt/durt.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';

class ChangePinProvider with ChangeNotifier {
  bool ischangedPin = false;
  TextEditingController newPin = TextEditingController();
  String pinToGive;

  NewWallet get badWallet => null;

  NewWallet changePin(String _oldPin, {String newCustomPin}) {
    try {
      final _dewif = chestBox.get(configBox.get('currentChest')).dewif;

      // TODO: Durt: Detect if CesiumWallet
      NewWallet newWalletFile = Dewif().changePassword(
          dewif: _dewif,
          oldPassword: _oldPin.toUpperCase(),
          newPassword: newCustomPin);

      newPin.text = pinToGive = newWalletFile.password;
      ischangedPin = true;
      // notifyListeners();
      return newWalletFile;
    } catch (e) {
      log.e('Impossible de changer le code PIN: $e');
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
