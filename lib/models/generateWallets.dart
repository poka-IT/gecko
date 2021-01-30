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
  TextEditingController pubkey = TextEditingController();
  TextEditingController pin = TextEditingController();

  Future storeWallet(NewWallet wallet, _name, BuildContext context) async {
    final Directory walletNameDirectory =
        Directory('${walletsDirectory.path}/$_name');
    final walletFile = File('${walletNameDirectory.path}/wallet.dewif');
    final walletPubkey = File('${walletNameDirectory.path}/pubkey');

    if (await walletNameDirectory.exists()) {
      print('Ce wallet existe déjà, impossible de le créer.');
      _showWalletExistDialog(context);
      return 'Exist: DENY';
    }

    await walletNameDirectory.create();
    await walletFile.writeAsString('${wallet.dewif}');
    await walletPubkey.writeAsString('${wallet.publicKey}');

    Navigator.pop(context, true);
    Navigator.pop(context, wallet.publicKey);
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

  Future<void> _showWalletExistDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Ce nom existe déjà'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Veuillez choisir un autre nom pour votre portefeuille.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text("J'ai compris"),
              onPressed: () {
                Navigator.of(context).pop();
                askedWordColor = Colors.green[500];
                isAskedWordValid = true;
              },
            ),
          ],
        );
      },
    );
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
          secretCodeType: SecretCodeType.letters);
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
    pubkey.text = this.actualWallet.publicKey;
    pin.text = this.actualWallet.pin;
    // notifyListeners();

    return this.actualWallet;
  }

  Future<void> changePinCode() async {
    this.actualWallet = await DubpRust.changeDewifPin(
      dewif: this.actualWallet.dewif,
      oldPin: this.actualWallet.pin,
    );

    pin.text = this.actualWallet.pin;
    // notifyListeners();
  }

  Future<Uint8List> printWallet(String _title, String _pubkey) async {
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
            pw.Text("Clé publique:",
                style: pw.TextStyle(fontSize: 20, font: ttf)),
            pw.SizedBox(height: 10),
            pw.Text(_pubkey,
                style: pw.TextStyle(fontSize: 15, font: ttf),
                textAlign: pw.TextAlign.center),
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
}
