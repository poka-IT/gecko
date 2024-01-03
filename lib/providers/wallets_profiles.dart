// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.address);

  String address = '';
  String pubkeyShort = '';

  bool isHistoryScreen = false;
  String historySwitchButtun = "Voir l'historique";
  String? rawSvg;
  TextEditingController payAmount = TextEditingController();
  TextEditingController payComment = TextEditingController();
  num? _balance;

  Future<String> scan(context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.camera.request();
    }
    ScanResult? barcode;
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      log.e("BarcodeScanner ERR: $e");
      return 'false';
    }
    if (isAddress(barcode.rawContent)) {
      address = barcode.rawContent;
      Navigator.popUntil(
        context,
        ModalRoute.withName('/'),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WalletViewScreen(
            address: barcode!.rawContent,
            username: null,
          );
        }),
      );
    } else {
      return 'false';
    }
    return barcode.rawContent;
  }

  void resetdHistory() {
    notifyListeners();
  }

  String generateIdenticon(String pubkey) {
    return Jdenticon.toSvg(pubkey);
  }

  Future<num?> getBalance(String? pubkey) async {
    while (_balance == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return _balance;
  }

  bool isContact(String address) {
    return contactsBox.containsKey(address);
  }

  Future addContact(G1WalletsList profile) async {
    if (isContact(profile.address)) {
      await contactsBox.delete(profile.address);
      snackMessage(homeContext,
          message: 'removedFromcontacts'.tr(), duration: 4);
    } else {
      await contactsBox.put(profile.address, profile);
      snackMessage(homeContext, message: 'addedToContacts'.tr(), duration: 4);
    }
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }
}

bool isAddress(address) {
  final RegExp regExp = RegExp(
    r'^[a-zA-Z0-9]+$',
    caseSensitive: false,
    multiLine: false,
  );

  if (regExp.hasMatch(address) == true &&
      address.length > 45 &&
      address.length < 52) {
    return true;
  } else {
    return false;
  }
}

snackMessage(context,
    {required String message, int duration = 2, double fontSize = 16}) {
  final snackBar = SnackBar(
      backgroundColor: Colors.grey[900],
      padding: EdgeInsets.all(scaleSize(19)),
      content: Text(message, style: scaledTextStyle(fontSize: fontSize)),
      duration: Duration(seconds: duration));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

snackCopyKey(context) {
  final snackBar = SnackBar(
      backgroundColor: Colors.grey[900],
      padding: EdgeInsets.all(scaleSize(19)),
      content: Text("thisAddressHasBeenCopiedToClipboard".tr(),
          style: scaledTextStyle(fontSize: 16)),
      duration: const Duration(seconds: 2));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

snackCopySeed(context) {
  final snackBar = SnackBar(
      backgroundColor: Colors.grey[900],
      padding: EdgeInsets.all(scaleSize(19)),
      content: Text("thisMnemonicHasBeenCopiedToClipboard".tr(),
          style: scaledTextStyle(fontSize: 16)),
      duration: const Duration(seconds: 4));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
