import 'dart:math';
import 'package:durt2/durt2.dart' show BidouilleLang;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';

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

/// StateNotifier for managing mnemonic generation and validation
class MnemonicStateNotifier extends StateNotifier<MnemonicState> {
  MnemonicStateNotifier() : super(const MnemonicState());

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
final mnemonicStateProvider = StateNotifierProvider<MnemonicStateNotifier, MnemonicState>((ref) {
  return MnemonicStateNotifier();
});

/// State for mnemonic word input validation
class MnemonicInputState {
  final List<String> words;
  final bool isValid;
  final bool isComplete;
  final Map<int, bool> wordValidations;

  const MnemonicInputState({
    this.words = const [],
    this.isValid = false,
    this.isComplete = false,
    this.wordValidations = const {},
  });

  MnemonicInputState copyWith({List<String>? words, bool? isValid, bool? isComplete, Map<int, bool>? wordValidations}) {
    return MnemonicInputState(
      words: words ?? this.words,
      isValid: isValid ?? this.isValid,
      isComplete: isComplete ?? this.isComplete,
      wordValidations: wordValidations ?? this.wordValidations,
    );
  }

  String get mnemonicString => words.join(' ');
  bool get hasAllWords => words.length == 12 && words.every((w) => w.isNotEmpty);
}

/// StateNotifier for managing mnemonic input validation
class MnemonicInputNotifier extends StateNotifier<MnemonicInputState> {
  MnemonicInputNotifier() : super(MnemonicInputState(words: List.filled(12, '')));

  /// Update a specific word and validate it
  Future<void> updateWord(int index, String word) async {
    if (index < 0 || index >= 12) return;

    final newWords = List<String>.from(state.words);
    newWords[index] = word.trim().toLowerCase();

    // Validate the individual word
    final isWordValid = word.trim().isEmpty || await MnemonicService.isValidBip39Word(word.trim());
    final newValidations = Map<int, bool>.from(state.wordValidations);
    newValidations[index] = isWordValid;

    state = state.copyWith(words: newWords, wordValidations: newValidations);

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

  /// Fill words from a list (e.g., from clipboard or OCR)
  Future<void> fillWords(List<String> words) async {
    if (words.length != 12) return;

    final cleanWords = words.map((w) => w.trim().toLowerCase()).toList();
    final validations = <int, bool>{};

    // Validate each word
    for (int i = 0; i < cleanWords.length; i++) {
      validations[i] = await MnemonicService.isValidBip39Word(cleanWords[i]);
    }

    state = state.copyWith(words: cleanWords, wordValidations: validations);

    await _validateComplete();
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
final mnemonicInputProvider = StateNotifierProvider<MnemonicInputNotifier, MnemonicInputState>((ref) {
  return MnemonicInputNotifier();
});

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
        for (int i = 0; i < 12; i++) {
          controllers[i].text = words[i];
        }
        await ref.read(mnemonicInputProvider.notifier).fillWords(words);
        return true;
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
    wordPosition: MnemonicService.getOrdinalString(randomIndex + 1, homeContext),
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

/// StateNotifier for word validation challenge
class WordChallengeNotifier extends StateNotifier<WordChallengeState> {
  WordChallengeNotifier() : super(const WordChallengeState());

  void checkWord(String input, String expectedWord) {
    final normalizedInput = input.trim().toLowerCase();
    final normalizedExpected = expectedWord.trim().toLowerCase();

    // Allow debug cheat code
    final isValid = normalizedInput == normalizedExpected || (kDebugMode && input == 'triche');

    state = state.copyWith(userInput: input, isValid: isValid, inputColor: isValid ? Colors.green[600] : null);
  }

  void reset() {
    state = const WordChallengeState();
  }
}

/// Provider for word validation challenge state
final wordChallengeProvider = StateNotifierProvider<WordChallengeNotifier, WordChallengeState>((ref) {
  return WordChallengeNotifier();
});

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
