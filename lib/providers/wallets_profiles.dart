import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:qrscan/qrscan.dart' as scanner;
import 'package:barcode_scan2/barcode_scan2.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.address);

  String? address = '';
  String pubkeyShort = '';

  bool isHistoryScreen = false;
  String historySwitchButtun = "Voir l'historique";
  String? rawSvg;
  TextEditingController payAmount = TextEditingController();
  TextEditingController payComment = TextEditingController();
  num? balance;

  Future<String> scan(context) async {
    if (Platform.isAndroid || Platform.isIOS) {
      await Permission.camera.request();
    }
    ScanResult? barcode;
    try {
      barcode = await BarcodeScanner.scan();
    } catch (e) {
      log.e(e);
      return 'false';
    }
    if (isAddress(barcode.rawContent)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) {
          return WalletViewScreen(pubkey: barcode!.rawContent);
        }),
      );
    } else {
      return 'false';
    }
    return barcode.rawContent;
  }

  // Future<String> pay(BuildContext context, {int? derivation}) async {
  //   MyWalletsProvider _myWalletProvider =
  //       Provider.of<MyWalletsProvider>(context, listen: false);
  //   int? currentChest = configBox.get('currentChest');
  //   String result;

  //     derivation ??=
  //         _myWalletProvider.getDefaultWallet(currentChest)!.derivation!;
  //     result = await Gva(node: endPointGVA).pay(
  //         recipient: pubkey!,
  //         amount: double.parse(payAmount.text),
  //         mnemonic: _myWalletProvider.mnemonic,
  //         comment: payComment.text,
  //         derivation: derivation,
  //         lang: appLang);

  //   return result;
  // }

  bool isAddress(address) {
    final RegExp regExp = RegExp(
      r'^[a-zA-Z0-9]+$',
      caseSensitive: false,
      multiLine: false,
    );

    if (regExp.hasMatch(address) == true &&
        address.length > 45 &&
        address.length < 52) {
      log.d("C'est une adresse !");

      this.address = address;

      return true;
    } else {
      return false;
    }
  }

// poka: Do99s6wQR2JLfhirPdpAERSjNbmjjECzGxHNJMiNKT3P
// Pi: D2meevcAHFTS2gQMvmRW5Hzi25jDdikk4nC4u1FkwRaU         // For debug
// Boris: JE6mkuzSpT3ePciCPRTpuMT9fqPUVVLJz2618d33p7tn
// Matograine portefeuille: 9p5nHsES6xujFR7pw2yGy4PLKKHgWsMvsDHaHF64Uj25.
// Lion simone: 78jhpprYkMNF6i5kQPXfkAVBpd2aqcpieNsXTSW4c21f

  void resetdHistory() {
    notifyListeners();
  }

  String generateIdenticon(String _pubkey) {
    return Jdenticon.toSvg(_pubkey);
  }

  // Future<num> getBalance(String _pubkey) async {
  //   final url = Uri.parse(
  //       '$endPointGVA?query={%20balance(script:%20%22$_pubkey%22)%20{%20amount%20base%20}%20}');
  //   final response = await http.get(url);
  //   final result = json.decode(response.body);

  //   if (result['data']['balance'] == null) {
  //     balance = 0.0;
  //   } else {
  //     balance = removeDecimalZero(result['data']['balance']['amount'] / 100);
  //   }

  //   return balance;
  // }

  Future<num?> getBalance(String? _pubkey) async {
    while (balance == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return balance;
  }

  void reload() {
    notifyListeners();
  }
}

snackCopyKey(context) {
  const snackBar = SnackBar(
      padding: EdgeInsets.all(20),
      content: Text("Cette adresse a été copié dans votre presse-papier.",
          style: TextStyle(fontSize: 16)),
      duration: Duration(seconds: 2));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
