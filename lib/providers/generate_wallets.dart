import 'dart:math';
import 'dart:typed_data';
import 'package:durt/durt.dart' as durt;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/bip39_words.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

class GenerateWalletsProvider with ChangeNotifier {
  GenerateWalletsProvider();
  // NewWallet generatedWallet;
  durt.NewWallet? actualWallet;

  FocusNode walletNameFocus = FocusNode();
  Color? askedWordColor = Colors.black;
  bool isAskedWordValid = false;

  late int nbrWord;
  String? nbrWordAlpha;

  String? generatedMnemonic;
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
  late durt.CesiumWallet cesiumWallet;

  // Import Chest
  TextEditingController cellController0 = TextEditingController();
  TextEditingController cellController1 = TextEditingController();
  TextEditingController cellController2 = TextEditingController();
  TextEditingController cellController3 = TextEditingController();
  TextEditingController cellController4 = TextEditingController();
  TextEditingController cellController5 = TextEditingController();
  TextEditingController cellController6 = TextEditingController();
  TextEditingController cellController7 = TextEditingController();
  TextEditingController cellController8 = TextEditingController();
  TextEditingController cellController9 = TextEditingController();
  TextEditingController cellController10 = TextEditingController();
  TextEditingController cellController11 = TextEditingController();
  bool isFirstTimeSentenceComplete = true;

