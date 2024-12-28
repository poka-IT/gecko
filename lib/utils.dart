import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:provider/provider.dart';
import 'package:truncate/truncate.dart';

void snackNode(bool isConnected) {
  String message;
  if (!isConnected) {
    message = "noDuniterNodeAvailableTryLater".tr();
  } else {
    final sub = Provider.of<SubstrateSdk>(homeContext, listen: false);

    message = "${"youAreConnectedToNode".tr()}\n${sub.getConnectedEndpoint()!.split('//')[1]}";
  }
  final snackBar = SnackBar(
      backgroundColor: Colors.grey[900],
      padding: const EdgeInsets.all(20),
      content: Text(message, style: scaledTextStyle(fontSize: 13)),
      duration: const Duration(seconds: 4));
  ScaffoldMessenger.of(homeContext).showSnackBar(snackBar);
}

String getShortPubkey(String pubkey) {
  String pubkeyShort = truncate(pubkey, 7, omission: String.fromCharCode(0x2026), position: TruncatePosition.end) +
      truncate(pubkey, 6, omission: "", position: TruncatePosition.start);
  return pubkeyShort;
}

Uint8List int32bytes(int value) => Uint8List(4)..buffer.asInt32List()[0] = value;

double round(double number, [int decimal = 2]) {
  return double.parse((number.toStringAsFixed(decimal)));
}

double removeDecimalZero(double n) {
  String result = n.toStringAsFixed(n.truncateToDouble() == n ? 0 : 3);
  return double.parse(result);
}
