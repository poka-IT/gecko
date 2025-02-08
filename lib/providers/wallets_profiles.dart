// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.address);

  String address = '';
  String pubkeyShort = '';

  bool isHistoryScreen = false;
  String historySwitchButtun = "Voir l'historique";
  String? rawSvg;
  final payAmount = TextEditingController();
  final payComment = TextEditingController();
  num? _balance;

  bool isCommentVisible = false;

  final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

  String _comment = '';
  String get comment => _comment;
  set comment(String value) {
    _comment = value;
    if (value.isEmpty) {
      payComment.text = '';
    } else {
      payComment.value = TextEditingValue(
        text: value,
        selection: payComment.selection,
      );
    }
    notifyListeners();
  }

  void toggleCommentVisibility() {
    isCommentVisible = !isCommentVisible;
    if (isCommentVisible) {
      payComment.text = _comment;
    } else {
      payComment.text = '';
    }
    notifyListeners();
  }

  Future<void> scan(context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.camera.request();
    }
    ScanResult? barcode;
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      log.e("BarcodeScanner ERR: $e");
      return;
    }

    final barcodeContent = barcode.rawContent;

    if (barcodeContent == '') return;

    if (await isAddressOrPubkey(barcodeContent)) {
      if (!(await isAddress(barcodeContent))) {
        address = await sub.pubkeyV1ToAddress(barcodeContent);
      } else {
        address = barcodeContent;
      }

      Navigator.popUntil(
        context,
        ModalRoute.withName('/'),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WalletViewScreen(
            address: address,
            username: null,
          );
        }),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('qrCodeNotAddress'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
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
      snackMessage(homeContext, message: 'removedFromcontacts'.tr(), duration: 4);
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

Future<bool> isAddressOrPubkey(String address) async {
  return await isAddress(address) || isPubkey(address);
}

Future<bool> isAddress(String address) async {
  final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);
  return await sub.sdk.api.account.checkAddressFormat(address, sub.initSs58).timeout(const Duration(milliseconds: 300)).onError((_, __) => false) ?? false;
}

bool isPubkey(String pubkey) {
  pubkey = pubkey.split(':')[0];
  final RegExp regExp = RegExp(
    r'^[a-zA-Z0-9]+$',
    caseSensitive: false,
    multiLine: false,
  );

  return regExp.hasMatch(pubkey) == true && pubkey.length > 42 && pubkey.length < 45;
}

snackMessage(context, {required String message, int duration = 2, double fontSize = 14}) {
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
      content: Text("thisAddressHasBeenCopiedToClipboard".tr(), style: scaledTextStyle(fontSize: 13)),
      duration: const Duration(seconds: 2));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

snackCopySeed(context) {
  final snackBar = SnackBar(
      backgroundColor: Colors.grey[900],
      padding: EdgeInsets.all(scaleSize(19)),
      content: Text("thisMnemonicHasBeenCopiedToClipboard".tr(), style: scaledTextStyle(fontSize: 13)),
      duration: const Duration(seconds: 4));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
