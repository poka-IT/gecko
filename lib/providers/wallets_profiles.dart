// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:barcode_scan2/barcode_scan2.dart';

class WalletsProfilesProvider with ChangeNotifier {
  late ProviderContainer _container;

  WalletsProfilesProvider(this.address) {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  String address = '';
  String pubkeyShort = '';

  bool isHistoryScreen = false;
  String historySwitchButtun = "Voir l'historique";
  String? rawSvg;
  final payAmount = TextEditingController();
  final payComment = TextEditingController();
  num? _balance;

  bool isCommentVisible = false;

  String _comment = '';
  String get comment => _comment;
  set comment(String value) {
    _comment = value;
    if (value.isEmpty) {
      payComment.text = '';
    } else {
      payComment.value = TextEditingValue(text: value, selection: payComment.selection);
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

  Future<void> scan(BuildContext context) async {
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

    if (isAddressOrPubkey(barcodeContent)) {
      if (!(isAddress(barcodeContent))) {
        address = _container.read(utilsProvider).pubkeyV1ToAddress(barcodeContent);
      } else {
        address = barcodeContent;
      }

      Navigator.popUntil(context, ModalRoute.withName('/'));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            return WalletViewScreen(address: address, username: null);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('qrCodeNotAddress'.tr()), duration: const Duration(seconds: 2)));
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

bool isAddressOrPubkey(String address) => isAddress(address) || isPubkey(address);

bool isAddress(String address) {
  final container = ProviderContainer();
  try {
    return container.read(utilsProvider).isAddressValid(address);
  } finally {
    container.dispose();
  }
}

bool isPubkey(String pubkey) {
  pubkey = pubkey.split(':')[0];
  final RegExp regExp = RegExp(r'^[a-zA-Z0-9]+$', caseSensitive: false, multiLine: false);

  return regExp.hasMatch(pubkey) == true && pubkey.length > 42 && pubkey.length < 45;
}

void snackMessage(BuildContext context, {required String message, int duration = 4, double fontSize = 14}) {
  final snackBar = SnackBar(
    backgroundColor: context.colorScheme.onSurface,
    padding: EdgeInsets.all(scaleSize(19)),
    content: Text(
      message,
      style: scaledTextStyle(fontSize: fontSize, color: context.colorScheme.surfaceContainer),
    ),
    duration: Duration(seconds: duration),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void snackCopyKey(BuildContext context) {
  final snackBar = SnackBar(
    backgroundColor: context.colorScheme.onSurface,
    padding: EdgeInsets.all(scaleSize(19)),
    content: Text(
      "thisAddressHasBeenCopiedToClipboard".tr(),
      style: scaledTextStyle(fontSize: 13, color: context.colorScheme.surfaceContainer),
    ),
    duration: const Duration(seconds: 4),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

void snackCopySeed(BuildContext context) {
  final snackBar = SnackBar(
    backgroundColor: context.colorScheme.onSurface,
    padding: EdgeInsets.all(scaleSize(19)),
    content: Text(
      "thisMnemonicHasBeenCopiedToClipboard".tr(),
      style: scaledTextStyle(fontSize: 13, color: context.colorScheme.surfaceContainer),
    ),
    duration: const Duration(seconds: 4),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
