// ignore_for_file: file_names
// ignore_for_file: must_be_immutable

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/screens/onBoarding/7.dart';
import 'package:gecko/screens/onBoarding/9.dart';
import 'package:gecko/widgets/commons/fader_transition.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class OnboardingStepSix extends StatelessWidget {
  OnboardingStepSix({super.key, required this.skipIntro, required this.generatedMnemonic});

  final bool skipIntro;
  String? generatedMnemonic;
  final wordController = TextEditingController();
  final _mnemonicController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final generateWalletProvider = Provider.of<GenerateWalletsProvider>(context, listen: true);

    _mnemonicController.text = generatedMnemonic!;

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        generateWalletProvider.isAskedWordValid = false;
        generateWalletProvider.askedWordColor = Colors.black;
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
                    text: "didYouNoteMnemonicToBeSureTypeWord".tr(
                      args: [(generateWalletProvider.nbrWord + 1).toString()],
                    ),
                    isMd: true,
                  ),
                  ScaledSizedBox(height: isTall ? 40 : 5),
                  if (isTall)
                    Text(
                      '${generateWalletProvider.nbrWord + 1}',
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
                      enabled: !generateWalletProvider.isAskedWordValid,
                      controller: wordController,
                      textInputAction: TextInputAction.next,
                      onChanged: (value) {
                        generateWalletProvider.checkAskedWord(value, _mnemonicController.text);
                      },
                      maxLines: 1,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        labelStyle: scaledTextStyle(fontSize: 18, color: Colors.grey[500], fontWeight: FontWeight.w500),
                        labelText: generateWalletProvider.isAskedWordValid
                            ? "itsTheGoodWord".tr()
                            : "${generateWalletProvider.nbrWordAlpha} ${"nthMnemonicWord".tr()}",
                        fillColor: const Color(0xffeeeedd),
                        filled: true,
                        contentPadding: const EdgeInsets.all(10),
                      ),
                      style: scaledTextStyle(
                        fontSize: 25,
                        color: generateWalletProvider.askedWordColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Visibility(
                    visible: generateWalletProvider.isAskedWordValid,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                      child: nextButton(
                        context,
                        'continue'.tr(),
                        skipIntro ? const OnboardingStepNine() : const OnboardingStepSeven(),
                        false,
                      ),
                    ),
                  ),
                  // Visibility(
                  //   visible: !_generateWalletProvider.isAskedWordValid,
                  //   child: const Expanded(
                  //     child: Align(
                  //       alignment: Alignment.bottomCenter,
                  //       child: Text(''),
                  //     ),
                  //   ),
                  // ),
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

Widget nextButton(BuildContext context, String text, nextScreen, bool isFast) {
  final generateWalletProvider = Provider.of<GenerateWalletsProvider>(context, listen: false);

  generateWalletProvider.isAskedWordValid = false;
  generateWalletProvider.askedWordColor = Colors.black;

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
        Navigator.push(context, FaderTransition(page: nextScreen, isFast: isFast));
      },
      child: Text(
        text,
        style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
      ),
    ),
  );
}
