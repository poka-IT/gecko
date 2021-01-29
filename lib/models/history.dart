import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sentry/sentry.dart' as sentry;
import 'package:qrscan/qrscan.dart' as scanner;

class HistoryProvider with ChangeNotifier {
  String pubkey = '';
  HistoryProvider(this.pubkey);
  final TextEditingController _outputPubkey = new TextEditingController();
  // String pubkey = 'D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU'; // For debug

  Future scan() async {
    await Permission.camera.request();
    String barcode;
    try {
      barcode = await scanner.scan();
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
      return 'false';
    }
    if (barcode != null) {
      this._outputPubkey.text = barcode;
      isPubkey(barcode);
    } else {
      return 'false';
    }
    return barcode;
  }

  String isPubkey(pubkey) {
    final RegExp regExp = new RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(pubkey) == true &&
        pubkey.length > 42 &&
        pubkey.length < 45) {
      print("C'est une pubkey !!!");

      this.pubkey = pubkey;
      this._outputPubkey.text = pubkey;
      notifyListeners();

      return pubkey;
    }

    return '';
  }

  // num getBalance(_pubkey) {
  //   getBalance(_pubkey);
  // }
}
