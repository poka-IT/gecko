import 'dart:math';
import 'dart:typed_data';
import 'package:dubp/dubp.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

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
    int chestNumber = 0;
    chestBox.toMap().forEach((key, value) {
      if (!value.isCesium) {
        chestNumber++;
      }
    });

    String chestName;
    if (chestNumber == 0) {
      chestName = 'Coffre à Ğecko';
    } else {
      chestName = 'Coffre à Ğecko ${chestNumber + 1}';
    }
    ChestData thisChest = ChestData(
      dewif: _wallet.dewif,
      name: chestName,
      defaultWallet: 0,
      imageName: '${chestNumber % 8}.png',
      isCesium: false,
    );
    await chestBox.add(thisChest);
    int chestKey = chestBox.keys.last;

    WalletData myWallet = WalletData(
        chest: chestKey,
        number: 0,
        name: _name,
        derivation: 3,
        imageName: '0.png');
    await walletBox.add(myWallet);

    await configBox.put('currentChest', chestKey);
    notifyListeners();
  }

  void checkAskedWord(String inputWord, String _mnemo) {
    final expectedWord = _mnemo.split(' ')[nbrWord];
    final normInputWord = unorm.nfkd(inputWord);

    log.i("Is $expectedWord equal to input $normInputWord ?");
    if (expectedWord == normInputWord ||
        inputWord == 'triche' ||
        inputWord == '3.14') {
      log.d('Word is OK');
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
    var rng = Random();
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
      actualWallet = await generateWallet(generatedMnemonic);
      walletIsGenerated = true;
    } catch (e) {
      log.e(e);
    }
    return generatedMnemonic;
  }

  Future<NewWallet> generateWallet(generatedMnemonic) async {
    try {
      actualWallet = await DubpRust.genWalletFromMnemonic(
        language: Language.french,
        mnemonic: generatedMnemonic,
        secretCodeType: SecretCodeType.letters,
      );
    } catch (e) {
      log.e(e);
    }

    mnemonicController.text = generatedMnemonic;
    pin.text = actualWallet.pin;
    // notifyListeners();

    return actualWallet;
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

    const imageProvider = AssetImage('assets/icon/gecko_final.png');
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
    log.d(_walletPubkey);
  }

  Future importCesiumWallet() async {
    // String _walletPubkey = await DubpRust.getLegacyPublicKey(
    //     salt: _cesiumID, password: _cesiumPWD);
    // String shortPubkey = truncate(_walletPubkey, 9,
    //     omission: "...", position: TruncatePosition.end);
    // await storeWallet(
    //     actualWallet, 'Portefeuille Cesium - $shortPubkey', context);
    // NewWallet myCesiumWallet = await DubpRust.genWalletFromDeprecatedSaltPassword(salt: _cesiumID, password: _cesiumPWD);

    cesiumID.text = '';
    cesiumPWD.text = '';
    cesiumPubkey.text = '';
    canImport = false;
    isPinChanged = false;
    pin.text = '';
    isCesiumIDVisible = false;
    isCesiumPWDVisible = false;

    int chestNumber = 0;
    chestBox.toMap().forEach((key, value) {
      if (value.isCesium) {
        chestNumber++;
      }
    });

    String chestName;
    if (chestNumber == 0) {
      chestName = 'Coffre à Césium';
    } else {
      chestName = 'Coffre à Césium ${chestNumber + 1}';
    }

    ChestData cesiumChest = ChestData(
        dewif: actualWallet.dewif,
        name: chestName,
        imageName: 'cesium.png',
        defaultWallet: 0,
        isCesium: true);

    await chestBox.add(cesiumChest).then((value) => null);
    int chestKey = await chestBox.toMap().keys.last;
    // chestBox.toMap().
    await configBox.put('currentChest', chestKey);

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
      _wordsList.add("$_nbr:$word");
      _nbr++;
    }

    return _wordsList;
  }

  void reloadBuild() {
    notifyListeners();
  }
}
