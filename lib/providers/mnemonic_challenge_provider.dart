import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/providers/providers.dart';
import 'package:gecko/services/pin_cache_service.dart';
import 'package:gecko/services/sentry_service.dart';

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

  /// Initialize the challenge by loading the mnemonic and selecting 2 random word indices.
  /// [pinCode] can be passed explicitly to avoid reading from PinCodeService which may
  /// have been cleared by debounceResetPinCode when PIN cache is disabled.
  Future<void> initialize(String address, {String? pinCode}) async {
    state = const MnemonicChallengeState(isLoading: true);

    try {
      final pin = pinCode ?? PinCodeService.pinCode;
      if (pin.isEmpty) {
        const errorDetail = 'PIN code is empty when initializing mnemonic challenge';
        log.e(errorDetail);
        SentryService.captureException(Exception(errorDetail), tag: 'mnemonic_challenge', extra: {'address': address});
        state = state.copyWith(isLoading: false, error: errorDetail);
        return;
      }

      // Call wallet service directly instead of using autoDispose seedDisplayProvider,
      // which gets disposed before the future resolves when used with ref.read()
      final walletService = ref.read(walletServiceProvider);
      final englishMnemonic = await walletService.getSeed(address: address, pin: pin);

      if (englishMnemonic.isEmpty) {
        final errorDetail = 'getSeed returned empty mnemonic for address $address';
        log.e(errorDetail);
        SentryService.captureException(Exception(errorDetail), tag: 'mnemonic_challenge', extra: {'address': address});
        state = state.copyWith(isLoading: false, error: errorDetail);
        return;
      }

      // Convert to display language
      final allSafes = walletService.safeBox.getAll();
      final wallet = allSafes.expand((safe) => safe.wallets).where((w) => w.address == address).firstOrNull;
      final safeBoxNumber = wallet?.safe.target?.number;

      String displayMnemonic;
      try {
        displayMnemonic = await walletService.convertEnglishToSafeLanguage(englishMnemonic, safeBoxNumber);
      } catch (e) {
        displayMnemonic = englishMnemonic;
      }

      final words = displayMnemonic.split(' ');

      if (words.length != 12) {
        final errorDetail =
            'Mnemonic has ${words.length} words instead of 12 for address $address. '
            'displayMnemonic starts with: "${displayMnemonic.substring(0, (displayMnemonic.length > 30 ? 30 : displayMnemonic.length))}..."';
        log.e(errorDetail);
        SentryService.captureException(
          Exception(errorDetail),
          tag: 'mnemonic_challenge',
          extra: {'address': address, 'wordCount': words.length.toString()},
        );
        state = state.copyWith(isLoading: false, error: errorDetail);
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
    } catch (e, stackTrace) {
      final errorDetail = 'Mnemonic challenge initialization failed for address $address: $e';
      log.e(errorDetail);
      SentryService.captureException(e, stackTrace: stackTrace, tag: 'mnemonic_challenge', extra: {'address': address});
      state = state.copyWith(isLoading: false, error: errorDetail);
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
