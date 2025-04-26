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
import 'package:gecko/models/wallet_balance.dart';
import 'package:gecko/providers/substrate_sdk.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import 'package:polkawallet_sdk/api/apiKeyring.dart';
import 'package:provider/provider.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

class GenerateWalletsProvider with ChangeNotifier {
  GenerateWalletsProvider();

  final walletNameFocus = FocusNode();
  Color? askedWordColor = Colors.black;
  bool isAskedWordValid = false;
  var scanStatus = ScanDerivationsStatus.none;
  int scanedValidWalletNumber = -1;
  int scanedWalletNumber = -1;
  int numberScan = 30;

  late int nbrWord;
  String? nbrWordAlpha;

  String? generatedMnemonic;
  bool walletIsGenerated = true;

  final mnemonicController = TextEditingController();

  // Import wallet
  final cesiumID = TextEditingController();
  final cesiumPWD = TextEditingController();
  final cesiumPubkey = TextEditingController();
  bool isCesiumIDVisible = false;
  bool isCesiumPWDVisible = false;
  bool canImport = false;
  late durt.CesiumWallet cesiumWallet;

  // Import Chest
  final cellController0 = TextEditingController();
  final cellController1 = TextEditingController();
  final cellController2 = TextEditingController();
  final cellController3 = TextEditingController();
  final cellController4 = TextEditingController();
  final cellController5 = TextEditingController();
  final cellController6 = TextEditingController();
  final cellController7 = TextEditingController();
  final cellController8 = TextEditingController();
  final cellController9 = TextEditingController();
  final cellController10 = TextEditingController();
  final cellController11 = TextEditingController();
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

