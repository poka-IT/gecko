import 'dart:math';
import 'package:durt2/durt2.dart' show BidouilleLang;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/main.dart';

import 'package:gecko/services/mnemonic_service.dart';

/// Provider for MnemonicService instance
final mnemonicServiceProvider = Provider<MnemonicService>((ref) {
  return MnemonicService();
});

/// State for mnemonic generation and validation
class MnemonicState {
  final MnemonicResult? mnemonicResult;
  final bool isLoading;
  final String? error;

  const MnemonicState({this.mnemonicResult, this.isLoading = false, this.error});

  MnemonicState copyWith({MnemonicResult? mnemonicResult, bool? isLoading, String? error}) {
    return MnemonicState(
      mnemonicResult: mnemonicResult ?? this.mnemonicResult,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasMnemonic => mnemonicResult != null;
  List<String> get displayWords => mnemonicResult?.displayWords ?? [];
  String get englishMnemonic => mnemonicResult?.englishMnemonic ?? '';
  BidouilleLang? get originalLanguage => mnemonicResult?.originalLanguage;
}

/// Notifier for managing mnemonic generation and validation
class MnemonicStateNotifier extends Notifier<MnemonicState> {
  @override
  MnemonicState build() {
    return const MnemonicState();
  }

  /// Generate a new mnemonic in the specified language
  Future<void> generateMnemonic({required BidouilleLang targetLanguage, bool forceEnglish = false}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await MnemonicService.generateMnemonic(targetLanguage: targetLanguage, forceEnglish: forceEnglish);

      state = state.copyWith(mnemonicResult: result, isLoading: false);
    } catch (e) {
      log.e('Error generating mnemonic: $e');
      state = state.copyWith(error: 'Failed to generate mnemonic: $e', isLoading: false);
    }
  }

  /// Set mnemonic from external source (like import)
  Future<void> setMnemonic(String mnemonic) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await MnemonicService.validateAndProcessMnemonic(mnemonic);

      if (result != null) {
        state = state.copyWith(mnemonicResult: result, isLoading: false);
      } else {
        state = state.copyWith(error: 'Invalid mnemonic', isLoading: false);
      }
    } catch (e) {
      log.e('Error setting mnemonic: $e');
      state = state.copyWith(error: 'Failed to process mnemonic: $e', isLoading: false);
    }
  }

  /// Clear the current mnemonic
  void clearMnemonic() {
    state = const MnemonicState();
  }
}

/// Provider for mnemonic state management
final mnemonicStateProvider = NotifierProvider<MnemonicStateNotifier, MnemonicState>(MnemonicStateNotifier.new);

/// State for mnemonic word input validation
class MnemonicInputState {
  final List<String> words;
  final bool isValid;
  final bool isComplete;
  final Map<int, bool> wordValidations;
  final Map<int, String> wordSuggestions;

  const MnemonicInputState({
    this.words = const [],
    this.isValid = false,
    this.isComplete = false,
    this.wordValidations = const {},
    this.wordSuggestions = const {},
  });

  MnemonicInputState copyWith({
    List<String>? words,
    bool? isValid,
    bool? isComplete,
    Map<int, bool>? wordValidations,
    Map<int, String>? wordSuggestions,
  }) {
    return MnemonicInputState(
      words: words ?? this.words,
      isValid: isValid ?? this.isValid,
      isComplete: isComplete ?? this.isComplete,
      wordValidations: wordValidations ?? this.wordValidations,
      wordSuggestions: wordSuggestions ?? this.wordSuggestions,
    );
  }

  String get mnemonicString => words.join(' ');
  bool get hasAllWords => words.length == 12 && words.every((w) => w.isNotEmpty);
}

/// Notifier for managing mnemonic input validation
class MnemonicInputNotifier extends Notifier<MnemonicInputState> {
  /// When true, controller listeners skip updateWord to prevent race conditions.
  bool _bulkUpdating = false;

  @override
  MnemonicInputState build() {
    return MnemonicInputState(words: List.filled(12, ''));
  }

  /// Update a specific word and validate it
  Future<void> updateWord(int index, String word) async {
    if (_bulkUpdating) return;
    if (index < 0 || index >= 12) return;

    final cleanWord = word.trim().toLowerCase();
    final newWords = List<String>.from(state.words);
    newWords[index] = cleanWord;

    // Validate the individual word
    final isWordValid = cleanWord.isEmpty || await MnemonicService.isValidBip39Word(cleanWord);
    final newValidations = Map<int, bool>.from(state.wordValidations);
    newValidations[index] = isWordValid;

    // Find suggestion for invalid words (3+ chars)
    final newSuggestions = Map<int, String>.from(state.wordSuggestions);
    if (!isWordValid && cleanWord.length >= 3) {
      final suggestion = await MnemonicService.findClosestBip39Word(cleanWord);
      if (suggestion != null) {
        newSuggestions[index] = suggestion;
      } else {
        newSuggestions.remove(index);
      }
    } else {
      newSuggestions.remove(index);
    }

    state = state.copyWith(words: newWords, wordValidations: newValidations, wordSuggestions: newSuggestions);

    // Check if complete and valid
    await _validateComplete();
  }

  /// Validate the complete mnemonic
  Future<void> _validateComplete() async {
    if (!state.hasAllWords) {
      state = state.copyWith(isComplete: false, isValid: false);
      return;
    }

    try {
      final result = await MnemonicService.validateAndProcessMnemonic(state.mnemonicString);
      state = state.copyWith(isComplete: true, isValid: result != null);
    } catch (e) {
      state = state.copyWith(isComplete: true, isValid: false);
    }
  }

