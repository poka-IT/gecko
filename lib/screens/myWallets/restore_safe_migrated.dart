// ignore_for_file: use_build_context_synchronously

import 'package:durt2/durt2.dart' show BidouilleLang, Durt;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/routes.dart';

import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';

class RestoreSafeMigrated extends ConsumerWidget {
  const RestoreSafeMigrated({super.key, this.skipIntro = false});
  final bool skipIntro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final controllers = ref.watch(mnemonicControllersProvider);

    return PopScope(
      onPopInvokedWithResult: (_, _) {
        // Clear input on back navigation
        ref.read(clearMnemonicInputProvider)();
      },
      child: Scaffold(
        backgroundColor: context.colorScheme.surface,
        appBar: GeckoAppBar('restoreASafe'.tr()),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                ScaledSizedBox(height: isTall ? 20 : 3),
                // Bubble speak widget - implement or import as needed
                Text('toRestoreEnterMnemonic'.tr(), style: scaledTextStyle(fontSize: 16)),
                ScaledSizedBox(height: isTall ? 20 : 5),
                // Responsive mnemonic input grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    final textScaler = MediaQuery.textScalerOf(context);
                    final isTextScaled = textScaler.scale(1.0) > 1.3;

                    // Calculate optimal layout
                    final horizontalPadding = scaleSize(32);
                    final availableWidth = constraints.maxWidth - horizontalPadding;
                    final spacing = scaleSize(8);

                    int cellsPerRow;
                    if (isTextScaled) {
                      cellsPerRow = 3;
                    } else if (availableWidth < scaleSize(300)) {
                      cellsPerRow = 2;
                    } else {
                      cellsPerRow = 4;
                    }

                    final cellWidth = (availableWidth - (spacing * (cellsPerRow - 1))) / cellsPerRow;
                    final cellHeight = scaleSize(isTextScaled ? 60 : 52);

                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: horizontalPadding / 2),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: scaleSize(isTall ? 10 : 6),
                        alignment: WrapAlignment.center,
                        children: controllers
                            .asMap()
                            .entries
                            .map(
                              (entry) => _buildMnemonicCell(
                                context,
                                ref,
                                entry.value,
                                entry.key,
                                cellWidth: cellWidth,
                                cellHeight: cellHeight,
                              ),
                            )
                            .toList(),
                      ),
                    );
                  },
                ),

                // Validation state and continue button
                if (mnemonicInput.isComplete && mnemonicInput.isValid)
                  Container(
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
                                minimumSize: Size(scaleSize(280), scaleSize(56)),
                              ).copyWith(
                                elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                  if (states.contains(WidgetState.pressed)) return 0;
                                  return 8;
                                }),
                                shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                              ),
                          onPressed: () async {
                            final validatedMnemonic = await ref
                                .read(mnemonicInputProvider.notifier)
                                .getValidatedMnemonic();

                            if (validatedMnemonic != null) {
                              // Set the mnemonic in the state for the next screen
                              await ref
                                  .read(mnemonicStateProvider.notifier)
                                  .setMnemonic(validatedMnemonic.displayMnemonic);

                              // Clear input and navigate
                              ref.read(clearMnemonicInputProvider)();

                              await AppNavigator.pushWithFader(
                                context,
                                skipIntro ? RouteNames.onboardingStepNine : RouteNames.onboardingStepSeven,
                                arguments: OnboardingStepsSevenToNineArguments(scanDerivation: true, fromRestore: true),
                                isFast: true,
                              );
                            }
                          },
                          child: Text(
                            'restoreAWallet'.tr(),
                            style: scaledTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Paste from clipboard option
                ScaledSizedBox(height: 20),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                  child: Align(
                    alignment: Alignment.center,
                    child: SizedBox(
                      height: scaleSize(50),
                      child: ElevatedButton(
                        key: keyPastMnemonic,
                        style:
                            ElevatedButton.styleFrom(
                              foregroundColor: Colors.black,
                              backgroundColor: context.colorScheme.secondary,
                              elevation: 0,
                              padding: EdgeInsets.symmetric(vertical: scaleSize(12), horizontal: scaleSize(16)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: Size(scaleSize(120), scaleSize(48)),
                            ).copyWith(
                              elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                if (states.contains(WidgetState.pressed)) return 0;
                                return 4;
                              }),
                              shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.15)),
                            ),
                        onPressed: () async {
                          final success = await ref.read(pasteMnemonicProvider)();
                          if (!success) {
                            // Show error if paste failed
                            await badMnemonicPopup(context);
                          }
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.content_paste_go,
                              size: scaleSize(18),
                              color: Colors.black.withValues(alpha: 0.7),
                            ),
                            SizedBox(width: scaleSize(6)),
                            Flexible(
                              child: Text(
                                'pasteFromClipboard'.tr(),
                                textAlign: TextAlign.center,
                                style: scaledTextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.3),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ScaledSizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMnemonicCell(
    BuildContext context,
    WidgetRef ref,
    TextEditingController controller,
    int index, {
    required double cellWidth,
    required double cellHeight,
  }) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final isWordValid = mnemonicInput.wordValidations[index] ?? true;

    return Container(
      width: cellWidth,
      height: cellHeight,
      constraints: BoxConstraints(minWidth: cellWidth, minHeight: cellHeight),
      decoration: BoxDecoration(
        border: Border.all(color: isWordValid ? Colors.grey[400]! : Colors.red[400]!, width: 1.5),
        color: context.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: controller,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          border: InputBorder.none,
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: context.colorScheme.primary, width: 2)),
          contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(4), vertical: scaleSize(8)),
        ),
        onChanged: (value) async {
          // Strip spaces and convert to lowercase
          if (value.contains(' ')) {
            controller.text = controller.text.replaceAll(' ', '');
          }
          if (value.isNotEmpty) controller.text = controller.text.toLowerCase();

          final cleanText = controller.text;

          // Auto-advance on valid word (except last field)
          if (cleanText.isNotEmpty && index < 11) {
            try {
              final languageCode = context.locale.languageCode;
              final preferredLanguage = BidouilleLang.fromLanguageCode(languageCode);

              // Use checkRedundance to only auto-advance when the word uniquely
              // identifies a single BIP39 word (no other words share this prefix)
              final isUniqueValidWord = await Durt.i.wallets.multilangService.isValidWordInAnyLanguage(
                cleanText,
                checkRedundance: true,
                preferredLanguage: preferredLanguage,
              );

              if (isUniqueValidWord) {
                FocusScope.of(context).nextFocus();
              }
            } catch (e) {
              // If validation fails, don't auto-advance
            }
          }
        },
        textAlign: TextAlign.center,
        style: scaledTextStyle(
          fontSize: 16,
          color: isWordValid ? context.colorScheme.onSecondaryContainer : Colors.red[600],
          height: 0.8,
        ),
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