    if (expectedWord == normInputWord || (kDebugMode && inputWord == 'triche')) {
      isAskedWordValid = true;
      askedWordColor = Colors.green[600];
      notifyListeners();
    } else {
      isAskedWordValid = false;
    }
  }

  String removeDiacritics(String str) {
    var withDia = 'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    var withoutDia = 'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

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

  Future<void> generateCesiumWalletPubkey(String cesiumID, String cesiumPWD) async {
    cesiumWallet = durt.CesiumWallet(cesiumID, cesiumPWD);
    String walletPubkey = cesiumWallet.pubkey;

    cesiumPubkey.text = walletPubkey;
  }

  void cesiumIDisVisible() {
    isCesiumIDVisible = !isCesiumIDVisible;
    notifyListeners();
  }

  void cesiumPWDisVisible() {
    isCesiumPWDVisible = !isCesiumPWDVisible;
    notifyListeners();
  }

  Future<List<String>?> generateWordList(BuildContext context) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    if (!sub.sdkReady) return null;

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
          isValid = nbrMatch == 0;
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
    cellController0.text = cellController1.text = cellController2.text = cellController3.text = cellController4.text = cellController5.text =
        cellController6.text = cellController7.text = cellController8.text = cellController9.text = cellController10.text = cellController11.text = '';
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
    if (sentence?.text == null || sentence!.text!.split(' ').length != 12) return;

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
    for (var word in sentence.text!.split(' ')) {
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

  Future<ScanDerivationsResult> scanDerivations(BuildContext context, String pinCode) async {
    try {
      return await _scanDerivations(context, pinCode).timeout(
        const Duration(seconds: 20),
        onTimeout: () async {
          // Remove the current chest
          final currentChestNumber = configBox.get('currentChest');
          if (currentChestNumber != null) {
            final currentChest = chestBox.get(currentChestNumber);
            if (currentChest != null) {
              await chestBox.delete(currentChestNumber);
            }
          }

          // Display error message to user
          // ignore: use_build_context_synchronously
          await infoPopup(context, "timeoutScanDerivations".tr());

          // Pop to home
          Navigator.popUntil(
            // ignore: use_build_context_synchronously
            context,
            ModalRoute.withName('/'),
          );

          return ScanDerivationsResult.timeout;
        },
      );
    } catch (e) {
      // Handle any other errors
      await infoPopup(context, "errorScanDerivations".tr());

      Navigator.popUntil(
        // ignore: use_build_context_synchronously
        context,
        ModalRoute.withName('/'),
      );

      return ScanDerivationsResult.error;
    }
  }

  Future<ScanDerivationsResult> _scanDerivations(BuildContext context, String pinCode) async {
    final sub = Provider.of<SubstrateSdk>(context, listen: false);
    final currentChestNumber = configBox.get('currentChest');
    bool isAlive = false;
    scanedWalletNumber = 0;
    Map<String, int> addressToScan = {};
    notifyListeners();

    if (!sub.nodeConnected) {
      return ScanDerivationsResult.error;
    }

    scanStatus = ScanDerivationsStatus.rootScanning;
    final hasRoot = await scanRootBalance(sub, currentChestNumber, pinCode);
    notifyListeners();
    if (hasRoot) {
      isAlive = true;
    }

    scanStatus = ScanDerivationsStatus.scanning;
    for (int derivationNbr in [for (var i = 0; i < numberScan; i += 1) i]) {
      final addressData = await sub.sdk.api.keyring
          .addressFromMnemonic(sub.currencyParameters['ss58']!, cryptoType: CryptoType.sr25519, mnemonic: generatedMnemonic!, derivePath: '//$derivationNbr');
      addressToScan.putIfAbsent(addressData.address!, () => derivationNbr);
    }

    final balanceList = await sub.getBalanceMulti(addressToScan.keys.toList()).timeout(
          const Duration(seconds: 20),
          onTimeout: () => {},
        );

    // Remove unused wallets
    balanceList.removeWhere((key, value) => value.transferableBalance == 0);
    scanedValidWalletNumber = balanceList.length + scanedWalletNumber;

    scanStatus = ScanDerivationsStatus.import;
    for (String scannedWallet in balanceList.keys) {
      isAlive = true;
      String walletName = scanedWalletNumber == 0 ? 'currentWallet'.tr() : '${'wallet'.tr()} ${scanedWalletNumber + 1}';
      await sub.importAccount(mnemonic: generatedMnemonic!, derivePath: "//${addressToScan[scannedWallet]}", password: pinCode);

      WalletData myWallet = WalletData(
          chest: currentChestNumber,
          address: scannedWallet,
          number: scanedWalletNumber,
          name: walletName,
          derivation: addressToScan[scannedWallet],
          imageDefaultPath: '${scanedWalletNumber % 4}.png',
          isOwned: true);
      await walletBox.put(myWallet.address, myWallet);
      scanedWalletNumber++;
      notifyListeners();
    }

    scanStatus = ScanDerivationsStatus.none;
    scanedWalletNumber = scanedValidWalletNumber = -1;
    notifyListeners();
    return isAlive ? ScanDerivationsResult.walletExists : ScanDerivationsResult.walletNotFound;
  }

  Future<bool> scanRootBalance(SubstrateSdk sub, int currentChestNumber, String pinCode) async {
    if (sub.currencyParameters['ss58'] == null || generatedMnemonic == null) return false;
    final addressData =
        await sub.sdk.api.keyring.addressFromMnemonic(sub.currencyParameters['ss58']!, cryptoType: CryptoType.sr25519, mnemonic: generatedMnemonic!);

    if (addressData.address == null) return false;
    final balance = await sub.getBalance(addressData.address!).timeout(
          const Duration(seconds: 1),
          onTimeout: () => WalletBalance.empty(),
        );

    if (balance.transferableBalance != 0) {
      String walletName = 'myRootWallet'.tr();
      await sub.importAccount(mnemonic: generatedMnemonic!, password: pinCode);

      WalletData myWallet = WalletData(
          chest: currentChestNumber, address: addressData.address!, number: 0, name: walletName, derivation: -1, imageDefaultPath: '0.png', isOwned: true);
      await walletBox.put(myWallet.address, myWallet);
      scanedWalletNumber++;
      return true;
    } else {
      return false;
    }
  }
}
