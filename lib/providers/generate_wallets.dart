import 'dart:math';
import 'package:durt/durt.dart' as durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/bip39_words.dart';
import 'package:gecko/models/chest_data.dart';
import 'package:gecko/models/wallet_data.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

class GenerateWalletsProvider with ChangeNotifier {
  GenerateWalletsProvider();

  final walletNameFocus = FocusNode();
  Color? askedWordColor = Colors.black;
  bool isAskedWordValid = false;
  int scanedValidWalletNumber = -1;
  int scanedWalletNumber = -1;
  int numberScan = 60;

  late int nbrWord;
  String? nbrWordAlpha;

  String? generatedMnemonic;
  bool walletIsGenerated = true;

  final mnemonicController = TextEditingController();
  final pin = TextEditingController();

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

  Future storeHDWChest(BuildContext context) async {
    int chestNumber = chestBox.isEmpty ? 0 : chestBox.keys.last + 1;

    String chestName;
    if (chestNumber == 0) {
      chestName = 'geckoChest'.tr();
    } else {
      chestName = '${'geckoChest'.tr()}${chestNumber + 1}';
    }
    await configBox.put('currentChest', chestNumber);

    ChestData thisChest = ChestData(
      name: chestName,
      defaultWallet: 0,
      imageName: '${chestNumber % 8}.png',
    );
    await chestBox.add(thisChest);
    int? chestKey = chestBox.keys.last;

    await configBox.put('currentChest', chestKey);
    notifyListeners();
  }

  void checkAskedWord(String inputWord, String mnemo) {
    final expectedWord = mnemo.split(' ')[nbrWord];
    final normInputWord = unorm.nfkd(inputWord);

    log.i("Is $expectedWord equal to input $normInputWord ?");
    if (expectedWord == normInputWord ||
        (kDebugMode && inputWord == 'triche')) {
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

  String? intToString(int nbr) {
    Map nbrToString = {};
    nbrToString[1] = '1th'.tr();
    nbrToString[2] = '2th'.tr();
    nbrToString[3] = '3th'.tr();
    nbrToString[4] = '4th'.tr();
    nbrToString[5] = '5th'.tr();
    nbrToString[6] = '6th'.tr();
    nbrToString[7] = '7th'.tr();
    nbrToString[8] = '8th'.tr();
    nbrToString[9] = '9th'.tr();
    nbrToString[10] = '10th'.tr();
    nbrToString[11] = '11th'.tr();
    nbrToString[12] = '12th'.tr();

    nbrWordAlpha = nbrToString[nbr];

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

  Future<void> generateCesiumWalletPubkey(
      String cesiumID, String cesiumPWD) async {
    cesiumWallet = durt.CesiumWallet(cesiumID, cesiumPWD);
    String walletPubkey = cesiumWallet.pubkey;

    cesiumPubkey.text = walletPubkey;
    log.d(walletPubkey);
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
    notifyListeners();
  }

  Future<List<String>> generateWordList(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);

    generatedMnemonic = await sub.generateMnemonic(lang: appLang);
    List<String> wordsList = [];
    String word;
    int nbr = 1;

    for (word in generatedMnemonic!.split(' ')) {
      wordsList.add("$nbr:$word");
      nbr++;
    }

    return wordsList;
  }

  bool isBipWord(String word, [bool checkRedondance = true]) {
    bool isValid = false;
    notifyListeners();

    // Needed for bad encoding of UTF-8
    word = word.replaceAll('é', 'é');
    word = word.replaceAll('è', 'è');

    int nbrMatch = 0;
    if (bip39Words(appLang).contains(word.toLowerCase())) {
      for (var bipWord in bip39Words(appLang)) {
        if (bipWord.startsWith(word)) {
          isValid = nbrMatch == 0 ? true : false;
          if (checkRedondance) nbrMatch = nbrMatch + 1;
        }
      }
    }

    return isValid;
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
    if (sentence?.text == null) return;
    for (var word in sentence!.text!.split(' ')) {
      bool isValid = isBipWord(word, false);

      if (isValid) {
        cells[nbr].text = word;
      }
      nbr++;
    }
  }

  void reloadBuild() {
    notifyListeners();
  }

  Future<bool> scanDerivations(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final currentChestNumber = configBox.get('currentChest');
    bool isAlive = false;
    scanedValidWalletNumber = 0;
    scanedWalletNumber = 0;
    Map<String, int> addressToScan = {};
    notifyListeners();

    if (!sub.nodeConnected) {
      return false;
    }

    final hasRoot = await scanRootBalance(sub, currentChestNumber);
    scanedWalletNumber = 1;
    notifyListeners();
    if (hasRoot) {
      scanedValidWalletNumber = 1;
      isAlive = true;
    }

    for (int derivationNbr in [for (var i = 0; i < numberScan; i += 1) i]) {
      final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
          sub.currencyParameters['ss58']!,
          cryptoType: CryptoType.sr25519,
          mnemonic: generatedMnemonic!,
          derivePath: '//$derivationNbr');
      addressToScan.putIfAbsent(addressData.address!, () => derivationNbr);
    }

    final balanceList =
        await sub.getBalanceMulti(addressToScan.keys.toList()).timeout(
              const Duration(seconds: 20),
              onTimeout: () => {},
            );

    for (String scannedWallet in balanceList.keys) {
      if (balanceList[scannedWallet]!['transferableBalance'] != 0) {
        isAlive = true;
        String walletName = scanedValidWalletNumber == 0
            ? 'currentWallet'.tr()
            : '${'wallet'.tr()} ${scanedValidWalletNumber + 1}';
        await sub.importAccount(
            mnemonic: generatedMnemonic!,
            derivePath: "//${addressToScan[scannedWallet]}",
            password: pin.text);

        WalletData myWallet = WalletData(
            chest: currentChestNumber,
            address: scannedWallet,
            number: scanedValidWalletNumber,
            name: walletName,
            derivation: addressToScan[scannedWallet],
            imageDefaultPath: '${scanedValidWalletNumber % 4}.png',
            isOwned: true);
        await walletBox.put(myWallet.address, myWallet);
        scanedValidWalletNumber = scanedValidWalletNumber + 1;
      }
      scanedWalletNumber = scanedWalletNumber + 1;
      notifyListeners();
    }

    log.d(scanedWalletNumber);
    scanedWalletNumber = -1;
    scanedValidWalletNumber = -1;
    notifyListeners();
    return isAlive;
  }

  Future<bool> scanRootBalance(SubstrateSdk sub, int currentChestNumber) async {
    final addressData = await sub.sdk.api.keyring.addressFromMnemonic(
        sub.currencyParameters['ss58']!,
        cryptoType: CryptoType.sr25519,
        mnemonic: generatedMnemonic!);

    final balance = await sub.getBalance(addressData.address!).timeout(
          const Duration(seconds: 1),
          onTimeout: () => {},
        );

    log.d(
        "${addressData.address!}: ${balance['transferableBalance']} $currencyName");
    if (balance['transferableBalance'] != 0) {
      String walletName = 'myRootWallet'.tr();
      await sub.importAccount(mnemonic: generatedMnemonic!, password: pin.text);

      WalletData myWallet = WalletData(
          chest: currentChestNumber,
          address: addressData.address!,
          number: 0,
          name: walletName,
          derivation: -1,
          imageDefaultPath: '0.png',
          isOwned: true);
      await walletBox.put(myWallet.address, myWallet);
      return true;
    } else {
      return false;
    }
  }
}
