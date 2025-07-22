// ignore_for_file: use_build_context_synchronously

import 'package:bubble/bubble.dart';
import 'package:durt2/durt2.dart' show Durt, BidouilleLang;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/generate_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:provider/provider.dart' as old_provider;

class RestoreSafe extends ConsumerWidget {
  const RestoreSafe({super.key, this.skipIntro = false});
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genW = old_provider.Provider.of<GenerateWalletsProvider>(context, listen: true);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        genW.resetImportView();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('restoreASafe'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ScaledSizedBox(height: isTall ? 20 : 3),
                bubbleSpeak('toRestoreEnterMnemonic'.tr()),
                ScaledSizedBox(height: isTall ? 20 : 5),
                Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        arrayCell(context, genW.cellController0),
                        arrayCell(context, genW.cellController1),
                        arrayCell(context, genW.cellController2),
                        arrayCell(context, genW.cellController3),
                      ],
                    ),
                    ScaledSizedBox(height: isTall ? 10 : 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        arrayCell(context, genW.cellController4),
                        arrayCell(context, genW.cellController5),
                        arrayCell(context, genW.cellController6),
                        arrayCell(context, genW.cellController7),
                      ],
                    ),
                    ScaledSizedBox(height: isTall ? 10 : 3),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        arrayCell(context, genW.cellController8),
                        arrayCell(context, genW.cellController9),
                        arrayCell(context, genW.cellController10),
                        arrayCell(context, genW.cellController11),
                      ],
                    ),
                  ],
                ),
                FutureBuilder(
                  future: genW.isSentenceComplete(),
                  builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
                    if (snapshot.hasData) {
                      if (snapshot.data!) {
                        return Container(
                          padding: EdgeInsets.symmetric(vertical: scaleSize(20)),
                          child: Align(
                            alignment: Alignment.center,
                            child: ScaledSizedBox(
                              width: 340,
                              height: 55,
                              child: ElevatedButton(
                                key: keyGoNext,
                                style:
                                    ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: context.colorScheme.primary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(12)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ).copyWith(
                                      elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.pressed)) return 0;
                                        return 8;
                                      }),
                                      shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                    ),
                                onPressed: () async {
                                  // The provider already handles validation and conversion automatically
                                  if (await genW.isSentenceComplete()) {
                                    try {
                                      // DON'T overwrite generatedMnemonic - it already contains the user's original input
                                      // The English conversion will be handled automatically by createSafe in Durt2
                                      genW.resetImportView();
                                      await AppNavigator.pushWithFader(
                                        context,
                                        skipIntro ? RouteNames.onboardingStepNine : RouteNames.onboardingStepSeven,
                                        arguments: OnboardingStepsSevenToNineArguments(
                                          scanDerivation: true,
                                          fromRestore: true,
                                        ),
                                        isFast: true,
                                      );
                                    } catch (e) {
                                      // Handle any errors from getting the English mnemonic
                                      await badMnemonicPopup(context);
                                    }
                                  } else {
                                    await badMnemonicPopup(context);
                                  }
                                },
                                child: Text(
                                  'restoreThisSafe'.tr(),
                                  style: scaledTextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            ScaledSizedBox(height: 20),
                            ScaledSizedBox(
                              width: 180,
                              child: ElevatedButton(
                                key: keyPastMnemonic,
                                style:
                                    ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: context.colorScheme.secondary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(8), horizontal: scaleSize(16)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ).copyWith(
                                      elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                        if (states.contains(WidgetState.pressed)) return 0;
                                        return 4;
                                      }),
                                      shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                                    ),
                                onPressed: () {
                                  genW.pasteMnemonic(context);
                                },
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Icon(
                                      Icons.content_paste_go,
                                      size: scaleSize(24),
                                      color: Colors.black.withValues(alpha: 0.7),
                                    ),
                                    Text(
                                      'pasteFromClipboard'.tr(),
                                      textAlign: TextAlign.center,
                                      style: scaledTextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget bubbleSpeak(String text) {
    return Bubble(
      margin: const BubbleEdges.symmetric(horizontal: 20),
      padding: BubbleEdges.all(scaleSize(15)),
      borderWidth: 1,
      borderColor: Colors.black,
      radius: Radius.zero,
      color: homeContext.colorScheme.surfaceContainer,
      child: Text(
        text,
        key: keyBubbleSpeak,
        textAlign: TextAlign.justify,
        style: scaledTextStyle(
          color: homeContext.colorScheme.onSecondaryContainer,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget arrayCell(BuildContext context, TextEditingController cellCtl) {
    final generateWalletProvider = old_provider.Provider.of<GenerateWalletsProvider>(context);

    return Container(
      width: scaleSize(87),
      height: scaleSize(37),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(3),
      ),
      child: TextField(
        autofocus: true,
        controller: cellCtl,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colorScheme.primary)),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (v) async {
          if (v.contains(' ')) {
            cellCtl.text = cellCtl.text.replaceAll(' ', '');
            FocusScope.of(context).nextFocus();
          }

          // Convert to lowercase for consistency
          if (v.isNotEmpty) cellCtl.text = cellCtl.text.toLowerCase();

          // Only move to next field if we have a valid BIP39 word AND we're not at the last field
          if (v.isNotEmpty && generateWalletProvider.cellController11.text.isEmpty) {
            // Check if the current word is a valid BIP39 word
            try {
              // Get user's preferred language from locale
              final languageCode = context.locale.languageCode;
              final preferredLanguage = BidouilleLang.fromLanguageCode(languageCode);

              final isValidWord = await Durt.i.wallets.multilangService.isValidWordInAnyLanguage(
                v,
                preferredLanguage: preferredLanguage,
              );
              if (isValidWord) {
                FocusScope.of(context).nextFocus();
              }
            } catch (e) {
              // If validation fails, don't move to next field
            }
          }

          // Trigger validation and UI update for real-time button visibility
          await generateWalletProvider.onMnemonicWordChanged();
        },
        textAlign: TextAlign.center,
        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSecondaryContainer),
      ),
    );
  }

  Future<bool?> badMnemonicPopup(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('incorrectPhrase'.tr()),
          content: Text('incorrectPhraseDescription'.tr()),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
