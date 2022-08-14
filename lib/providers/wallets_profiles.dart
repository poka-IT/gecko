import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/g1_wallets_list.dart';
import 'package:gecko/providers/cesium_plus.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/providers/wallet_options.dart';
import 'package:gecko/screens/common_elements.dart';
import 'package:gecko/screens/wallet_view.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:qrscan/qrscan.dart' as scanner;
import 'package:barcode_scan2/barcode_scan2.dart';
import 'package:provider/provider.dart';

class WalletsProfilesProvider with ChangeNotifier {
  WalletsProfilesProvider(this.address);

  String? address = '';
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

  String generateIdenticon(String pubkey) {
    return Jdenticon.toSvg(pubkey);
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

  Future<num?> getBalance(String? pubkey) async {
    while (_balance == null) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return _balance;
  }

  Widget headerProfileView(
      BuildContext context, String address, String? username) {
    const double avatarSize = 140;

    WalletOptionsProvider walletOptions =
        Provider.of<WalletOptionsProvider>(context, listen: false);
    CesiumPlusProvider cesiumPlusProvider =
        Provider.of<CesiumPlusProvider>(context, listen: false);
    // SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    bool isAccountExist = balanceCache[address] != 0;

    return Stack(children: <Widget>[
      Consumer<SubstrateSdk>(builder: (context, sub, _) {
        return Container(
            height: 180,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isAccountExist ? yellowC : Colors.grey[400]!,
                  isAccountExist ? const Color(0xFFE7811A) : Colors.grey[600]!,
                ],
              ),
            ));
      }),
      Padding(
        padding: const EdgeInsets.only(left: 30, right: 40),
        child: Row(children: <Widget>[
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  height: 10,
                  color: yellowC, // Colors.grey[400],
                ),
                Row(children: [
                  GestureDetector(
                    key: const Key('copyPubkey'),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: address));
                      snackCopyKey(context);
                    },
                    child: Text(
                      getShortPubkey(address),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 25),
                balance(context, address, 22),
                const SizedBox(height: 10),
                walletOptions.idtyStatus(context, address,
                    isOwner: false, color: Colors.black),
                getCerts(context, address, 14),
                if (username == null &&
                    g1WalletsBox.get(address)?.username != null)
                  SizedBox(
                    width: 230,
                    child: Text(
                      g1WalletsBox.get(address)?.username ?? '',
                      style: const TextStyle(
                        fontSize: 27,
                        color: Color(0xff814C00),
                      ),
                    ),
                  ),
                if (username != null)
                  SizedBox(
                    width: 230,
                    child: Text(
                      username,
                      style: const TextStyle(
                        fontSize: 27,
                        color: Color(0xff814C00),
                      ),
                    ),
                  ),
                const SizedBox(height: 55),
              ]),
          const Spacer(),
          Column(children: <Widget>[
            ClipOval(
              child: cesiumPlusProvider.defaultAvatar(avatarSize),
            ),
            const SizedBox(height: 25),
          ]),
        ]),
      ),
      CommonElements().offlineInfo(context),
    ]);
  }

  bool isContact(String address) {
    return contactsBox.containsKey(address);
  }

  void addContact(G1WalletsList profile) {
    log.d(profile.username);
    if (isContact(profile.pubkey!)) {
      contactsBox.delete(profile.pubkey);
    } else {
      contactsBox.put(profile.pubkey, profile);
    }
    notifyListeners();
  }

  void reload() {
    notifyListeners();
  }
}

snackCopyKey(context) {
  final snackBar = SnackBar(
      padding: const EdgeInsets.all(20),
      content: Text("thisAddressHasBeenCopiedToClipboard".tr(),
          style: const TextStyle(fontSize: 16)),
      duration: const Duration(seconds: 2));
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
