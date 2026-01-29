import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/providers/security_providers.dart';
import 'package:gecko/services/pin_cache_service.dart';

/// Data for a single word challenge
class MnemonicChallengeWord {
  final int wordIndex;
  final String expectedWord;
  final String userInput;
  final bool isValidated;

  const MnemonicChallengeWord({
    required this.wordIndex,
    required this.expectedWord,
    this.userInput = '',
    this.isValidated = false,
  });

  MnemonicChallengeWord copyWith({String? userInput, bool? isValidated}) {
    return MnemonicChallengeWord(
      wordIndex: wordIndex,
      expectedWord: expectedWord,
      userInput: userInput ?? this.userInput,
      isValidated: isValidated ?? this.isValidated,
    );
  }

  /// 1-based word number for display
  int get wordNumber => wordIndex + 1;
}

/// State for the 2-word mnemonic challenge
class MnemonicChallengeState {
  final List<MnemonicChallengeWord> challenges;
  final int activeIndex;
  final bool isLoading;
  final String? error;

  const MnemonicChallengeState({this.challenges = const [], this.activeIndex = 0, this.isLoading = false, this.error});

  MnemonicChallengeState copyWith({
    List<MnemonicChallengeWord>? challenges,
    int? activeIndex,
    bool? isLoading,
    String? error,
  }) {
    return MnemonicChallengeState(
      challenges: challenges ?? this.challenges,
      activeIndex: activeIndex ?? this.activeIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get isComplete => challenges.length == 2 && challenges.every((c) => c.isValidated);
  bool get isInitialized => challenges.length == 2;
}

/// Notifier for the mnemonic challenge
class MnemonicChallengeNotifier extends Notifier<MnemonicChallengeState> {
  @override
  MnemonicChallengeState build() {
    return const MnemonicChallengeState();
  }

  /// Initialize the challenge by loading the mnemonic and selecting 2 random word indices
  Future<void> initialize(String address) async {
    state = const MnemonicChallengeState(isLoading: true);

    try {
      final pin = PinCodeService.pinCode;
      final seedData = await ref.read(seedDisplayProvider((address: address, pin: pin)).future);
      final words = seedData.displayMnemonic.split(' ');

      if (words.length != 12) {
        state = state.copyWith(isLoading: false, error: 'mnemonicVerificationFailed');
        return;
      }

      // Select 2 distinct random indices
      final random = Random();
      final first = random.nextInt(12);
      int second = random.nextInt(11);
      if (second >= first) second++;

      final challenges = [
        MnemonicChallengeWord(wordIndex: first, expectedWord: words[first]),
        MnemonicChallengeWord(wordIndex: second, expectedWord: words[second]),
      ];

      state = MnemonicChallengeState(challenges: challenges, activeIndex: 0);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'mnemonicVerificationFailed');
    }
  }

  /// Check a word input against the expected word.
  /// Only validates the challenge, does NOT advance activeIndex.
  bool checkWord(int challengeIndex, String input) {
    if (challengeIndex < 0 || challengeIndex >= state.challenges.length) return false;

    final challenge = state.challenges[challengeIndex];
    final normalizedInput = input.trim().toLowerCase();
    final normalizedExpected = challenge.expectedWord.trim().toLowerCase();

    final isValid = normalizedInput == normalizedExpected || (kDebugMode && normalizedInput == 'triche');

    final updatedChallenges = List<MnemonicChallengeWord>.from(state.challenges);
    updatedChallenges[challengeIndex] = challenge.copyWith(userInput: input, isValidated: isValid);

    state = state.copyWith(challenges: updatedChallenges);
    return isValid;
  }

  /// Advance to the next challenge word
  void advanceToNext() {
    if (state.activeIndex < state.challenges.length - 1) {
      state = state.copyWith(activeIndex: state.activeIndex + 1);
    }
  }

  /// Reset the challenge state
  void reset() {
    state = const MnemonicChallengeState();
  }
}

/// Provider for the mnemonic challenge
final mnemonicChallengeProvider = NotifierProvider<MnemonicChallengeNotifier, MnemonicChallengeState>(
  MnemonicChallengeNotifier.new,
);
