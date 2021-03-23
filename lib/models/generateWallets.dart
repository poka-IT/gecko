import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
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
  String nbrWordAlpha;

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

  Future storeHDWChest(
      NewWallet _wallet, String _name, BuildContext context) async {
    // Directory walletDirectory;

    final Directory hdDirectory = Directory('${walletsDirectory.path}/0');
    await hdDirectory.create();

    final configFile = File('${hdDirectory.path}/list.conf');
    File _currentChestFile = File('${walletsDirectory.path}/currentChest.conf');

    final dewifFile = File('${hdDirectory.path}/wallet.dewif');

    // List<String> _lastConfig = [];
    // _lastConfig = await masterConfigFile.readAsLines();
    // final int _lastDerivation = int.parse(_lastConfig.last.split(':')[2]);
    // final int _derivationNbr = _lastDerivation + 3;

    final int _derivationNbr = 3;
    List _pubkeysTmp = await DubpRust.getBip32DewifAccountsPublicKeys(
        dewif: _wallet.dewif,
        secretCode: _wallet.pin,
        accountsIndex: [_derivationNbr]);
    String _pubkey = _pubkeysTmp[0];

    await configFile.writeAsString('0:0:$_name:$_derivationNbr:$_pubkey');
    await dewifFile.writeAsString(_wallet.dewif);
    bool isCurrentChestExist = _currentChestFile.existsSync();
    if (isCurrentChestExist) {
      await _currentChestFile.delete();
    }
    await _currentChestFile.create();
    await _currentChestFile.writeAsString('0');

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
      // walletNameFocus.nextFocus();
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

  String intToString(int _nbr) {
    Map nbrToString = {};
    nbrToString[1] = 'Premier';
    nbrToString[2] = 'Deuxième';
    nbrToString[3] = 'Troisième';
    nbrToString[4] = 'Quatrième';
    nbrToString[5] = 'Cinquième';
    nbrToString[6] = 'Sixième';
    nbrToString[7] = 'Septième';
    nbrToString[8] = 'Huitième';
    nbrToString[9] = 'Neuvième';
    nbrToString[10] = 'Dixième';
    nbrToString[11] = 'Onzième';
    nbrToString[12] = 'Douzième';

    nbrWordAlpha = nbrToString[_nbr];

    return nbrWordAlpha;
  }

  void nameChanged() {
    notifyListeners();
  }

  Future<String> generateMnemonic() async {
    try {
      generatedMnemonic = await DubpRust.genMnemonic(language: Language.french);
      this.actualWallet = await generateWallet(this.generatedMnemonic);
      walletIsGenerated = true;
    } catch (e) {
      print(e);
    }
    return generatedMnemonic;
  }

  Future<NewWallet> generateWallet(generatedMnemonic) async {
    try {
      this.actualWallet = await DubpRust.genWalletFromMnemonic(
        language: Language.french,
        mnemonic: generatedMnemonic,
        secretCodeType: SecretCodeType.letters,
      );
    } catch (e) {
      print(e);
    }

    mnemonicController.text = generatedMnemonic;
    pin.text = this.actualWallet.pin;
    // notifyListeners();

    return this.actualWallet;
  }

  Future<NewWallet> changePinCode({bool reload}) async {
    actualWallet = await DubpRust.changeDewifPin(
      dewif: actualWallet.dewif,
      oldPin: actualWallet.pin,
    );

    pin.text = actualWallet.pin;
    isPinChanged = true;
    if (reload) {
      notifyListeners();
    }
    return actualWallet;
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
    pin.text = actualWallet.pin;
    isPinChanged = true;
    print(_walletPubkey);
  }

  Future importWallet(context, _cesiumID, _cesiumPWD) async {
    // String _walletPubkey = await DubpRust.getLegacyPublicKey(
    //     salt: _cesiumID, password: _cesiumPWD);
    // String shortPubkey = truncate(_walletPubkey, 9,
    //     omission: "...", position: TruncatePosition.end);
    // await storeWallet(
    //     actualWallet, 'Portefeuille Cesium - $shortPubkey', context);
    cesiumID.text = '';
    cesiumPWD.text = '';
    cesiumPubkey.text = '';
    canImport = false;
    isPinChanged = false;
    pin.text = '';
    isCesiumIDVisible = false;
    isCesiumPWDVisible = false;
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

  void resetImportView() {
    cesiumID.text = '';
    cesiumPWD.text = '';
    cesiumPubkey.text = '';
    pin.text = '';
    canImport = false;
    isPinChanged = false;
    isCesiumIDVisible = false;
    isCesiumPWDVisible = false;
    actualWallet = null;
    notifyListeners();
  }

  Future<List<String>> generateWordList() async {
    final String _sentance = await generateMnemonic();
    List<String> _wordsList = [];
    String word;
    int _nbr = 1;

    for (word in _sentance.split(' ')) {
      // print(word);
      _wordsList.add("$_nbr:$word");
      _nbr++;
    }
    // notifyListeners();

    return _wordsList;
  }

  // void makeError() {
  //   var tata = File(appPath.path + '/ddfhjftjfg');
  //   tata.readAsLinesSync();
  // }

  void reloadBuild() {
    notifyListeners();
  }
}
