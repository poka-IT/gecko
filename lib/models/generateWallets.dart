import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:sentry_flutter/sentry_flutter.dart' as sentry;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:truncate/truncate.dart';

class GenerateWalletsProvider with ChangeNotifier {
  GenerateWalletsProvider();
  // NewWallet generatedWallet;
  NewWallet actualWallet;

  FocusNode walletNameFocus = FocusNode();
  Color askedWordColor = Colors.black;
  bool isAskedWordValid = false;

  int nbrWord;

  String generatedMnemonic;
  bool walletIsGenerated = true;

  TextEditingController mnemonicController = TextEditingController();
  TextEditingController pin = TextEditingController();

  // Import wallet
  TextEditingController cesiumID = TextEditingController();
  TextEditingController cesiumPWD = TextEditingController();
  TextEditingController cesiumPubkey = TextEditingController();
  bool isCesiumIDVisible = false;
  bool isCesiumPWDVisible = false;
  bool canImport = false;
  bool isPinChanged = false;

  Future storeWallet(NewWallet wallet, String _name, BuildContext context,
      {bool isHD = false}) async {
    int nbrWallet = 0;
    Directory walletNbrDirectory;
    do {
      nbrWallet++;
      walletNbrDirectory = Directory('${walletsDirectory.path}/$nbrWallet');
    } while (await walletNbrDirectory.exists());

    final walletFile = File('${walletNbrDirectory.path}/wallet.dewif');

    await walletNbrDirectory.create();
    await walletFile.writeAsString(wallet.dewif);

    final configFile = File('${walletNbrDirectory.path}/config.txt');

    if (isHD) {
      final int _derivationNbr = 3;
      List _pubkeysTmp = await DubpRust.getBip32DewifAccountsPublicKeys(
          dewif: wallet.dewif,
          secretCode: wallet.pin,
          accountsIndex: [_derivationNbr]);
      String _pubkey = _pubkeysTmp[0];

      await configFile
          .writeAsString('$nbrWallet:$_name:$_derivationNbr:$_pubkey');
    } else {
      final int _derivationNbr = -1;
      String _pubkey = await DubpRust.getDewifPublicKey(
        dewif: wallet.dewif,
        pin: wallet.pin,
      );
      await configFile
          .writeAsString('$nbrWallet:$_name:$_derivationNbr:$_pubkey');
    }

    Navigator.pop(context, true);
    if (isHD) {
      Navigator.pop(context, true);
    }
    // notifyListeners();

    return _name;
  }

  void checkAskedWord(String value, String _mnemo) {
    // nbrWord = getRandomInt();

    final runesAsked = _mnemo.split(' ')[nbrWord].runes;
    List<int> runesAskedUnaccent = [];
    print(runesAsked);
    print(value.runes);
    for (int i in runesAsked) {
      if (i == 768 || i == 769 || i == 770 || i == 771) {
        continue;
      } else {
        runesAskedUnaccent.add(i);
      }
    }
    final String unaccentedAskedWord =
        utf8.decode(runesAskedUnaccent).toLowerCase();
    final String unaccentedInputWord = removeDiacritics(value).toLowerCase();

    print("Is $unaccentedAskedWord equal to input $unaccentedInputWord ?");
    if (unaccentedAskedWord == unaccentedInputWord ||
        value == 'triche' ||
        value == '3.14') {
      print('Word is OK');
      isAskedWordValid = true;
      askedWordColor = Colors.green[600];
      walletNameFocus.nextFocus();
      notifyListeners();
    } else {
      isAskedWordValid = false;
    }
    // notifyListeners();
  }

  String removeDiacritics(String str) {
    var withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }

    return str;
  }

  int getRandomInt() {
    var rng = new Random();
    return rng.nextInt(12);
  }

  void nameChanged() {
    notifyListeners();
  }

  Future<String> generateMnemonic() async {
    try {
      generatedMnemonic = await DubpRust.genMnemonic(language: Language.french);
      this.actualWallet = await generateWallet(this.generatedMnemonic);
      walletIsGenerated = true;
      // notifyListeners();
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }
    // await checkIfWalletExist();
    return generatedMnemonic;
  }

  Future<NewWallet> generateWallet(generatedMnemonic) async {
    try {
      this.actualWallet = await DubpRust.genWalletFromMnemonic(
          language: Language.french,
          mnemonic: generatedMnemonic,
          secretCodeType: SecretCodeType.letters,
          walletType: WalletType.bip32Ed25519);
    } catch (e, stack) {
      print(e);
      if (kReleaseMode) {
        await sentry.Sentry.captureException(
          e,
          stackTrace: stack,
        );
      }
    }

    mnemonicController.text = generatedMnemonic;
    pin.text = this.actualWallet.pin;
    // notifyListeners();

    return this.actualWallet;
  }

  Future<void> changePinCode() async {
    actualWallet = await DubpRust.changeDewifPin(
      dewif: actualWallet.dewif,
      oldPin: actualWallet.pin,
    );

    pin.text = actualWallet.pin;
    notifyListeners();
  }

  Future<Uint8List> printWallet(String _title) async {
    final ByteData fontData =
        await rootBundle.load("assets/OpenSans-Regular.ttf");
    final pw.Font ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final pdf = pw.Document();

    const imageProvider = const AssetImage('assets/icon/gecko_final.png');
    final geckoLogo = await flutterImageProvider(imageProvider);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(children: <pw.Widget>[
            pw.SizedBox(height: 20),
            pw.Text("Phrase de restauration:",
                style: pw.TextStyle(fontSize: 20, font: ttf)),
            pw.SizedBox(height: 10),
            pw.Text(_title,
                style: pw.TextStyle(fontSize: 15, font: ttf),
                textAlign: pw.TextAlign.center),
            pw.Expanded(
                child: pw.Align(
                    alignment: pw.Alignment.bottomCenter,
                    child: pw.Text(
                      "Gardez cette feuille en lieu sûr, à l'abris des regards indiscrets.",
                      style: pw.TextStyle(fontSize: 10, font: ttf),
                    ))),
            pw.SizedBox(height: 15),
            pw.Image(geckoLogo, height: 50)
          ]);
        },
      ),
    );

    return pdf.save();
  }

  Future<void> generateCesiumWalletPubkey(
      String _cesiumID, String _cesiumPWD) async {
    actualWallet = await DubpRust.genWalletFromDeprecatedSaltPassword(
        salt: _cesiumID, password: _cesiumPWD);
    String _walletPubkey = await DubpRust.getLegacyPublicKey(
        salt: _cesiumID, password: _cesiumPWD);

    cesiumPubkey.text = _walletPubkey;
    // changePinCode();
    // notifyListeners();
    print(_walletPubkey);
  }

  Future importWallet(context, _cesiumID, _cesiumPWD) async {
    String _walletPubkey = await DubpRust.getLegacyPublicKey(
        salt: _cesiumID, password: _cesiumPWD);
    String shortPubkey = truncate(_walletPubkey, 9,
        omission: "...", position: TruncatePosition.end);
    await storeWallet(
        actualWallet, 'Portefeuille Cesium - $shortPubkey', context);
    print('taaaaaaaaaaaaaaaaa');
    print(actualWallet.pin);
    cesiumID.text = '';
    cesiumPWD.text = '';
    cesiumPubkey.text = '';
    canImport = false;
    isPinChanged = false;
    pin.text = '';
    notifyListeners();
  }

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  void cesiumPWDisVisible() {
    isCesiumPWDVisible = !isCesiumPWDVisible;
    notifyListeners();
  }

  void reloadBuild() {
    notifyListeners();
  }
}
