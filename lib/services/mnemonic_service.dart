import 'package:durt2/durt2.dart' show BidouilleLang, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/globals.dart';

/// Service for handling BIP39 mnemonic operations.
///
/// This service provides pure functions for mnemonic generation, validation,
/// language detection, and conversion between languages. It does not manage state.
class MnemonicService {
  /// Generate a mnemonic word list in the target language.
  ///
  /// Always generates an English master seed for crypto operations and optionally
  /// converts it to the target language for display purposes.
  ///
  /// Returns a [MnemonicResult] containing both the display mnemonic and the English mnemonic.
  static Future<MnemonicResult> generateMnemonic({
    required BidouilleLang targetLanguage,
    bool forceEnglish = false,
  }) async {
    // Always generate English mnemonic first (master seed)
    final englishMnemonicTyped = Durt.i.wallets.generateMnemonic(language: BidouilleLang.english.toBip39Language());
    final englishMnemonic = englishMnemonicTyped.sentence;

    // If force English or target is English, return English for both
    if (forceEnglish || targetLanguage == BidouilleLang.english) {
      log.i('Generated English mnemonic (${forceEnglish ? 'forced' : 'target language'})');
      return MnemonicResult(
        displayMnemonic: englishMnemonic,
        englishMnemonic: englishMnemonic,
        originalLanguage: BidouilleLang.english,
      );
    }

    // For non-English languages, convert to target language for display
    try {
      final multilangService = Durt.i.wallets.multilangService;
      final convertedMnemonic = await multilangService.convertFromEnglish(englishMnemonic, targetLanguage);

      log.i('Generated English master seed, converted to ${targetLanguage.code} for display');
      return MnemonicResult(
        displayMnemonic: convertedMnemonic,
        englishMnemonic: englishMnemonic,
        originalLanguage: targetLanguage,
      );
    } catch (e) {
      log.e('Failed to convert mnemonic to ${targetLanguage.code}, using English: $e');
      // Fallback to English if conversion fails
      return MnemonicResult(
        displayMnemonic: englishMnemonic,
        englishMnemonic: englishMnemonic,
        originalLanguage: BidouilleLang.english,
      );
    }
  }

  /// Detect and validate a mnemonic from user input.
  ///
  /// Returns a [MnemonicResult] with the validated mnemonic or null if invalid.
  static Future<MnemonicResult?> validateAndProcessMnemonic(String inputMnemonic) async {
    try {
      final words = inputMnemonic.trim().split(' ');
      if (words.length != 12) {
        return null; // Invalid length
      }

      final multilangService = Durt.i.wallets.multilangService;
      final detectedLanguage = await multilangService.detectMnemonicLanguageFromWords(words);

      if (detectedLanguage == null) {
        return null; // No valid language detected
      }

      String englishMnemonic;
      if (detectedLanguage == BidouilleLang.english) {
        // Input is already English
        englishMnemonic = inputMnemonic;
      } else {
        // Convert to English for crypto operations
        englishMnemonic = await multilangService.convertToEnglish(inputMnemonic, sourceLanguage: detectedLanguage);
      }

      // Validate the English mnemonic with BIP39
      if (!Durt.i.wallets.isMnemonicValid(englishMnemonic)) {
        return null; // Invalid mnemonic checksum
      }

      return MnemonicResult(
        displayMnemonic: inputMnemonic,
        englishMnemonic: englishMnemonic,
        originalLanguage: detectedLanguage,
      );
    } catch (e) {
      log.e('Error validating mnemonic: $e');
      return null;
    }
  }

  /// Check if a single word is valid in any supported language.
  static Future<bool> isValidBip39Word(String word, {BidouilleLang? preferredLanguage}) async {
    if (word.trim().isEmpty || word.length < 3) {
      return false;
    }

    try {
      final multilangService = Durt.i.wallets.multilangService;
      return await multilangService.isValidWordInAnyLanguage(
        word.trim().toLowerCase(),
        checkRedundance: false,
        preferredLanguage: preferredLanguage,
      );
    } catch (e) {
      return false;
    }
  }

  /// Check if all words in a list are valid BIP39 words in any language.
  static Future<bool> areAllWordsValid(List<String> words) async {
    if (words.length != 12) {
      return false;
    }

    try {
      final multilangService = Durt.i.wallets.multilangService;
      return await multilangService.areAllWordsValidInAnyLanguage(words);
    } catch (e) {
      return false;
    }
  }

  /// Parse clipboard content and extract potential mnemonic words.
  ///
  /// Returns a list of 12 words if valid, empty list otherwise.
  static Future<List<String>> parseClipboardMnemonic({BidouilleLang? preferredLanguage}) async {
    try {
      final clipboardData = await Clipboard.getData('text/plain');
      final text = clipboardData?.text?.trim();

      if (text == null || text.isEmpty) {
        return [];
      }

      final words = text.split(' ').where((w) => w.trim().isNotEmpty).toList();
      if (words.length != 12) {
        return [];
      }

      // Validate each word
      final validWords = <String>[];
      for (final word in words) {
        final cleanWord = word.trim().toLowerCase();
        if (await isValidBip39Word(cleanWord, preferredLanguage: preferredLanguage)) {
          validWords.add(cleanWord);
        } else {
          return []; // One invalid word makes the whole mnemonic invalid
        }
      }

      return validWords;
    } catch (e) {
      log.e('Error parsing clipboard mnemonic: $e');
      return [];
    }
  }

  /// Convert ordinal number to localized string representation.
  static String getOrdinalString(int number, BuildContext context) {
    final Map<int, String> ordinalMap = {
      1: '1th'.tr(),
      2: '2th'.tr(),
      3: '3th'.tr(),
      4: '4th'.tr(),
      5: '5th'.tr(),
      6: '6th'.tr(),
      7: '7th'.tr(),
      8: '8th'.tr(),
      9: '9th'.tr(),
      10: '10th'.tr(),
      11: '11th'.tr(),
      12: '12th'.tr(),
    };

    return ordinalMap[number] ?? '${number}th';
  }
}

/// Result class for mnemonic operations.
class MnemonicResult {
  /// The mnemonic as it should be displayed to the user (in their preferred language).
  final String displayMnemonic;

  /// The English version of the mnemonic for crypto operations.
  final String englishMnemonic;

  /// The original language of the mnemonic.
  final BidouilleLang originalLanguage;

  const MnemonicResult({required this.displayMnemonic, required this.englishMnemonic, required this.originalLanguage});

  /// Get the display mnemonic as a list of words.
  List<String> get displayWords => displayMnemonic.split(' ');

  /// Get the English mnemonic as a list of words.
  List<String> get englishWords => englishMnemonic.split(' ');

  bool get isEnglish => originalLanguage == BidouilleLang.english;
}
