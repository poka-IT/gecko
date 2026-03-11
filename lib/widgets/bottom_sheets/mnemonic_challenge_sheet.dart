import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/mnemonic_challenge_provider.dart';

/// Shows a bottom sheet that asks the user to type 2 random words from their mnemonic.
/// Returns `true` if both words are validated, `false` otherwise.
/// [pinCode] can be passed explicitly to avoid race conditions with PIN cache clearing.
Future<bool> showMnemonicChallenge({
  required BuildContext context,
  required WidgetRef ref,
  required String address,
  String? pinCode,
}) async {
  // Initialize the challenge
  await ref.read(mnemonicChallengeProvider.notifier).initialize(address, pinCode: pinCode);

  final challengeState = ref.read(mnemonicChallengeProvider);
  if (challengeState.error != null) {
    log.e('Mnemonic challenge failed for address $address: ${challengeState.error}');
    if (context.mounted) {
      final snackMessage = kDebugMode ? '${challengeState.error}' : 'mnemonicVerificationFailed'.tr();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(snackMessage), duration: const Duration(seconds: 6)));
    }
    ref.read(mnemonicChallengeProvider.notifier).reset();
    return false;
  }

  if (!context.mounted) return false;

  final result = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    useSafeArea: true,
    constraints: const BoxConstraints(maxWidth: 600),
    builder: (BuildContext sheetContext) {
      return _MnemonicChallengeSheet(address: address);
    },
  );

  ref.read(mnemonicChallengeProvider.notifier).reset();
  return result ?? false;
}

class _MnemonicChallengeSheet extends ConsumerStatefulWidget {
  final String address;

  const _MnemonicChallengeSheet({required this.address});

  @override
  ConsumerState<_MnemonicChallengeSheet> createState() => _MnemonicChallengeSheetState();
}

class _MnemonicChallengeSheetState extends ConsumerState<_MnemonicChallengeSheet> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isAdvancing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged(String value) {
    final state = ref.read(mnemonicChallengeProvider);
    final activeIndex = state.activeIndex;
    final isValid = ref.read(mnemonicChallengeProvider.notifier).checkWord(activeIndex, value);

