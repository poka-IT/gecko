import 'dart:async';
import 'dart:math';
import 'package:durt/durt.dart' as durt;
import 'package:durt2/durt2.dart' show Language, WalletBalance, WalletEntity, IdtyStatus, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/bip39_words.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gecko/widgets/commons/common_elements.dart';
import "package:unorm_dart/unorm_dart.dart" as unorm;

class GenerateWalletsProvider with ChangeNotifier {
  late ProviderContainer _container;

  GenerateWalletsProvider() {
    _container = ProviderContainer();
  }

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

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

  // @Deprecated('Use Durt 2 instead')
  // Future storeHDWChest(BuildContext context) async {
  //   int chestNumber = chestBox.isEmpty ? 0 : chestBox.keys.last + 1;

  //   String chestName;
  //   if (chestNumber == 0) {
  //     chestName = 'geckoChest'.tr();
  //   } else {
  //     chestName = '${'geckoChest'.tr()}${chestNumber + 1}';
  //   }
  //   await configBox.put('currentChest', chestNumber);

  //   ChestData thisChest = ChestData(
  //     name: chestName,
  //     defaultWallet: 0,
  //     imageName: '${chestNumber % 8}.png',
  //   );
  //   await chestBox.add(thisChest);
  //   int? chestKey = chestBox.keys.last;

  //   await configBox.put('currentChest', chestKey);
  //   notifyListeners();
  // }

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
    final language = switch (appLang) {
      'english' => Language.english,
      'french' => Language.french,
      'spanish' => Language.spanish,
      'italian' => Language.italian,
      _ => Language.english,
    };

    final generatedMnemonicTyped = _container.read(walletServiceProvider).generateMnemonic(language: language);

    generatedMnemonic = generatedMnemonicTyped.sentence;
    return generatedMnemonicTyped.words;
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
    cellController0.text = cellController1.text = cellController2.text = cellController3.text = cellController4.text =
        cellController5.text = cellController6.text = cellController7.text = cellController8.text =
            cellController9.text = cellController10.text = cellController11.text = '';
    isFirstTimeSentenceComplete = true;
    notifyListeners();
  }

  bool isSentenceComplete(BuildContext context) {
    if (isBipWordsList([
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
      cellController11.text,
    ])) {
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
    if (sentence?.text == null || sentence!.text!.split(' ').length != 12) {
      return;
    }

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
      cellController11,
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
        const Duration(seconds: 120),
        onTimeout: () async {
          // Remove the current chest
          final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;
          await _container.read(walletServiceProvider).deleteSafe(actualSafeNumber);

          // Display error message to user
          // ignore: use_build_context_synchronously
          await infoPopup(context, "timeoutScanDerivations".tr());

          // Remove all wallets
          await _container.read(walletServiceProvider).walletBox.removeAllAsync();
          await _container.read(walletServiceProvider).safeBox.removeAllAsync();

          // Pop to home
          // ignore: use_build_context_synchronously
          await Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);

          return ScanDerivationsResult.timeout;
        },
      );
    } catch (e) {
      log.e('Error scanning derivations: $e');
      // Handle any other errors
      // ignore: use_build_context_synchronously
      await infoPopup(context, "errorScanDerivations".tr());

      // Remove all wallets
      await _container.read(walletServiceProvider).walletBox.removeAllAsync();
      await _container.read(walletServiceProvider).safeBox.removeAllAsync();

      // ignore: use_build_context_synchronously
      await Navigator.of(context).pushNamedAndRemoveUntil('/', (Route<dynamic> route) => false);

      return ScanDerivationsResult.error;
    }
  }

  Future<ScanDerivationsResult> _scanDerivations(BuildContext context, String pinCode) async {
    bool isAlive = false;
    scanedWalletNumber = 0;
    Map<String, int> addressToScan = {};
    notifyListeners();

    if (!_container.read(durtProvider).isConnected) {
      return ScanDerivationsResult.error;
    }

    scanStatus = ScanDerivationsStatus.rootScanning;
    notifyListeners();
    final hasRoot = await scanRootBalance(pinCode);
    if (hasRoot) {
      isAlive = true;
    }

    scanStatus = ScanDerivationsStatus.scanning;
    notifyListeners();
    for (int derivationNbr in [for (var i = 0; i < numberScan; i += 1) i]) {
      final keypair = await _container
          .read(walletServiceProvider)
          .getKeyPairFromMnemonic(generatedMnemonic!, derivation: derivationNbr);
      addressToScan.putIfAbsent(keypair.address, () => derivationNbr);
    }

    final balanceList = await _container
        .read(storageServiceProvider)
        .getBalances(addressToScan.keys.toList())
        .timeout(const Duration(seconds: 20), onTimeout: () => throw TimeoutException('Timeout scanning derivations'));

    // Remove unused wallets
    balanceList.removeWhere((key, value) => value.free == BigInt.zero);
    scanedValidWalletNumber = balanceList.length + scanedWalletNumber;

    scanStatus = ScanDerivationsStatus.import;
    notifyListeners();
    for (String scannedWallet in balanceList.keys) {
      isAlive = true;
      String walletName = scanedWalletNumber == 0 ? 'currentWallet'.tr() : '${'wallet'.tr()} ${scanedWalletNumber + 1}';
      final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;

      final myWallet = WalletEntity.create(
        address: scannedWallet,
        name: walletName,
        derivation: addressToScan[scannedWallet],
        imagePath: 'assets/avatars/${scanedWalletNumber % 4}.png',
        keyPairType: Durt.defaultKeyPairType,
        identityStatus: IdtyStatus.unknown,
      );

      final safe = _container.read(walletServiceProvider).getSafeBox(actualSafeNumber);
      myWallet.safe.target = safe;

      await _container.read(walletServiceProvider).walletBox.putAsync(myWallet);
      scanedWalletNumber++;
      notifyListeners();
    }

    scanStatus = ScanDerivationsStatus.none;
    scanedWalletNumber = scanedValidWalletNumber = -1;
    notifyListeners();
    return isAlive ? ScanDerivationsResult.walletExists : ScanDerivationsResult.walletNotFound;
  }

  Future<bool> scanRootBalance(String pinCode) async {
    if (generatedMnemonic == null) return false;

    final keypair = await _container.read(walletServiceProvider).getKeyPairFromMnemonic(generatedMnemonic!);

    final address = _container.read(walletServiceProvider).getAddress(keypair.address);

    // if (addressData.address == null) return false;
    final balance = await _container
        .read(storageServiceProvider)
        .getBalance(address)
        .timeout(const Duration(seconds: 1), onTimeout: () => WalletBalance.empty());

    if (balance.free != BigInt.zero) {
      String walletName = 'myRootWallet'.tr();

      // await _container.read(walletServiceProvider).importRootWallet(pinCode: pinCode);

      final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;

      WalletEntity myWallet = WalletEntity(
        address: address,
        name: walletName,
        derivation: -1,
        imagePath: 'assets/avatars/0.png',
      );

      final safe = _container.read(walletServiceProvider).getSafeBox(actualSafeNumber);
      myWallet.safe.target = safe;

      await _container.read(walletServiceProvider).walletBox.putAsync(myWallet);
      scanedWalletNumber++;
      return true;
    } else {
      return false;
    }
  }
}
