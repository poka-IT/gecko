import 'package:bubble/bubble.dart';
import 'dart:io' show Platform;
import 'package:durt2/durt2.dart' show Durt, BidouilleLang;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gecko/extensions.dart';
import 'package:gecko/globals.dart';
import 'package:flutter/material.dart';
import 'package:gecko/models/scale_functions.dart';
import 'package:gecko/models/widgets_keys.dart';
import 'package:gecko/providers/wallet_generation_providers.dart';
import 'package:gecko/routes.dart';
import 'package:gecko/widgets/commons/async_elevated_button.dart';
import 'package:gecko/widgets/commons/confirmation_dialog.dart';
import 'package:gecko/widgets/commons/responsive_center.dart';
import 'package:gecko/widgets/commons/top_appbar.dart';
import 'package:gecko/widgets/mnemonic_scanner.dart';

class RestoreSafe extends ConsumerStatefulWidget {
  const RestoreSafe({super.key, this.skipIntro = false});
  final bool skipIntro;

  @override
  ConsumerState<RestoreSafe> createState() => _RestoreSafeState();
}

class _RestoreSafeState extends ConsumerState<RestoreSafe> {
  static final bool _isDesktop = !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);
  bool _isRestoring = false;
  final List<FocusNode> _focusNodes = List.generate(12, (_) => FocusNode());

  // Track the latest validation call per field to cancel stale results
  int _validationGeneration = 0;

  @override
  void dispose() {
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            child: ResponsiveCenter(
              maxWidth: 500,
              padding: EdgeInsets.zero,
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
                          children: controllers
                              .asMap()
                              .entries
                              .map(
                                (entry) => arrayCell(
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
                          child: AsyncElevatedButton(
                            key: keyGoNext,
                            style:
                                ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: context.colorScheme.primary,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(vertical: scaleSize(16), horizontal: scaleSize(24)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  minimumSize: Size(scaleSize(280), scaleSize(56)), // Minimum size for accessibility
                                ).copyWith(
                                  elevation: WidgetStateProperty.resolveWith<double>((Set<WidgetState> states) {
                                    if (states.contains(WidgetState.pressed)) return 0;
                                    return 8;
                                  }),
                                  shadowColor: WidgetStateProperty.all(Colors.black.withValues(alpha: 0.2)),
                                ),
                            onPressed: () async {
                              // Set restoring state immediately to prevent UI flash
                              setState(() {
                                _isRestoring = true;
                              });

                              final validatedMnemonic = await ref
                                  .read(mnemonicInputProvider.notifier)
                                  .getValidatedMnemonic();

                              if (validatedMnemonic != null) {
                                try {
                                  // Set the mnemonic in the state for the next screen
                                  await ref
                                      .read(mnemonicStateProvider.notifier)
                                      .setMnemonic(validatedMnemonic.displayMnemonic);

                                  // Clear input and clean up global keys
                                  ref.read(clearMnemonicInputProvider)();

                                  if (!mounted) return;
                                  await AppNavigator.pushWithFader(
                                    context,
                                    widget.skipIntro ? RouteNames.onboardingStepNine : RouteNames.onboardingStepSeven,
                                    arguments: OnboardingStepsSevenToNineArguments(
                                      scanDerivation: true,
                                      fromRestore: true,
                                    ),
                                    isFast: true,
                                  );
                                } catch (e) {
                                  setState(() {
                                    _isRestoring = false;
                                  });
                                  // ignore: use_build_context_synchronously
                                  await badMnemonicPopup(context);
                                }
                              } else {
                                setState(() {
                                  _isRestoring = false;
                                });
                                // ignore: use_build_context_synchronously
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
                    ),

                  // Paste from clipboard and scan options (only show if mnemonic not complete/valid and not restoring)
                  if (!(mnemonicInput.isComplete && mnemonicInput.isValid) && !_isRestoring) ...[
                    ScaledSizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: scaleSize(16)),
                      child: Row(
                        children: [
                          // Paste button
                          Expanded(
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
                                  // ignore: use_build_context_synchronously
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
                          SizedBox(width: scaleSize(12)),
                          // Scan button
                          Expanded(
                            child: ElevatedButton(
                              style:
                                  ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: context.colorScheme.primary,
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
                                // Navigate to the OCR scanner
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => MnemonicScanner(
                                      onMnemonicDetected: (List<String> words) async {
                                        // Update controllers first so the UI shows the scanned words
                                        final ctrls = ref.read(mnemonicControllersProvider);
                                        for (int i = 0; i < words.length && i < 12; i++) {
                                          ctrls[i].text = words[i];
                                        }
                                        // Then update the provider state for validation
                                        await ref.read(mnemonicInputProvider.notifier).fillWords(words);
                                      },
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt, size: scaleSize(18), color: Colors.white),
                                  SizedBox(width: scaleSize(6)),
                                  Flexible(
                                    child: Text(
                                      'scanMnemonic'.tr(),
                                      textAlign: TextAlign.center,
                                      style: scaledTextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        height: 1.3,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
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
      color: context.colorScheme.surfaceContainer,
      child: Text(
        text,
        key: keyBubbleSpeak,
        textAlign: TextAlign.justify,
        style: scaledTextStyle(
          color: context.colorScheme.onSecondaryContainer,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }

  Widget arrayCell(
    BuildContext context,
    WidgetRef ref,
    TextEditingController cellCtl,
    int index, {
    required double cellWidth,
    required double cellHeight,
  }) {
    final mnemonicInput = ref.watch(mnemonicInputProvider);
    final isWordValid = mnemonicInput.wordValidations[index] ?? true;
    final suggestion = mnemonicInput.wordSuggestions[index];

    return SizedBox(
      width: cellWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: cellHeight,
            constraints: BoxConstraints(minWidth: cellWidth, minHeight: cellHeight),
            decoration: BoxDecoration(
              border: Border.all(color: isWordValid ? Colors.grey[400]! : context.geckoColors.danger, width: 1.5),
              color: context.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              autofocus: index == 0,
              focusNode: _focusNodes[index],
              controller: cellCtl,
              enabled: !(mnemonicInput.isComplete && mnemonicInput.isValid) && !_isRestoring,
              // On desktop, disable system auto-advance (Tab key) to avoid
              // racing with our async BIP39 validation
              textInputAction: _isDesktop ? TextInputAction.none : TextInputAction.next,
              decoration: InputDecoration(
                border: InputBorder.none,
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: context.colorScheme.primary, width: 2),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: scaleSize(4), vertical: scaleSize(8)),
              ),
              onChanged: (v) async {
                // Strip spaces and convert to lowercase, preserving cursor position
                final cleaned = v.replaceAll(' ', '').toLowerCase();
                if (cleaned != v) {
                  final cursorPos = cellCtl.selection.baseOffset - (v.length - cleaned.length);
                  cellCtl.value = TextEditingValue(
                    text: cleaned,
                    selection: TextSelection.collapsed(offset: cursorPos.clamp(0, cleaned.length)),
                  );
                }

                final cleanText = cleaned;

                // Only move to next field if we have a valid BIP39 word AND we're not at the last field
                if (cleanText.isNotEmpty && index < 11) {
                  // Track this validation call to discard stale results
                  final thisGeneration = ++_validationGeneration;
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
                    // Only advance if this is still the latest validation AND this field still has focus
                    if (isUniqueValidWord && thisGeneration == _validationGeneration && _focusNodes[index].hasFocus) {
                      _focusNodes[index + 1].requestFocus();
                    }
                  } catch (e) {
                    // If validation fails, don't move to next field
                  }
                }

                // Hide keyboard if mnemonic is now complete and valid
                if (mnemonicInput.isComplete && mnemonicInput.isValid) {
                  // ignore: use_build_context_synchronously
                  FocusScope.of(context).unfocus();
                }
              },
              textAlign: TextAlign.center,
              style: scaledTextStyle(
                fontSize: 16,
                color: isWordValid ? context.colorScheme.onSecondaryContainer : context.geckoColors.danger,
                height: 0.8,
              ),
            ),
          ),
          if (suggestion != null)
            GestureDetector(
              onTap: () {
                cellCtl.text = suggestion;
                if (index < 11) _focusNodes[index + 1].requestFocus();
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  suggestion,
                  style: scaledTextStyle(fontSize: 11, color: context.colorScheme.primary, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
        ],
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
