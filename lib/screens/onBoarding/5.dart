// ignore_for_file: file_names

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/providers/my_wallets.dart';
import 'package:gecko/providers/wallets_profiles.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/build_progress_bar.dart';
import 'package:gecko/widgets/commons/build_text.dart';
import 'package:gecko/widgets/commons/mnemonic_display.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart';

class OnboardingStepFive extends StatefulWidget {
  const OnboardingStepFive({super.key, this.skipIntro = false});
  final bool skipIntro;

  @override
  State<StatefulWidget> createState() {
    return _ChooseSafeState();
  }
}

// ignore: unused_element
class _ChooseSafeState extends State<OnboardingStepFive> {
  List<String>? mnemonicList;
  bool isLoading = false;
  bool _hasInitialized = false;
  final generateWalletProvider = Provider.of<GenerateWalletsProvider>(homeContext, listen: false);
  bool get isMnemonicGenerated => generateWalletProvider.generatedMnemonic != null;

  @override
  void initState() {
    super.initState();
    // Don't call _generateMnemonicList() here as context.locale is not available yet
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call _generateMnemonicList() here when context is fully available
    if (!_hasInitialized) {
      _hasInitialized = true;
      _generateMnemonicList();
    }
  }

  Future<void> _generateMnemonicList() async {
    final list = await generateWalletProvider.generateWordList(context);
    if (mounted) {
      setState(() {
        mnemonicList = list?.cast<String>();
        isLoading = false;
      });
    }
  }

  Future<void> _regenerateMnemonic() async {
    setState(() {
      isLoading = true;
    });
    await _generateMnemonicList();
  }

  Widget sentenceArray() {
    if (mnemonicList == null) {
      return Center(child: CircularProgressIndicator(color: context.colorScheme.primary, strokeWidth: 2));
    }

    return MnemonicDisplayWidget(
      mnemonicWords: mnemonicList!,
      isLoading: isLoading,
      useWordAsKey: false, // Use index as key for onboarding
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: GeckoAppBar('yourMnemonic'.tr()),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  ScaledSizedBox(height: isTall ? 25 : 5),
                  const BuildProgressBar(pagePosition: 4),
                  ScaledSizedBox(height: isTall ? 25 : 5),
                  BuildText(text: 'geckoGeneratedYourMnemonicKeepItSecret'.tr()),
                  ScaledSizedBox(height: isTall ? 15 : 5),
                  sentenceArray(),
                  ScaledSizedBox(height: isTall ? 17 : 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ScaledSizedBox(
                        height: 40,
                        width: 132,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            backgroundColor: context.colorScheme.primary,
                            elevation: 1,
                          ),
                          onPressed: isMnemonicGenerated
                              ? () {
                                  Clipboard.setData(ClipboardData(text: generateWalletProvider.generatedMnemonic!));
                                  snackCopySeed(context);
                                }
                              : null,
                          child: Row(
                            children: <Widget>[
                              Image.asset('assets/walletOptions/copy-white.png', height: scaleSize(23)),
                              const Spacer(),
                              Text('copy'.tr(), style: scaledTextStyle(fontSize: 14, color: Colors.grey[50])),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ),
                      ScaledSizedBox(width: 70),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            RouteNames.printWallet,
                            arguments: PrintWalletArguments(sentence: generateWalletProvider.generatedMnemonic!),
                          );
                        },
                        child: Image.asset(
                          'assets/printer.png',
                          height: scaleSize(42),
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  ScaledSizedBox(height: isTall ? 17 : 5),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: scaleSize(18)),
                    child: ScaledSizedBox(
                      width: 350,
                      height: 55,
                      child: ElevatedButton(
                        key: keyGenerateMnemonic,
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: const Color(0xffFFD58D),
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          shadowColor: const Color(0xffFFD58D).withValues(alpha: 0.3),
                        ),
                        onPressed: () {
                          _regenerateMnemonic();
                        },
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            "chooseAnotherMnemonic".tr(),
                            textAlign: TextAlign.center,
                            style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                  ),
                  nextButton(context, "iNotedMyMnemonic".tr(), false, widget.skipIntro),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget nextButton(BuildContext context, String text, bool isFast, bool skipIntro) {
    final myWalletProvider = Provider.of<MyWalletsProvider>(context, listen: false);
    return ScaledSizedBox(
      width: 350,
      height: 55,
      child: ElevatedButton(
        key: keyGoNext,
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: context.colorScheme.primary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadowColor: context.colorScheme.primary.withValues(alpha: 0.3),
        ),
        onPressed: isMnemonicGenerated
            ? () {
                generateWalletProvider.nbrWord = generateWalletProvider.getRandomInt();
                generateWalletProvider.nbrWordAlpha = generateWalletProvider.intToString(
                  generateWalletProvider.nbrWord + 1,
                );
                myWalletProvider.mnemonic = generateWalletProvider.generatedMnemonic!;

                AppNavigator.pushWithFader(
                  context,
                  RouteNames.onboardingStepSix,
                  arguments: OnboardingStepSixArguments(
                    generatedMnemonic: generateWalletProvider.generatedMnemonic,
                    skipIntro: skipIntro,
                  ),
                );
              }
            : null,
        child: Text(
          text,
          style: scaledTextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        ),
      ),
    );
  }
}
