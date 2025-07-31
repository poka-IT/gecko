// ignore_for_file: file_names
// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class OnboardingStepSixMigrated extends ConsumerStatefulWidget {
  const OnboardingStepSixMigrated({super.key, required this.skipIntro, required this.generatedMnemonic});

  final bool skipIntro;
  final String? generatedMnemonic;

  @override
  ConsumerState<OnboardingStepSixMigrated> createState() => _OnboardingStepSixMigratedState();
}

class _OnboardingStepSixMigratedState extends ConsumerState<OnboardingStepSixMigrated> {
  final wordController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    // Set the mnemonic in the provider on init
    if (widget.generatedMnemonic != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Process the mnemonic and set it in the provider
        MnemonicService.validateAndProcessMnemonic(widget.generatedMnemonic!).then((result) {
          if (result != null) {
            ref.read(mnemonicStateProvider.notifier).setMnemonic(widget.generatedMnemonic!);
          }
        });

        // Force focus after build
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    wordController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wordChallenge = ref.watch(wordValidationChallengeProvider);
    final challengeState = ref.watch(wordChallengeProvider);

    // If no challenge is available yet, show loading
    if (wordChallenge == null) {
      return Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('yourMnemonic'.tr()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        // Reset challenge state on back navigation
        ref.read(wordChallengeProvider.notifier).reset();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('yourMnemonic'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Align(
              alignment: Alignment.topCenter,
              child: Column(
                children: [
                  ScaledSizedBox(height: isTall ? 25 : 5),
                  const BuildProgressBar(pagePosition: 5),
                  ScaledSizedBox(height: isTall ? 25 : 5),
                  BuildText(
                    text: "didYouNoteMnemonicToBeSureTypeWord".tr(args: [(wordChallenge.wordIndex + 1).toString()]),
                    isMd: true,
                  ),
                  ScaledSizedBox(height: isTall ? 40 : 5),
                  if (isTall)
                    Text(
                      '${wordChallenge.wordIndex + 1}',
                      key: keyAskedWord,
                      style: scaledTextStyle(
                        fontSize: 19,
                        color: context.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (isTall) ScaledSizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: Colors.grey[600]!, width: scaleSize(3)),
                    ),
                    width: scaleSize(340),
                    child: TextFormField(
                      key: keyInputWord,
                      autofocus: true,
                      focusNode: _focusNode,
                      enabled: !challengeState.isValid,
                      controller: wordController,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        ref.read(wordChallengeProvider.notifier).checkWord(value, wordChallenge.expectedWord);
                      },
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelStyle: scaledTextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        labelText: challengeState.isValid
                            ? "itsTheGoodWord".tr()
                            : "${wordChallenge.wordPosition} ${"nthMnemonicWord".tr()}",
                        fillColor: const Color(0xffeeeedd),
                        filled: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      style: scaledTextStyle(
                        fontSize: 25,
                        color: challengeState.inputColor ?? Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: challengeState.isValid,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                      child: nextButton(
                        context: context,
                        text: 'continue'.tr(),
                        nextScreen: widget.skipIntro ? RouteNames.onboardingStepNine : RouteNames.onboardingStepSeven,
                        isFast: false,
                        arguments: OnboardingStepsSevenToNineArguments(scanDerivation: false, fromRestore: false),
                      ),
                    ),
                  ),
                  ScaledSizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Widget nextButton({
  required BuildContext context,
  required String text,
  required String nextScreen,
  required bool isFast,
  required OnboardingStepsSevenToNineArguments? arguments,
}) {
  return ScaledSizedBox(
    width: 340,
    height: 55,
    child: ElevatedButton(
      key: keyGoNext,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: context.colorScheme.primary,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
      ),
      onPressed: () {
        // With Riverpod, we can use Consumer/ref to reset state if needed
        // But in this case, we'll let the next screen handle state as needed
        AppNavigator.pushWithFader(context, nextScreen, arguments: arguments, isFast: isFast);
      },
      child: Text(
        text,
        style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