    if (isValid) {
      _autoAdvance();
    }
  }

  void _onSubmit() {
    final state = ref.read(mnemonicChallengeProvider);
    final activeIndex = state.activeIndex;
    final isValid = ref.read(mnemonicChallengeProvider.notifier).submitWord(activeIndex);

    if (isValid) {
      _autoAdvance();
    }
  }

  void _autoAdvance() {
    if (_isAdvancing) return;
    _isAdvancing = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      _isAdvancing = false;
      if (!mounted) return;
      final currentState = ref.read(mnemonicChallengeProvider);
      if (currentState.isComplete) return;

      // Clear input then advance — the TextField stays in the tree so focus is preserved
      _controller.clear();
      ref.read(mnemonicChallengeProvider.notifier).advanceToNext();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mnemonicChallengeProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    if (!state.isInitialized) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 16, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'mnemonicVerification'.tr(),
                      style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    key: keyMnemonicChallengeClose,
                    onPressed: () => Navigator.pop(context, false),
                    icon: Icon(Icons.close, color: context.colorScheme.onSurface.withValues(alpha: 0.6)),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
              child: Text(
                'enterTwoWordsToConfirm'.tr(),
                style: scaledTextStyle(fontSize: 14, color: context.colorScheme.onSurface.withValues(alpha: 0.7)),
              ),
            ),
            SizedBox(height: scaleSize(20)),
            // Word position chips
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WordPositionChip(
                  wordNumber: state.challenges[0].wordNumber,
                  chipState: state.challenges[0].isValidated
                      ? _ChipState.validated
                      : state.activeIndex == 0
                      ? _ChipState.active
                      : _ChipState.pending,
                ),
                SizedBox(width: scaleSize(16)),
                _WordPositionChip(
                  wordNumber: state.challenges[1].wordNumber,
                  chipState: state.challenges[1].isValidated
                      ? _ChipState.validated
                      : state.activeIndex == 1
                      ? _ChipState.active
                      : _ChipState.pending,
                ),
              ],
            ),
            SizedBox(height: scaleSize(20)),
            // Word input area — TextField stays in tree to preserve keyboard focus
            _buildWordInput(context, state),
            SizedBox(height: scaleSize(16)),
            // Confirm button
            Padding(
              padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: keyMnemonicChallengeConfirm,
                  onPressed: state.isComplete ? () => Navigator.pop(context, true) : null,
                  child: Text('confirm'.tr()),
                ),
              ),
            ),
            SizedBox(height: 24 + bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildWordInput(BuildContext context, MnemonicChallengeState state) {
    final challenge = state.challenges[state.activeIndex];
    final isCurrentValidated = challenge.isValidated;
    final hasError = challenge.hasError;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: scaleSize(20)),
      child: Column(
        children: [
          // Only the label is animated — the TextField below never leaves the tree
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              key: ValueKey('label_${state.activeIndex}'),
              'typeWordNumber'.tr(args: ['${challenge.wordNumber}']),
              style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(height: scaleSize(12)),
          TextField(
            key: keyMnemonicChallengeInput,
            controller: _controller,
            focusNode: _focusNode,
            textAlign: TextAlign.center,
            autocorrect: false,
            enableSuggestions: false,
            onChanged: _onTextChanged,
            onSubmitted: (_) => _onSubmit(),
            style: scaledTextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: isCurrentValidated
                  ? Colors.green[600]
                  : hasError
                  ? Colors.red[600]
                  : null,
            ),
            decoration: InputDecoration(
              hintText: 'wordNofMnemonic'.tr(),
              hintStyle: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSurface.withValues(alpha: 0.4)),
              filled: true,
              fillColor: context.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: hasError ? BorderSide(color: Colors.red[600]!, width: 1.5) : BorderSide.none,
              ),
              enabledBorder: hasError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[600]!, width: 1.5),
                    )
                  : OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: hasError
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.red[600]!, width: 1.5),
                    )
                  : null,
              suffixIcon: isCurrentValidated
                  ? TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      builder: (context, value, child) {
                        return Opacity(opacity: value, child: child);
                      },
                      child: Icon(Icons.check_circle, color: Colors.green[600]),
                    )
                  : hasError
                  ? Icon(Icons.error_outline, color: Colors.red[600])
                  : null,
            ),
          ),
          SizedBox(height: scaleSize(8)),
          // Feedback message: correct or incorrect
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isCurrentValidated
                ? Text(
                    key: const ValueKey('correct'),
                    'correctWord'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Colors.green[600], fontWeight: FontWeight.w500),
                  )
                : hasError
                ? Text(
                    key: const ValueKey('error'),
                    'incorrectWord'.tr(),
                    style: scaledTextStyle(fontSize: 14, color: Colors.red[600], fontWeight: FontWeight.w500),
                  )
                : const SizedBox.shrink(key: ValueKey('empty')),
          ),
          // Check button — visible when not yet validated and user has typed something
          if (!isCurrentValidated) ...[
            SizedBox(height: scaleSize(12)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: challenge.userInput.trim().isNotEmpty ? _onSubmit : null,
                child: Text('checkWord'.tr()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

enum _ChipState { pending, active, validated }

class _WordPositionChip extends StatelessWidget {
  final int wordNumber;
  final _ChipState chipState;

  const _WordPositionChip({required this.wordNumber, required this.chipState});

  @override
  Widget build(BuildContext context) {
    final isValidated = chipState == _ChipState.validated;
    final isActive = chipState == _ChipState.active;

    final bgColor = isValidated
        ? Colors.green[600]!
        : isActive
        ? context.colorScheme.primary
        : context.colorScheme.surfaceContainerHighest;

    final fgColor = isValidated || isActive ? Colors.white : context.colorScheme.onSurface.withValues(alpha: 0.5);

    return AnimatedContainer(
      key: keyMnemonicChallengeChip(wordNumber),
      duration: const Duration(milliseconds: 300),
      width: scaleSize(48),
      height: scaleSize(48),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: isActive
            ? [BoxShadow(color: context.colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
            : null,
      ),
      child: Center(
        child: isValidated
            ? Icon(Icons.check, color: fgColor, size: scaleSize(24))
            : Text(
                '#$wordNumber',
                style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: fgColor),
              ),
      ),
    );
  }
}