  Future storeHDWChest(
      String address, String _name, BuildContext context) async {
    int chestNumber = chestBox.isEmpty ? 0 : chestBox.keys.last + 1;

    String chestName;
    if (chestNumber == 0) {
      chestName = 'Coffre à Ğecko';
    } else {
      chestName = 'Coffre à Ğecko ${chestNumber + 1}';
    }
    await configBox.put('currentChest', chestNumber);

    ChestData thisChest = ChestData(
      name: chestName,
      defaultWallet: 0,
      imageName: '${chestNumber % 8}.png',
    );
    await chestBox.add(thisChest);
    int? chestKey = chestBox.keys.last;

    WalletData myWallet = WalletData(
        version: dataVersion,
        chest: chestKey,
        address: address,
        number: 0,
        name: _name,
        derivation: 2,
        imageDefaultPath: '0.png');
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

  String? intToString(int _nbr) {
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

  String changePinCode({required bool reload}) {
    pin.text = durt.randomSecretCode(pinLength);
    if (reload) {
      notifyListeners();
    }
    return pin.text;
  }

  Future<Uint8List> printWallet(AsyncSnapshot<List>? mnemoList) async {
    final ByteData fontData =
        await rootBundle.load("assets/OpenSans-Regular.ttf");
    final pw.Font ttf = pw.Font.ttf(fontData.buffer.asByteData());
    final pdf = pw.Document();

    // const imageProvider = AssetImage('assets/icon/gecko_final.png');
    // final geckoLogo = await flutterImageProvider(imageProvider);

    pw.Widget arrayCell(dataWord) {
      return pw.SizedBox(
        width: 120,
        child: pw.Column(children: <pw.Widget>[
          pw.Text(
            dataWord.split(':')[0],
            style: pw.TextStyle(
                fontSize: 15, color: const PdfColor(0.5, 0, 0), font: ttf),
          ),
          pw.Text(
            dataWord.split(':')[1],
            style: pw.TextStyle(
                fontSize: 20, color: const PdfColor(0, 0, 0), font: ttf),
          ),
          pw.SizedBox(height: 10)
        ]),
      );
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            // mainAxisAlignment: pw.MainAxisAlignment.center,
            // mainAxisSize: pw.MainAxisSize.max,
            // crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: <pw.Widget>[
              pw.Row(children: <pw.Widget>[
                arrayCell(mnemoList!.data![0]),
                arrayCell(mnemoList.data![1]),
                arrayCell(mnemoList.data![2]),
                arrayCell(mnemoList.data![3]),
              ]),
              pw.Row(children: <pw.Widget>[
                arrayCell(mnemoList.data![4]),
                arrayCell(mnemoList.data![5]),
                arrayCell(mnemoList.data![6]),
                arrayCell(mnemoList.data![7]),
              ]),
              pw.Row(children: <pw.Widget>[
                arrayCell(mnemoList.data![8]),
                arrayCell(mnemoList.data![9]),
                arrayCell(mnemoList.data![10]),
                arrayCell(mnemoList.data![11])
              ]),
              pw.Expanded(
                  child: pw.Align(
                      alignment: pw.Alignment.bottomCenter,
                      child: pw.Text(
                        "Gardez cette feuille préciseusement, à l’abri des lézards indiscrets.",
                        style: pw.TextStyle(fontSize: 15, font: ttf),
                      )))
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> generateCesiumWalletPubkey(
      String _cesiumID, String _cesiumPWD) async {
    cesiumWallet = durt.CesiumWallet(_cesiumID, _cesiumPWD);
    String _walletPubkey = cesiumWallet.pubkey;

    cesiumPubkey.text = _walletPubkey;
    log.d(_walletPubkey);
  }

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  void cesiumPWDisVisible() {
    isCesiumPWDVisible = !isCesiumPWDVisible;
    notifyListeners();
  }

  void resetCesiumImportView() {
    cesiumID.text = cesiumPWD.text = cesiumPubkey.text = pin.text = '';
    canImport = isCesiumIDVisible = isCesiumPWDVisible = false;
    actualWallet = null;
    notifyListeners();
  }

  Future<List<String>> generateWordList(BuildContext context) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);

    generatedMnemonic = await _sub.generateMnemonic(lang: appLang);
    List<String> _wordsList = [];
    String word;
    int _nbr = 1;

    for (word in generatedMnemonic!.split(' ')) {
      _wordsList.add("$_nbr:$word");
      _nbr++;
    }

    return _wordsList;
  }

  bool isBipWord(String word) {
    notifyListeners();

    // Needed for bad encoding of UTF-8
    word = word.replaceAll('é', 'é');
    word = word.replaceAll('è', 'è');
    return bip39Words(appLang).contains(word.toLowerCase());
  }

  bool isBipWordsList(List<String> words) {
    bool isValid = true;
    for (String word in words) {
      // Needed for bad encoding of UTF-8
      word = word.replaceAll('é', 'é');
      word = word.replaceAll('è', 'è');
      if (!bip39Words(appLang).contains(word.toLowerCase())) {
        isValid = false;
      }
    }
    return isValid;
  }

  void resetImportView() {
    cellController0.text = cellController1.text = cellController2.text =
        cellController3.text = cellController4.text = cellController5.text =
            cellController6.text = cellController7.text = cellController8.text =
                cellController9.text =
                    cellController10.text = cellController11.text = '';
    isFirstTimeSentenceComplete = true;
    notifyListeners();
  }

  bool isSentenceComplete(BuildContext context) {
    if (isBipWordsList(
      [
        cellController0.text,
        cellController1.text,
        cellController2.text,
        cellController3.text,
        cellController4.text,
        cellController5.text,
        cellController6.text,
        cellController7.text,
        cellController8.text,
        cellController9.text,
        cellController10.text,
        cellController11.text
      ],
    )) {
      if (isFirstTimeSentenceComplete) {
        FocusScope.of(context).unfocus();
      }
      isFirstTimeSentenceComplete = false;
      return true;
    } else {
      return false;
    }
  }

  Future pasteMnemonic(BuildContext context) async {
    final sentence = await Clipboard.getData('text/plain');
    int nbr = 0;

    List cells = [
      cellController0,
      cellController1,
      cellController2,
      cellController3,
      cellController4,
      cellController5,
      cellController6,
      cellController7,
      cellController8,
      cellController9,
      cellController10,
      cellController11
    ];
    for (var word in sentence!.text!.split(' ')) {
      bool isValid = isBipWord(word);

      if (isValid) {
        cells[nbr].text = word;
      }
      nbr++;
    }
  }

  void reloadBuild() {
    notifyListeners();
  }

  Future scanDerivations(BuildContext context, {int number = 10}) async {
    SubstrateSdk _sub = Provider.of<SubstrateSdk>(context, listen: false);
    final ss58 = _sub.ss58;

    // for ()
    // final addressData = await _sub.sdk.api.keyring.addressFromMnemonic(ss58,
    //     cryptoType: CryptoType.sr25519,
    //     mnemonic: generatedMnemonic!,
    //     derivePath: '//4');

    // final balance = await _sub.getBalance(addressData.address!);

    // log.d(balance);
    // if (balance != 0) {
    //   await _sub.importAccount(
    //       mnemonic: '',
    //       fromMnemonic: true,
    //       derivePath: '//4',
    //       password: pin.text);
    // }
  }
}
