import 'dart:async';
import 'dart:math';
import 'package:durt/durt.dart' as durt;
import 'package:durt2/durt2.dart' show WalletBalance, WalletEntity, Durt, BidouilleLang;
import 'package:durt2/objectbox.g.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/scan_derivations_info.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';

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

  String? generatedMnemonic; // Mnemonic in user's language (for display/copy/validation)
  String? _englishMnemonic; // English mnemonic for crypto operations
  BidouilleLang? _originalMnemonicLanguage; // Language in which the mnemonic was originally entered/generated
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

  // Import safe
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

  void checkAskedWord(String inputWord, String mnemo) {
    final expectedWord = mnemo.split(' ')[nbrWord];
    final normInputWord = inputWord;

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
    // Check if user wants to generate mnemonics in English (expert mode option)
    final generateInEnglish = configBox.get('generateMnemonicsInEnglish') ?? false;

    // Get system language from easy_localization context
    final languageCode = context.locale.languageCode;
    final targetLanguage = BidouilleLang.fromLanguageCode(languageCode);

    // Always generate English mnemonic first (master seed)
    final englishMnemonicTyped = _container
        .read(walletServiceProvider)
        .generateMnemonic(language: BidouilleLang.english.toBip39Language());
    final englishMnemonic = englishMnemonicTyped.sentence;

    // Store English for crypto operations
    _englishMnemonic = englishMnemonic;

    // If expert mode option is enabled, always display in English
    if (generateInEnglish) {
      generatedMnemonic = englishMnemonic;
      _originalMnemonicLanguage = BidouilleLang.english; // User chose English
      log.i('Generated English mnemonic (expert option enabled)');
      return englishMnemonic.split(' ');
    }

    // For non-English languages, convert to target language index by index
    if (targetLanguage != BidouilleLang.english) {
      final multilangService = _container.read(walletServiceProvider).multilangService;
      final convertedMnemonic = await multilangService.convertFromEnglish(englishMnemonic, targetLanguage);

      // Store converted mnemonic for user display (English is stored in safe for crypto)
      generatedMnemonic = convertedMnemonic;
      _originalMnemonicLanguage = targetLanguage; // User generated in their language

      log.i('Generated English master seed, converted to ${targetLanguage.code} for display');
      return convertedMnemonic.split(' ');
    } else {
      // For English, same mnemonic for everything
      generatedMnemonic = englishMnemonic;
      _originalMnemonicLanguage = BidouilleLang.english; // User generated in English
      log.i('Generated English mnemonic for all operations');
      return englishMnemonic.split(' ');
    }
  }

  /// Get the English mnemonic for crypto operations
  /// This is always in English regardless of display language
  String getEnglishMnemonic() {
    if (_englishMnemonic == null) {
      throw StateError('No mnemonic has been generated yet');
    }
    // Return the cached English mnemonic for BIP39 crypto operations
    return _englishMnemonic!;
  }

  /// Get the original language in which the mnemonic was entered/generated
  BidouilleLang? getOriginalMnemonicLanguage() {
    return _originalMnemonicLanguage;
  }

  /// Set a mnemonic from external source (migration, import, etc.)
  /// This properly detects the language and sets both display and English versions
  Future<void> setMnemonicFromExternal(String mnemonic) async {
    try {
      final multilangService = _container.read(walletServiceProvider).multilangService;
      final words = mnemonic.split(' ');
      final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords(words);

      if (detectedLanguage == null) {
        throw Exception('Invalid mnemonic: no valid language detected');
      }

      // Set the display mnemonic (user's input)
      generatedMnemonic = mnemonic;
      _originalMnemonicLanguage = detectedLanguage;

      if (detectedLanguage == BidouilleLang.english) {
        // Input is already English, store directly
        _englishMnemonic = mnemonic;
      } else {
        // Input is in another language, convert to English for crypto operations
        _englishMnemonic = await _convertToEnglishForValidation(mnemonic, detectedLanguage);
      }

      log.i('Set external mnemonic: detected language=${detectedLanguage.code}, English ready for crypto ops');
    } catch (e) {
      log.e('Failed to set external mnemonic: $e');
      throw Exception('Failed to process mnemonic: $e');
    }
  }

  /// Validate complete mnemonic integrity (checksum) by converting to English and using BIP39 validation
  Future<bool> isValidCompleteMnemonic(String mnemonic) async {
    try {
      final words = mnemonic.split(' ');
      final multilangService = _container.read(walletServiceProvider).multilangService;
      final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords(words);

      if (detectedLanguage == null) {
        return false; // No valid language detected
      }

      if (detectedLanguage == BidouilleLang.english) {
        // Direct validation for English
        return _container.read(walletServiceProvider).isMnemonicValid(mnemonic);
      } else {
        // Convert to English and validate
        final multilangService = _container.read(walletServiceProvider).multilangService;
        final englishMnemonic = await multilangService.convertToEnglish(mnemonic, sourceLanguage: detectedLanguage);
        return _container.read(walletServiceProvider).isMnemonicValid(englishMnemonic);
      }
    } catch (e) {
      // Conversion failed, invalid mnemonic
      return false;
    }
  }

  /// Convert user language mnemonic to English for validation purposes
  Future<String> _convertToEnglishForValidation(String userMnemonic, BidouilleLang sourceLanguage) async {
    final multilangService = _container.read(walletServiceProvider).multilangService;
    return await multilangService.convertToEnglish(userMnemonic, sourceLanguage: sourceLanguage);
  }

  void resetImportView() {
    cellController0.text = cellController1.text = cellController2.text = cellController3.text = cellController4.text =
        cellController5.text = cellController6.text = cellController7.text = cellController8.text =
            cellController9.text = cellController10.text = cellController11.text = '';
    isFirstTimeSentenceComplete = true;
    notifyListeners();
  }

  /// Called when a mnemonic word changes to trigger validation and UI update
  Future<void> onMnemonicWordChanged() async {
    // Update the generated mnemonic from current field values
    if (await isSentenceComplete()) {
      final userMnemonic = [
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
      ].join(' ');

      // Store the user's mnemonic (for display)
      generatedMnemonic = userMnemonic;

      // Detect the language of the input mnemonic and convert accordingly
      try {
        final multilangService = _container.read(walletServiceProvider).multilangService;
        final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords(userMnemonic.split(' '));

        if (detectedLanguage == BidouilleLang.english) {
          // Input is already English, store directly
          _englishMnemonic = userMnemonic;
          _originalMnemonicLanguage = BidouilleLang.english;
        } else if (detectedLanguage != null) {
          // Input is in another language, convert to English
          _englishMnemonic = await _convertToEnglishForValidation(userMnemonic, detectedLanguage);
          _originalMnemonicLanguage = detectedLanguage;
        } else {
          // Invalid mnemonic, keep _englishMnemonic null
          _englishMnemonic = null;
          _originalMnemonicLanguage = null;
        }
      } catch (e) {
        // If conversion fails, keep _englishMnemonic null
        _englishMnemonic = null;
        _originalMnemonicLanguage = null;
      }
    }

    // Notify UI to rebuild with new validation state
    notifyListeners();
  }

  Future<bool> isSentenceComplete() async {
    // First check if all individual words are valid BIP39 words
    final allWords = [
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
    ];

    final multilangService = _container.read(walletServiceProvider).multilangService;
    if (await multilangService.areAllWordsValidInAnyLanguage(allWords)) {
      // If all words are valid, check the complete mnemonic integrity (checksum)
      final completeMnemonic = allWords.join(' ');

      if (await isValidCompleteMnemonic(completeMnemonic)) {
        if (isFirstTimeSentenceComplete) {
          // ignore: use_build_context_synchronously
          FocusScope.of(homeContext).unfocus();
        }
        isFirstTimeSentenceComplete = false;
        return true;
      }
    }

    return false;
  }

  Future<void> pasteMnemonic(BuildContext context) async {
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
      // Use multilang validation - check if word is valid in current language
      // ignore: use_build_context_synchronously
      final languageCode = homeContext.locale.languageCode;
      final preferredLanguage = BidouilleLang.fromLanguageCode(languageCode);
      final multilangService = _container.read(walletServiceProvider).multilangService;
      bool isValid = await multilangService.isValidWordInAnyLanguage(
        word,
        checkRedundance: false,
        preferredLanguage: preferredLanguage,
      );

      if (isValid) {
        cells[nbr].text = word;
      }
      nbr++;
    }

    // Trigger validation and UI update after pasting all words
    await onMnemonicWordChanged();
  }

  void reloadBuild() {
    notifyListeners();
  }

  Future<ScanDerivationsResult> scanDerivations(BuildContext context) async {
    try {
      return await _scanDerivations(context).timeout(
        const Duration(seconds: 120),
        onTimeout: () async {
          // Remove the current safe
          final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;
          await _container.read(walletServiceProvider).deleteSafe(actualSafeNumber);

          // Display error message to user
          // ignore: use_build_context_synchronously
          await showConfirmationDialog(
            // ignore: use_build_context_synchronously
            context: context,
            message: "timeoutScanDerivations".tr(),
            confirmText: "gotit".tr(),
            hideCancelButton: true,
            type: ConfirmationDialogType.error,
          );
          // Remove all wallets
          await _container.read(walletServiceProvider).walletBox.removeAllAsync();
          await _container.read(walletServiceProvider).safeBox.removeAllAsync();

          // Pop to home
          // ignore: use_build_context_synchronously
          await Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (Route<dynamic> route) => false);

          return ScanDerivationsResult.timeout;
        },
      );
    } catch (e) {
      log.e('Error scanning derivations: $e');
      // Handle any other errors
      await showConfirmationDialog(
        // ignore: use_build_context_synchronously
        context: context,
        message: "errorScanDerivations".tr(),
        confirmText: "gotit".tr(),
        hideCancelButton: true,
        type: ConfirmationDialogType.error,
      );

      // Remove all wallets
      await _container.read(walletServiceProvider).walletBox.removeAllAsync();
      await _container.read(walletServiceProvider).safeBox.removeAllAsync();

      // ignore: use_build_context_synchronously
      await Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.home, (Route<dynamic> route) => false);

      return ScanDerivationsResult.error;
    }
  }

  Future<ScanDerivationsResult> _scanDerivations(BuildContext context) async {
    bool isAlive = false;
    scanedWalletNumber = 0;
    Map<String, int> addressToScan = {};
    notifyListeners();

    if (!_container.read(durtProvider).isConnected) {
      return ScanDerivationsResult.error;
    }

    // 1. SCAN ROOT BALANCE
    scanStatus = ScanDerivationsStatus.rootScanning;
    notifyListeners();
    final hasRoot = await scanRootBalance();
    if (hasRoot) {
      isAlive = true;
    }

    // 2. PARALLEL KEYPAIR GENERATION
    scanStatus = ScanDerivationsStatus.scanning;
    notifyListeners();

    // Generate all keypairs in parallel instead of sequentially
    // Convert stored mnemonic (in user's language) to English for crypto operations
    final englishMnemonic = getEnglishMnemonic();
    final derivationNumbers = [for (var i = 0; i < numberScan; i += 1) i];
    final keypairFutures = derivationNumbers
        .map(
          (derivationNbr) => _container
              .read(walletServiceProvider)
              .getKeyPairFromMnemonic(englishMnemonic, derivation: derivationNbr, keyPairType: Durt.defaultKeyPairType)
              .then((keypair) => MapEntry(derivationNbr, keypair)),
        )
        .toList();

    // Wait for all keypairs to be generated in parallel
    final keypairResults = await Future.wait(keypairFutures);

    // Build the address to derivation map
    for (final entry in keypairResults) {
      addressToScan.putIfAbsent(entry.value.address, () => entry.key);
    }

    // 2.5. CHECK FOR EXISTING ADDRESSES IN STORED WALLETS
    // Collect all addresses to check (including root if it exists)
    final allAddressesToCheck = <String>[];

    // Add root address if it was scanned and found
    if (scanedWalletNumber > 0) {
      // Root wallet was added, get its address
      final englishMnemonic = getEnglishMnemonic();
      final rootKeypair = await _container.read(walletServiceProvider).getKeyPairFromMnemonic(englishMnemonic);
      allAddressesToCheck.add(rootKeypair.address);
    }

    // Add all derived addresses
    allAddressesToCheck.addAll(addressToScan.keys);

    // Check if any address already exists in stored wallets (excluding current safe)
    final duplicateAddresses = <String>[];
    final currentSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;

    for (final address in allAddressesToCheck) {
      // Check if address exists in any wallet
      final existingWallet = _container
          .read(walletServiceProvider)
          .walletBox
          .query(WalletEntity_.address.equals(address))
          .build()
          .findFirst();

      if (existingWallet != null) {
        // Check if this wallet belongs to a different safe than the current one
        final walletSafeNumber = existingWallet.safe.target?.number;
        if (walletSafeNumber != null && walletSafeNumber != currentSafeNumber) {
          duplicateAddresses.add(address);
        }
      }
    }

    if (duplicateAddresses.isNotEmpty) {
      // Remove the current safe (which removes all its wallets too)
      final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;
      await _container.read(walletServiceProvider).deleteSafe(actualSafeNumber);

      // Restore the previous defaultSafeBoxNumber (highest remaining safe number)
      final safeBox = _container.read(walletServiceProvider).safeBox;
      if (!safeBox.isEmpty()) {
        final maxSafeNumber = safeBox.query().build().property(SafeEntity_.number).max();
        _container.read(walletServiceProvider).setDefaultSafeBoxNumber(maxSafeNumber);
      }

      // Show error dialog
      await showConfirmationDialog(
        // ignore: use_build_context_synchronously
        context: context,
        type: ConfirmationDialogType.error,
        title: 'error'.tr(),
        message: 'safeAlreadyExist'.tr(),
        hideCancelButton: true,
      );

      // Navigate back to home
      // ignore: use_build_context_synchronously
      Navigator.of(context).popUntil((route) => route.isFirst);

      return ScanDerivationsResult.error;
    }

    // 3. BALANCE CHECK (already optimized - single batch call)
    final balanceList = await _container
        .read(storageServiceProvider)
        .getBalances(addressToScan.keys.toList())
        .timeout(const Duration(seconds: 20), onTimeout: () => throw TimeoutException('Timeout scanning derivations'));

    // Remove unused wallets
    balanceList.removeWhere((key, value) => value.free == BigInt.zero);
    scanedValidWalletNumber = balanceList.length + scanedWalletNumber;

    // 4. PARALLEL WALLET IMPORT WITH PRESERVED ORDER
    scanStatus = ScanDerivationsStatus.import;
    notifyListeners();

    if (balanceList.isNotEmpty) {
      isAlive = true;

      // Sort wallets by derivation number to preserve order
      final sortedWallets = balanceList.keys.toList()..sort((a, b) => addressToScan[a]!.compareTo(addressToScan[b]!));

      // Prepare wallet data in parallel
      final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;
      final safe = _container.read(walletServiceProvider).getSafeBox(actualSafeNumber);

      final walletDataList = <({WalletEntity wallet, int index})>[];
      for (int i = 0; i < sortedWallets.length; i++) {
        final scannedWallet = sortedWallets[i];
        final walletIndex = scanedWalletNumber + i;
        final walletName = walletIndex == 0 ? 'currentWallet'.tr() : '${'wallet'.tr()} ${walletIndex + 1}';

        final myWallet = WalletEntity.create(
          address: scannedWallet,
          name: walletName,
          derivation: addressToScan[scannedWallet],
          imagePath: 'assets/avatars/${walletIndex % 4}.png',
          keyPairType: Durt.defaultKeyPairType,
        );

        myWallet.safe.target = safe;
        walletDataList.add((wallet: myWallet, index: walletIndex));
      }

      // Import wallets in parallel batches to avoid overwhelming the system
      const batchSize = 5; // Process 5 wallets at a time
      for (int batchStart = 0; batchStart < walletDataList.length; batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize).clamp(0, walletDataList.length);
        final batch = walletDataList.sublist(batchStart, batchEnd);

        // Import current batch in parallel
        await Future.wait(
          batch.map((walletData) => _container.read(walletServiceProvider).walletBox.putAsync(walletData.wallet)),
        );

        // Update progress
        scanedWalletNumber = batch.last.index + 1;
        notifyListeners();
      }
    }

    scanStatus = ScanDerivationsStatus.none;
    scanedWalletNumber = scanedValidWalletNumber = -1;
    notifyListeners();
    return isAlive ? ScanDerivationsResult.walletExists : ScanDerivationsResult.walletNotFound;
  }

  Future<bool> scanRootBalance() async {
    if (generatedMnemonic == null) return false;

    // Convert stored mnemonic (in user's language) to English for crypto operations
    final englishMnemonic = getEnglishMnemonic();
    final keypair = await _container.read(walletServiceProvider).getKeyPairFromMnemonic(englishMnemonic);

    final address = keypair.address;

    final balance = await _container
        .read(storageServiceProvider)
        .getBalance(address)
        .timeout(const Duration(seconds: 1), onTimeout: () => WalletBalance.empty());

    if (balance.free != BigInt.zero) {
      String walletName = 'myRootWallet'.tr();

      final actualSafeNumber = _container.read(walletServiceProvider).defaultSafeBoxNumber;

      WalletEntity myWallet = WalletEntity.create(
        address: address,
        name: walletName,
        imagePath: 'assets/avatars/0.png',
        keyPairType: Durt.defaultKeyPairType,
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