  /// Fill words from a list (e.g., from clipboard or OCR).
  ///
  /// If [updateControllers] is provided, they are updated WHILE listener
  /// callbacks are suppressed, preventing race conditions.
  Future<void> fillWords(List<String> words, {List<TextEditingController>? updateControllers}) async {
    if (words.length != 12) return;

    _bulkUpdating = true;
    try {
      final cleanWords = words.map((w) => w.trim().toLowerCase()).toList();
      final validations = <int, bool>{};

      for (int i = 0; i < cleanWords.length; i++) {
        validations[i] = await MnemonicService.isValidBip39Word(cleanWords[i]);
      }

      state = state.copyWith(words: cleanWords, wordValidations: validations);

      // Update controllers while listeners are suppressed
      if (updateControllers != null) {
        for (int i = 0; i < 12; i++) {
          updateControllers[i].text = cleanWords[i];
        }
      }

      await _validateComplete();
    } finally {
      _bulkUpdating = false;
    }
  }

  /// Clear all words
  void clearWords() {
    state = MnemonicInputState(words: List.filled(12, ''));
  }

  /// Get the final validated mnemonic result
  Future<MnemonicResult?> getValidatedMnemonic() async {
    if (!state.isValid) return null;
    return await MnemonicService.validateAndProcessMnemonic(state.mnemonicString);
  }
}

/// Provider for mnemonic input state
final mnemonicInputProvider = NotifierProvider<MnemonicInputNotifier, MnemonicInputState>(MnemonicInputNotifier.new);

/// Text controllers for mnemonic input fields (12 controllers)
final mnemonicControllersProvider = Provider<List<TextEditingController>>((ref) {
  final controllers = List.generate(12, (index) => TextEditingController());

  // Listen to changes and update the mnemonic input provider
  for (int i = 0; i < controllers.length; i++) {
    final index = i; // Capture the index
    controllers[i].addListener(() {
      ref.read(mnemonicInputProvider.notifier).updateWord(index, controllers[index].text);
    });
  }

  // Cleanup when provider is disposed
  ref.onDispose(() {
    for (final controller in controllers) {
      controller.dispose();
    }
  });

  return controllers;
});

/// Provider for checking if words can be pasted from clipboard
final canPasteMnemonicProvider = FutureProvider<bool>((ref) async {
  try {
    final words = await MnemonicService.parseClipboardMnemonic();
    return words.length == 12;
  } catch (e) {
    return false;
  }
});

/// Function to paste mnemonic from clipboard
final pasteMnemonicProvider = Provider<Future<bool> Function()>((ref) {
  return () async {
    try {
      final words = await MnemonicService.parseClipboardMnemonic();
      if (words.length == 12) {
        final controllers = ref.read(mnemonicControllersProvider);
        await ref.read(mnemonicInputProvider.notifier).fillWords(words, updateControllers: controllers);
        return ref.read(mnemonicInputProvider).isValid;
      }
      return false;
    } catch (e) {
      log.e('Error pasting mnemonic: $e');
      return false;
    }
  };
});

/// Provider for word validation challenge (asking user for a specific word)
class WordValidationChallenge {
  final int wordIndex;
  final String expectedWord;
  final String wordPosition;

  const WordValidationChallenge({required this.wordIndex, required this.expectedWord, required this.wordPosition});
}

/// Provider for generating word validation challenge
final wordValidationChallengeProvider = Provider<WordValidationChallenge?>((ref) {
  final mnemonicState = ref.watch(mnemonicStateProvider);

  if (!mnemonicState.hasMnemonic) {
    return null;
  }

  final words = mnemonicState.displayWords;
  final randomIndex = Random().nextInt(12);

  return WordValidationChallenge(
    wordIndex: randomIndex,
    expectedWord: words[randomIndex],
    wordPosition: MnemonicService.getOrdinalString(randomIndex + 1, Gecko.navigatorContext!),
  );
});

/// State for word validation challenge
class WordChallengeState {
  final bool isValid;
  final Color? inputColor;
  final String userInput;

  const WordChallengeState({this.isValid = false, this.inputColor, this.userInput = ''});

  WordChallengeState copyWith({bool? isValid, Color? inputColor, String? userInput}) {
    return WordChallengeState(
      isValid: isValid ?? this.isValid,
      inputColor: inputColor,
      userInput: userInput ?? this.userInput,
    );
  }
}

/// Notifier for word validation challenge
class WordChallengeNotifier extends Notifier<WordChallengeState> {
  @override
  WordChallengeState build() {
    return const WordChallengeState();
  }

  void checkWord(String input, String expectedWord) {
    final normalizedInput = input.trim().toLowerCase();
    final normalizedExpected = expectedWord.trim().toLowerCase();

    // Allow debug cheat code
    final isValid = normalizedInput == normalizedExpected || (kDebugMode && input == 'triche');

    state = state.copyWith(userInput: input, isValid: isValid);
  }

  void reset() {
    state = const WordChallengeState();
  }
}

/// Provider for word validation challenge state
final wordChallengeProvider = NotifierProvider<WordChallengeNotifier, WordChallengeState>(WordChallengeNotifier.new);

/// Provider for clearing mnemonic input
final clearMnemonicInputProvider = Provider<VoidCallback>((ref) {
  return () {
    final controllers = ref.read(mnemonicControllersProvider);
    for (final controller in controllers) {
      controller.clear();
    }
    ref.read(mnemonicInputProvider.notifier).clearWords();
  };
});

/// Provider for resetting all mnemonic state
final resetMnemonicStateProvider = Provider<VoidCallback>((ref) {
  return () {
    ref.read(mnemonicStateProvider.notifier).clearMnemonic();
    ref.read(clearMnemonicInputProvider)();
    ref.read(wordChallengeProvider.notifier).reset();
  };
});
