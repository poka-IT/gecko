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
import 'package:gecko/providers_deprecated/generate_wallets.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
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
                // Flexible layout that adapts to screen size and text scaling
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScaler = MediaQuery.textScalerOf(context);
                    final isTextScaled = textScaler.scale(1.0) > 1.3;

                    // Calculate optimal cell size based on available space
                    final horizontalPadding = scaleSize(32); // Total horizontal padding
                    final availableWidth = constraints.maxWidth - horizontalPadding;
                    final spacing = scaleSize(8);

                    // Determine cells per row based on text scaling and available space
                    int cellsPerRow;
                    if (isTextScaled) {
                      cellsPerRow = 3;
                    } else if (availableWidth < scaleSize(300)) {
                      cellsPerRow = 2; // Very small screens
                    } else {
                      cellsPerRow = 4; // Default
                    }

                    // Calculate cell width to use available space efficiently
                    final cellWidth = (availableWidth - (spacing * (cellsPerRow - 1))) / cellsPerRow;
                    final cellHeight = scaleSize(44);

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: scaleSize(isTall ? 10 : 6),
                        alignment: WrapAlignment.center,
                        children:
                            [
                                  genW.cellController0,
                                  genW.cellController1,
                                  genW.cellController2,
                                  genW.cellController3,
                                  genW.cellController4,
                                  genW.cellController5,
                                  genW.cellController6,
                                  genW.cellController7,
                                  genW.cellController8,
                                  genW.cellController9,
                                  genW.cellController10,
                                  genW.cellController11,
                                ]
                                .map(
                                  (controller) =>
                                      arrayCell(context, controller, cellWidth: cellWidth, cellHeight: cellHeight),
                                )
                                .toList(),
                      ),
                    );
                  },
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
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                              child: ElevatedButton(
                                key: keyGoNext,
                                style:
                                    ElevatedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      backgroundColor: context.colorScheme.primary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(16), horizontal: scaleSize(24)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      minimumSize: Size(
                                        scaleSize(280),
                                        scaleSize(56),
                                      ), // Minimum size for accessibility
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
                                    height: 1.3, // Better line height for accessibility
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2, // Allow text to wrap if needed
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                        );
                      } else {
                        return Column(
                          children: [
                            ScaledSizedBox(height: 20),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                              child: ElevatedButton(
                                key: keyPastMnemonic,
                                style:
                                    ElevatedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: context.colorScheme.secondary,
                                      elevation: 0,
                                      padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(20)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      minimumSize: Size(
                                        scaleSize(180),
                                        scaleSize(48),
                                      ), // Minimum size for accessibility
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
                                  mainAxisSize: MainAxisSize.min, // Allow button to shrink/grow with content
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.content_paste_go,
                                      size: scaleSize(20),
                                      color: Colors.black.withValues(alpha: 0.7),
                                    ),
                                    SizedBox(width: scaleSize(8)), // Fixed spacing instead of spaceAround
                                    Flexible(
                                      // Allow text to wrap if needed
                                      child: Text(
                                        'pasteFromClipboard'.tr(),
                                        textAlign: TextAlign.center,
                                        style: scaledTextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500, // Slightly bolder for better readability
                                          height: 1.3, // Better line height for accessibility
                                        ),
                                        maxLines: 2, // Allow text to wrap on 2 lines if needed
                                        overflow: TextOverflow.ellipsis,
                                      ),
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

  Widget arrayCell(
    BuildContext context,
    TextEditingController cellCtl, {
    required double cellWidth,
    required double cellHeight,
  }) {
    final generateWalletProvider = old_provider.Provider.of<GenerateWalletsProvider>(context);

    return Container(
      width: cellWidth,
      height: cellHeight,
      constraints: BoxConstraints(minWidth: cellWidth, minHeight: cellHeight),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey[400]!, // Better contrast
          width: 1.5, // Slightly thicker border for better visibility
        ),
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6), // Slightly more rounded for modern look
      ),
      child: TextField(
        autofocus: true,
        controller: cellCtl,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: context.colorScheme.primary,
              width: 2, // Thicker focus indicator
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: scaleSize(4),
            vertical: scaleSize(8),
          ), // Better padding for text scaling
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
        style: scaledTextStyle(fontSize: 16, color: context.colorScheme.onSecondaryContainer, height: 0.8),
      ),
    );
  }

  Future<bool?> badMnemonicPopup(BuildContext context) async {
    return await showConfirmationDialog(
      context: context,
      title: 'incorrectPhrase'.tr(),
      message: 'incorrectPhraseDescription'.tr(),
      type: ConfirmationDialogType.error,
      hideCancelButton: true,
      barrierDismissible: true,
    );
  }
}
